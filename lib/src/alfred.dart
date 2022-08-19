import 'dart:async';
import 'dart:io';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:queue/queue.dart';

import 'alfred_exception.dart';
import 'extensions/request_helpers.dart';
import 'http_route.dart';
import 'plugins/store_plugin.dart';
import 'route_matcher.dart';
import 'route_param_types/alpha_param_type.dart';
import 'route_param_types/date_param_type.dart';
import 'route_param_types/double_param_type.dart';
import 'route_param_types/hex_param_type.dart';
import 'route_param_types/int_param_type.dart';
import 'route_param_types/timestamp_param_type.dart';
import 'route_param_types/uint_param_type.dart';
import 'route_param_types/uuid_param_type.dart';
import 'type_handlers/binary_type_handlers.dart';
import 'type_handlers/directory_type_handler.dart';
import 'type_handlers/file_type_handler.dart';
import 'type_handlers/json_type_handlers.dart';
import 'type_handlers/serializable_type_handler.dart';
import 'type_handlers/string_type_handler.dart';
import 'type_handlers/type_handler.dart';
import 'type_handlers/websocket_type_handler.dart';

enum Method {
  get,
  post,
  put,
  delete,
  patch,
  options,
  head,
  copy,
  link,
  unlink,
  purge,
  lock,
  unlock,
  propfind,
  view,
  all
}

