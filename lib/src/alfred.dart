import 'dart:async';
import 'dart:io';

import 'package:alfred/src/type_handlers/binary_type_handlers.dart';
import 'package:alfred/src/type_handlers/directory_type_handler.dart';
import 'package:alfred/src/type_handlers/file_type_handler.dart';
import 'package:alfred/src/type_handlers/json_type_handlers.dart';
import 'package:alfred/src/type_handlers/string_type_handler.dart';
import 'package:alfred/src/type_handlers/type_handler.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:pedantic/pedantic.dart';
import 'package:queue/queue.dart';

import 'alfred_exception.dart';
import 'http_route.dart';
import 'route_matcher.dart';

enum Method { get, post, put, delete, patch, options, all }

/// Server application class
///
/// This is the core of the server application. Generally you would create one
/// for each app.
class Alfred {
  /// List of routes
  ///
  /// Generally you don't want to manipulate this array directly, instead add
  /// routes by calling the [get,post,put,delete] methods.
  final routes = <HttpRoute>[];

  /// HttpServer instance from the dart:io library
  ///
  /// If there is anything the app can't do, you can do it through here.
  HttpServer? server;

  /// Log requests immediately as they come in
  ///
  bool logRequests;

  /// Optional handler for when a route is not found
  ///
  FutureOr Function(HttpRequest req, HttpResponse res)? onNotFound;

  /// Optional handler for when the server throws an unhandled error
  ///
  FutureOr Function(HttpRequest req, HttpResponse res)? onInternalError;

  /// Incoming request queue
  ///
  /// Set the number of simultaneous connections being processed at any one time
  /// in the [simultaneousProcessing] param in the constructor
  late Queue requestQueue;

  List<TypeHandler> typeHandlers = [];

  /// Constructor
  ///
  /// [simultaneousProcessing] is the number of requests doing work at any one
  /// time. If the amount of unprocessed incoming requests exceed this number,
  /// the requests will be queued.
  Alfred({
    this.onNotFound,
    this.onInternalError,
    this.logRequests = true,
    int simultaneousProcessing = 50,
  }) {
    requestQueue = Queue(parallel: simultaneousProcessing);
    _registerDefaultTypeHandlers();
  }

  void _registerDefaultTypeHandlers() {
    typeHandlers.addAll([
      stringTypeHandler,
      uint8listTypeHandler,
      listIntTypeHandler,
      binaryStreamTypeHandler,
      jsonListTypeHandler,
      jsonMapTypeHandler,
      fileTypeHandler,
      directoryTypeHandler
    ]);
  }

  /// Create a get route
  ///
  HttpRoute get(String path,
      FutureOr Function(HttpRequest req, HttpResponse res) callback,
      {List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
          const []}) {
    final route = HttpRoute(path, callback, Method.get, middleware: middleware);
    routes.add(route);
    return route;
  }

