import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:alfred/src/route_matcher.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:http_server/http_server.dart';
import 'package:mime_type/mime_type.dart';

enum RouteMethod { get, post, put, delete, all }
enum RequestMethod { get, post, put, delete }

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

  final _staticFiles = <String, HttpRoute>{};

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

  Alfred({this.onNotFound, this.onInternalError, this.logRequests = true});

  /// Create a get route
  ///
  HttpRoute get(String path,
      FutureOr Function(HttpRequest req, HttpResponse res) callback,
      {List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
          const []}) {
    final route =
        HttpRoute(path, callback, RouteMethod.get, middleware: middleware);
    routes.add(route);
    return route;
  }

  /// Create a post route
  ///
  HttpRoute post(String path,
      FutureOr Function(HttpRequest req, HttpResponse res) callback,
      {List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
          const []}) {
    final route = HttpRoute(path, callback, RouteMethod.post);
    routes.add(route);
    return route;
  }

  /// Create a put route
  HttpRoute put(String path,
      FutureOr Function(HttpRequest req, HttpResponse res) callback,
      {List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
          const []}) {
    final route = HttpRoute(path, callback, RouteMethod.put);
    routes.add(route);
    return route;
  }

  /// Create a delete route
  ///
  HttpRoute delete(String path,
      FutureOr Function(HttpRequest req, HttpResponse res) callback,
      {List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
          const []}) {
    final route = HttpRoute(path, callback, RouteMethod.delete);
    routes.add(route);
    return route;
  }

  /// Create a route that listens on all methods
  ///
  HttpRoute all(String path,
      FutureOr Function(HttpRequest req, HttpResponse res) callback,
      {List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
          const []}) {
    final route = HttpRoute(path, callback, RouteMethod.all);
    routes.add(route);
    return route;
  }

  /// Serve some static files on a route
  ///
  void static(String path, Directory directory) {
    _staticFiles[path] = HttpRoute(path, (req, res) async {
      final filePath = directory.path + req.uri.path.replaceFirst(path, "");
      final file = File(filePath);
      final exists = await file.exists();
      if (!exists) {
        throw AlfredException(404, {"message": "file not found"});
      }
      res.setContentTypeFromFile(file);
      await res.addStream(file.openRead());
      await res.close();
    }, RouteMethod.get);
  }

  /// Call this function to fire off the server
  ///
  Future<HttpServer> listen(
      [int port = 3000, dynamic bindIp = "0.0.0.0"]) async {
    final _server = await HttpServer.bind(bindIp, port);

    _server.listen((HttpRequest request) {
      unawaited(_incomingRequest(request));
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

    unawaited(request.response.done.then((value) {
      isDone = true;
    }));

    final effectiveRoutes = RouteMatcher.match(
        request.uri.toString(),
        routes,
        EnumToString.fromString<RouteMethod>(
                RouteMethod.values, request.method) ??
            RouteMethod.get);

    final staticRoutes = _staticFiles.values
        .where((element) => request.uri.path.startsWith(element.route))
        .toList();

    try {
      if (effectiveRoutes.isEmpty) {
        if (staticRoutes.isNotEmpty) {
          await staticRoutes.first.callback(request, request.response);
        } else if (onNotFound != null) {
          final result = await onNotFound!(request, request.response);
          if (result != null && !isDone) {
            await _handleResponse(result, request);
          }
          await request.response.close();
        } else {
          request.response.statusCode = 404;
          request.response.write("404 not found");
          await request.response.close();
        }
      } else {
        for (var route in effectiveRoutes) {
          /// Loop through any middleware
          for (var middleware in route.middleware) {
            if (isDone) {
              break;
            }
            await _handleResponse(
                await middleware(request, request.response), request);
          }
          if (isDone) {
            break;
          }
          await _handleResponse(
              await route.callback(request, request.response), request);
        }
        if (!isDone) {
          if (request.response.contentLength == -1) {
            print(
                "Warning: Returning a response with no content. ${effectiveRoutes.map((e) => e.route).join(", ")}");
          }
          await request.response.close();
        }
      }
    } on AlfredException catch (e) {
      request.response.statusCode = e.statusCode;
      await _handleResponse(e.response, request);
    } catch (e, s) {
      print(e);
      print(s);
      if (onInternalError != null) {
        final result = await onInternalError!(request, request.response);
        if (result != null && !isDone) {
          await _handleResponse(result, request);
        }
        await request.response.close();
      } else {
        request.response.statusCode = 500;
        request.response.write(e);
        await request.response.close();
      }
    }
  }

  /// Handle an automated response
  ///
  Future<void> _handleResponse(dynamic result, HttpRequest request) async {
    if (result != null) {
      if (result is Uint8List || result is List<int>) {
        if (request.response.headers.contentType == null ||
            request.response.headers.contentType!.value == "text/plain") {
          request.response.headers.contentType = ContentType.binary;
        }
        request.response.add(result);
      } else if (result is Map<String, dynamic> || result is List<dynamic>) {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(result));
      } else if (result is String) {
        //Default content type is text, no need to set it
        request.response.write(result);
      } else if (result is File) {
        request.response.setContentTypeFromFile(result);
        await request.response.addStream(result.openRead());
      } else if (result is Stream<List<int>>) {
        if (request.response.headers.contentType == null ||
            request.response.headers.contentType!.value == "text/plain") {
          request.response.headers.contentType = ContentType.binary;
        }
        await request.response.addStream(result);
      }
      await request.response.close();
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

extension RequestHelpers on HttpRequest {
  /// Parse the body automatically and return the result
  ///
  Future<Object?> get body async =>
      (await HttpBodyHandler.processRequest(this)).body;

  /// Get the content type
  ///
  ContentType? get contentType => headers.contentType;
}

extension ResponseHelpers on HttpResponse {
  /// Set the appropriate headers to download the file
  ///
  void setDownload({required String filename}) {
    headers.add("Content-Disposition", "attachment; filename=$filename");
  }

  /// Set the content type from the extension ie. 'pdf'
  ///
  void setContentTypeFromExtension(String extension) {
    final mime = mimeFromExtension(extension);
    if (mime != null) {
      final split = mime.split("/");
      headers.contentType = ContentType(split[0], split[1]);
    }
  }

  /// Set the content type given a file
  ///
  void setContentTypeFromFile(File file) {
    if (headers.contentType == null ||
        headers.contentType!.mimeType == "text/plain") {
      headers.contentType = file.contentType;
    } else {
      headers.contentType == ContentType.binary;
    }
  }

  /// Helper method for those used to res.json()
  ///
  Future json(Object? json) async {
    headers.contentType = ContentType.json;
    write(jsonEncode(json));
    await close();
  }

  /// Helper method to just send data;
  Future send(Object? data) async {
    write(data);
    await close();
  }
}

extension FileHelpers on File {
  /// Get the mimeType as a string
  ///
  String? get mimeType => mime(path);

  /// Get the contentType header from the current
  ///
  ContentType? get contentType {
    final mimeType = this.mimeType;
    if (mimeType != null) {
      final split = mimeType.split("/");
      return ContentType(split[0], split[1]);
    }
  }
}

/// Used to prevent lint warnings about unawaited futures;
void unawaited(Future future) {}

/// Throw these exceptions to bubble up an error from sub functions and have them
/// handled automatically for the client
class AlfredException implements Exception {
  /// The response to send to the client
  ///
  final Object? response;

  /// The statusCode to send to the client
  ///
  final int statusCode;

  AlfredException(this.statusCode, this.response);
}