/// Indicates the severity of logged message
enum LogType { debug, info, warn, error }

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

  /// Writer to handle internal logging.
  ///
  /// It can optionally exchanged with your own logging solution.
  /// ```
  late void Function(dynamic Function() messageFn, LogType type) logWriter;

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
  Queue requestQueue;

  /// An array of [TypeHandler] that Alfred walks through in order to determine
  /// if it can handle a value returned from a route.
  ///
  var typeHandlers = <TypeHandler>[];

  final _onDoneListeners = <void Function(HttpRequest req, HttpResponse res)>[];

  /// Register a listener when a request is complete
  ///
  /// Typically would be used for logging, benchmarking or cleaning up data
  /// used when writing a plugin.
  ///
  Function registerOnDoneListener(
      void Function(HttpRequest, HttpResponse) listener) {
    _onDoneListeners.add(listener);
    return listener;
  }

  /// Dispose of any on done listeners when you are done with them.
  ///
  void removeOnDoneListener(Function listener) {
    _onDoneListeners.remove(listener);
  }

  /// Creates a new Alfred application.
  ///
  /// The default [logWriter] can be tuned by changing the [logLevel]:
  /// - [LogType.error]: prints errors
  /// - [LogType.warn]: prints errors and warning
  /// - [LogType.info]: prints errors, warning and requests
  /// - [LogType.debug]: prints errors, warning, requests and further details
  ///
  /// *Note: Changing the [logLevel] only effects the default [logWriter].*
  ///
  /// [simultaneousProcessing] is the number of requests doing work at any one
  /// time. If the amount of unprocessed incoming requests exceed this number,
  /// the requests will be queued.
  Alfred({
    this.onNotFound,
    this.onInternalError,
    LogType logLevel = LogType.info,
    int simultaneousProcessing = 50,
  }) : requestQueue = Queue(parallel: simultaneousProcessing) {
    _registerDefaultParamTypes();
    _registerDefaultTypeHandlers();
    _registerPluginListeners();
    _registerDefaultLogWriter(logLevel);
  }

  void _registerDefaultLogWriter(LogType logLevel) {
    logWriter = (dynamic Function() messageFn, type) {
      if (type.index >= logLevel.index) {
        var timestamp = DateTime.now();
        var logType = EnumToString.convertToString(type);
        var message = messageFn().toString();
        print('$timestamp - $logType - $message');
      }
    };
  }

  void _registerDefaultTypeHandlers() {
    typeHandlers.addAll([
      stringTypeHandler,
      uint8listTypeHandler,
      listIntTypeHandler,
      binaryStreamTypeHandler,
      jsonListTypeHandler,
      jsonMapTypeHandler,
      jsonNumberTypeHandler,
      jsonBooleanTypeHandler,
      fileTypeHandler,
      directoryTypeHandler,
      websocketTypeHandler,
      serializableTypeHandler
    ]);
  }

  void _registerDefaultParamTypes() {
    HttpRouteParam.paramTypes.addAll([
      IntParamType(),
      UintParamType(),
      DoubleParamType(),
      DateParamType(),
      TimestampParamType(),
      HexParamType(),
      AlphaParamType(),
      UuidParamType()
    ]);
  }

  void _registerPluginListeners() {
    registerOnDoneListener(storePluginOnDoneHandler);
  }

  /// Create a get route
  ///
  HttpRoute get(String path,
          FutureOr Function(HttpRequest req, HttpResponse res) callback,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      _createRoute(path, callback, Method.get, middleware);

  /// Create a head route
  ///
  HttpRoute head(String path,
          FutureOr Function(HttpRequest req, HttpResponse res) callback,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      _createRoute(path, callback, Method.head, middleware);

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

  HttpRoute _createRoute(
      String path,
      FutureOr Function(HttpRequest req, HttpResponse res) callback,
      Method method,
      [List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
          const []]) {
    final route = HttpRoute(path, callback, method, middleware: middleware);
    routes.add(route);
    return route;
  }

  /// Call this function to fire off the server.
  ///
  ///
  ///
  Future<HttpServer> listen([
    int port = 3000,
    dynamic bindIp = '0.0.0.0',
    bool shared = true,
    int backlog = 0,
  ]) async {
    final _server = await HttpServer.bind(
      bindIp,
      port,
      backlog: backlog,
      shared: shared,
    );

    _server.idleTimeout = Duration(seconds: 1);

    _server.listen((HttpRequest request) {
      requestQueue.add(() => _incomingRequest(request));
    });

    logWriter(
        () => 'HTTP Server listening on port ${_server.port}', LogType.info);
    return server = _server;
  }

  Future<HttpServer> listenSecure({
    required SecurityContext securityContext,
    int port = 3000,
    dynamic bindIp = '0.0.0.0',
    bool shared = true,
    int backlog = 0,
  }) async {
    final _server = await HttpServer.bindSecure(
      bindIp,
      port,
      securityContext,
      backlog: backlog,
      shared: shared,
    );

    _server.idleTimeout = Duration(seconds: 1);

    _server.listen((HttpRequest request) {
      requestQueue.add(() => _incomingRequest(request));
    });

    logWriter(
        () => 'HTTP Server listening on port ${_server.port}', LogType.info);
    return server = _server;
  }

  /// Handles and routes an incoming request
  ///
  Future<void> _incomingRequest(HttpRequest request) async {
    /// Expose this Alfred instance for middleware or other utility functions
    request.store.set('_internal_alfred', this);

    /// Variable to track the close of the response
    var isDone = false;

    logWriter(
        () => '${request.method} - ${request.uri.toString()}', LogType.info);

    // We track if the response has been resolved in order to exit out early
    // the list of routes (ie the middleware returned)
    _unawaited(request.response.done.then((dynamic _) {
      isDone = true;
      for (var listener in _onDoneListeners) {
        listener(request, request.response);
      }
      logWriter(() => 'Response sent to client', LogType.debug);
    }));

    // Work out all the routes we need to process
    final effectiveMatches = RouteMatcher.match(
        request.uri.toString(),
        routes,
        EnumToString.fromString<Method>(Method.values, request.method) ??
            Method.get);

    try {
      // If there are no effective routes, that means we need to throw a 404
      // or see if there are any static routes to fall back to, otherwise
      // continue and process the routes
      if (effectiveMatches.isEmpty) {
        logWriter(() => 'No matching route found.', LogType.debug);
        await _respondNotFound(request, isDone);
      } else {
        /// Tracks if one route is using a wildcard
        var nonWildcardRouteMatch = false;

        // Loop through the routes in the order they are in the routes list
        for (var match in effectiveMatches) {
          if (isDone) {
            break;
          }
          logWriter(() => 'Match route: ${match.route.route}', LogType.debug);
          request.store.set('_internal_match', match);
          nonWildcardRouteMatch =
              !match.route.usesWildcardMatcher || nonWildcardRouteMatch;

          /// Loop through any middleware
          for (var middleware in match.route.middleware) {
            // If the request has already completed, exit early.
            if (isDone) {
              break;
            }
            logWriter(
                () => 'Apply middleware associated with route', LogType.debug);
            await _handleResponse(
                await middleware(request, request.response), request);
          }

          /// If the request has already completed, exit early, otherwise process
          /// the primary route callback
          if (isDone) {
            break;
          }
          logWriter(() => 'Execute route callback function', LogType.debug);
          await _handleResponse(
              await match.route.callback(request, request.response), request);
        }

        /// If you got here and isDone is still false, you forgot to close
        /// the response, or you didn't return anything. Either way its an error,
        /// but instead of letting the whole server hang as most frameworks do,
        /// lets at least close the connection out
        ///
        if (!isDone) {
          if (request.response.contentLength == -1) {
            if (nonWildcardRouteMatch == false) {
              await _respondNotFound(request, isDone);
            }
          }
          await request.response.close();
        }
      }
    } on AlfredException catch (e) {
      // The user threw a handle HTTP Exception
      try {
        request.response.statusCode = e.statusCode;
        await _handleResponse(e.response, request);
      } on StateError catch (e, s) {
        // It can hit this block if you try to write a header when one is already been raised
        logWriter(() => e, LogType.error);
        logWriter(() => s, LogType.error);
      } catch (e, s) {
        // Catch all other errors, this block may be able to be removed in the future
        logWriter(() => e, LogType.error);
        logWriter(() => s, LogType.error);
      }
    } on NotFoundError catch (_) {
      await _respondNotFound(request, isDone);
    } catch (e, s) {
      // Its all broken, bail (but don't crash)
      logWriter(() => e, LogType.error);
      logWriter(() => s, LogType.error);
      if (onInternalError != null) {
        // Handle the error with a custom response
        request.store.set('_internal_exception', e);
        final dynamic result =
            await onInternalError!(request, request.response);
        if (result != null && !isDone) {
          await _handleResponse(result, request);
        }
        await request.response.close();
      } else {
        //Otherwise fall back to a generic 500 error
        try {
          request.response.statusCode = 500;
          request.response.write(e);
          await request.response.close();
        } catch (e, s) {
          logWriter(() => e, LogType.error);
          logWriter(() => s, LogType.error);
        }
      }
    }
  }

  /// Responds request with a NotFound response
  ///
  Future _respondNotFound(HttpRequest request, bool isDone) async {
    if (onNotFound != null) {
      // Otherwise check if a custom 404 handler has been provided
      final dynamic result = await onNotFound!(request, request.response);
      if (result != null && !isDone) {
        await _handleResponse(result, request);
      }
      await request.response.close();
    } else {
      // Otherwise throw a generic 404;
      request.response.statusCode = 404;
      request.response.write('404 not found');
      await request.response.close();
    }
  }

  /// Handle a response by response type
  ///
  /// This is the logic that will handle the response based on what you return.
  ///
  Future<void> _handleResponse(dynamic result, HttpRequest request) async {
    if (result != null) {
      var handled = false;
      for (var handler in typeHandlers) {
        if (handler.shouldHandle(result)) {
          logWriter(
              () => 'Apply TypeHandler for result type: ${result.runtimeType}',
              LogType.debug);
          dynamic handlerResult =
              await handler.handler(request, request.response, result);
          if (handlerResult != false) {
            handled = true;
            break;
          }
        }
      }
      if (!handled) {
        throw NoTypeHandlerError(result, request);
      }
    }
  }

  /// Close the server and clean up any resources
  ///
  /// Call this if you are shutting down the server but continuing to run
  /// the app.
  Future close({bool force = true}) async {
    if (server != null) {
      await server!.close(force: force);
    }
  }

  /// Print out the registered routes to the console
  ///
  /// Helpful to see whats available
  void printRoutes() {
    for (var route in routes) {
      late String methodString;
      switch (route.method) {
        case Method.get:
          methodString = '\x1B[33mGET\x1B[0m';
          break;
        case Method.post:
          methodString = '\x1B[31mPOST\x1B[0m';
          break;
        case Method.put:
          methodString = '\x1B[32mPUT\x1B[0m';
          break;
        case Method.delete:
          methodString = '\x1B[34mDELETE\x1B[0m';
          break;
        case Method.patch:
          methodString = '\x1B[35mPATCH\x1B[0m';
          break;
        case Method.options:
          methodString = '\x1B[36mOPTIONS\x1B[0m';
          break;
        case Method.all:
          methodString = '\x1B[37mALL\x1B[0m';
          break;
        case Method.head:
          methodString = '\x1B[38mHEAD\x1B[0m';
          break;
        case Method.copy:
          methodString = '\x1B[39mCOPY\x1B[0m';
          break;
        case Method.link:
          methodString = '\x1B[40mLINK\x1B[0m';
          break;
        case Method.unlink:
          methodString = '\x1B[41mUNLINK\x1B[0m';
          break;
        case Method.purge:
          methodString = '\x1B[42mPURGE\x1B[0m';
          break;
        case Method.lock:
          methodString = '\x1B[43mUNLOCK\x1B[0m';
          break;
        case Method.unlock:
          methodString = '\x1B[44mUNLOCK\x1B[0m';
          break;
        case Method.propfind:
          methodString = '\x1B[45mPROPFIND\x1B[0m';
          break;
        case Method.view:
          methodString = '\x1B[46mVIEW\x1B[0m';
          break;
      }
      print('${route.route} - $methodString');
    }
  }
}

/// Function to prevent linting errors.
///
void _unawaited(Future<Null> then) {}

/// Error thrown when a type handler cannot be found for a returned item
///
class NoTypeHandlerError extends Error {
  final dynamic object;
  final HttpRequest request;

  NoTypeHandlerError(this.object, this.request);

  @override
  String toString() =>
      'No type handler found for ${object.runtimeType} / ${object.toString()} \nRoute: ${request.route}\nIf the app is running in production mode, the type name may be minified. Run it in debug mode to resolve';
}

/// Error used by middleware, utils or type handler to elevate
/// a NotFound response.
class NotFoundError extends Error {}