  /// Create a post route
  ///
  HttpRoute post(String path,
          FutureOr Function(HttpRequest req, HttpResponse res) callback,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      _createRoute(path, callback, Method.post, middleware);

  /// Create a put route
  HttpRoute put(String path,
          FutureOr Function(HttpRequest req, HttpResponse res) callback,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      _createRoute(path, callback, Method.put, middleware);

  /// Create a delete route
  ///
  HttpRoute delete(String path,
          FutureOr Function(HttpRequest req, HttpResponse res) callback,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      _createRoute(path, callback, Method.delete, middleware);

  /// Create a patch route
  ///
  HttpRoute patch(String path,
          FutureOr Function(HttpRequest req, HttpResponse res) callback,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      _createRoute(path, callback, Method.patch, middleware);

  /// Create an options route
  ///
  HttpRoute options(String path,
          FutureOr Function(HttpRequest req, HttpResponse res) callback,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      _createRoute(path, callback, Method.options, middleware);

  /// Create a route that listens on all methods
  ///
  HttpRoute all(String path,
          FutureOr Function(HttpRequest req, HttpResponse res) callback,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      _createRoute(path, callback, Method.all, middleware);

  HttpRoute _createRoute(path, callback, Method method,
      [List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
          const []]) {
    final route = HttpRoute(path, callback, method, middleware: middleware);
    routes.add(route);
    return route;
  }

  /// Call this function to fire off the server
  ///
  Future<HttpServer> listen(
      [int port = 3000, dynamic bindIp = "0.0.0.0"]) async {
    final _server = await HttpServer.bind(bindIp, port);
    _server.idleTimeout = Duration(seconds: 1);

    _server.listen((HttpRequest request) {
      requestQueue.add(() => _incomingRequest(request));
    });

    return server = _server;
  }

  /// Handles and routes an incoming request
  ///
  Future _incomingRequest(HttpRequest request) async {
    bool isDone = false;

    if (logRequests) {
      print("${request.method} - ${request.uri.toString()}");
    }

    // We track if the response has been resolved in order to exit out early
    // the list of routes (ie the middleware returned)
    unawaited(request.response.done.then((value) {
      isDone = true;
    }));

    // Work out all the routes we need to process
    final effectiveRoutes = RouteMatcher.match(
        request.uri.toString(),
        routes,
        EnumToString.fromString<Method>(Method.values, request.method) ??
            Method.get);

    try {
      // If there are no effective routes, that means we need to throw a 404
      // or see if there are any static routes to fall back to, otherwise
      // continue and process the routes
      if (effectiveRoutes.isEmpty) {
        if (onNotFound != null) {
          // Otherwise check if a custom 404 handler has been provided
          final result = await onNotFound!(request, request.response);
          if (result != null && !isDone) {
            await _handleResponse(result, request);
          }
          await request.response.close();
        } else {
          // Otherwise throw a generic 404;
          request.response.statusCode = 404;
          request.response.write("404 not found");
          await request.response.close();
        }
      } else {
        // Loop through the routes in the order they are in the routes list
        for (var route in effectiveRoutes) {
          //TODO: This is a hack to match the params of the selected route
          request.response.headers.set("x-alfred-route", route.route);

          /// Loop through any middleware
          for (var middleware in route.middleware) {
            // If the request has already completed, exit early.
            if (isDone) {
              break;
            }
            await _handleResponse(
                await middleware(request, request.response), request);
          }

          /// If the request has already completed, exit early, otherwise process
          /// the primary route callback
          if (isDone) {
            break;
          }
          await _handleResponse(
              await route.callback(request, request.response), request);
        }

        /// If you got here and isDone is still false, you forgot to close
        /// the response, or your didn't return anything. Either way its an error,
        /// but instead of letting the whole server hang as most frameworks do,
        /// lets at least close the connection out
        ///
        if (!isDone) {
          if (request.response.contentLength == -1) {
            print(
                "Warning: Returning a response with no content. ${effectiveRoutes.map((e) => e.route).join(", ")}");
          }
          await request.response.close();
        }
      }
    } on AlfredException catch (e) {
      // The user threw a handle HTTP Exception
      request.response.statusCode = e.statusCode;
      await _handleResponse(e.response, request);
    } catch (e, s) {
      // Its all broken, bail (but don't crash)
      print(e);
      print(s);
      if (onInternalError != null) {
        // Handle the error with a custom response
        final result = await onInternalError!(request, request.response);
        if (result != null && !isDone) {
          await _handleResponse(result, request);
        }
        await request.response.close();
      } else {
        //Otherwise fall back to a generic 500 error
        request.response.statusCode = 500;
        request.response.write(e);
        await request.response.close();
      }
    }
  }

  /// Handle a response by response type
  ///
  /// This is the logic that will handle the response based on what you return.
  ///
  Future<void> _handleResponse(dynamic result, HttpRequest request) async {
    if (result != null) {
      for (var handler in typeHandlers) {
        if (handler.shouldHandle(result)) {
          print(result.runtimeType);
          await handler.handler(request, request.response, result);
          break;
        }
      }
    }
  }

  /// Close the server
  ///
  Future close({bool force = true}) async {
    if (server != null) {
      await server!.close(force: force);
    }
  }
}
