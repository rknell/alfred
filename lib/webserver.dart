import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:http_server/http_server.dart';
import 'package:mime_type/mime_type.dart';
import 'package:webserver/src/route_matcher.dart';

enum RouteMethod { get, post, put, delete, all }
enum RequestMethod { get, post, put, delete }

class Webserver {
  final routes = <HttpRoute>[];
  HttpServer? server;

  FutureOr Function(HttpRequest req, HttpResponse res)? on404;
  FutureOr Function(HttpRequest req, HttpResponse res)? on500;

  Webserver({this.on404, this.on500});

  HttpRoute get(String path,
      FutureOr Function(HttpRequest req, HttpResponse res) callback,
      {List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
          const []}) {
    final route = HttpRoute(path, callback, RouteMethod.get);
    routes.add(route);
    return route;
  }

  HttpRoute post(String path,
      FutureOr Function(HttpRequest req, HttpResponse res) callback,
      {List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
          const []}) {
    final route = HttpRoute(path, callback, RouteMethod.post);
    routes.add(route);
    return route;
  }

  HttpRoute put(String path,
      FutureOr Function(HttpRequest req, HttpResponse res) callback,
      {List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
          const []}) {
    final route = HttpRoute(path, callback, RouteMethod.put);
    routes.add(route);
    return route;
  }

  HttpRoute delete(String path,
      FutureOr Function(HttpRequest req, HttpResponse res) callback,
      {List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
          const []}) {
    final route = HttpRoute(path, callback, RouteMethod.delete);
    routes.add(route);
    return route;
  }

  HttpRoute all(String path,
      FutureOr Function(HttpRequest req, HttpResponse res) callback,
      {List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
          const []}) {
    final route = HttpRoute(path, callback, RouteMethod.all);
    routes.add(route);
    return route;
  }

  Future<HttpServer> listen(
      [int port = 3000, dynamic bindIp = "0.0.0.0"]) async {
    final _server = await HttpServer.bind(bindIp, port);

    _server.listen((HttpRequest request) {
      unawaited(incomingRequest(request));
    });

    return server = _server;
  }

  Future incomingRequest(HttpRequest request) async {
    bool isDone = false;
    print("${request.method} - ${request.uri.toString()}");
    unawaited(request.response.done.then((value) {
      isDone = true;
    }));

    final effectiveRoutes = RouteMatcher.match(
        request.uri.toString(),
        routes,
        EnumToString.fromString<RouteMethod>(
                RouteMethod.values, request.method) ??
            RouteMethod.get);

    if (effectiveRoutes.isEmpty) {
      if (on404 != null) {
        final result = await on404!(request, request.response);
        if (result != null && !isDone) {
          await _handleRoute(result, request);
        }
        await request.response.close();
      } else {
        request.response.statusCode = 404;
        request.response.write("404 not found");
        await request.response.close();
      }
    } else {
      try {
        for (var route in effectiveRoutes) {
          /// Loop through any middleware
          for (var middleware in route.middleware) {
            if (isDone) {
              break;
            }
            await _handleRoute(
                await middleware(request, request.response), request);
          }
          if (isDone) {
            break;
          }
          await _handleRoute(
              await route.callback(request, request.response), request);
        }
        if (!isDone) {
          if (request.response.contentLength == 0) {
            print("Warning: Returning a response with no content");
          }
          await request.response.close();
        }
      } on WebserverException catch (e) {
        request.response.statusCode = e.statusCode;
        await _handleRoute(e.response, request);
      } catch (e, s) {
        print(e);
        print(s);
        if (on500 != null) {
          final result = await on500!(request, request.response);
          if (result != null && !isDone) {
            await _handleRoute(result, request);
          }
          await request.response.close();
        } else {
          request.response.statusCode = 500;
          request.response.write(e);
          await request.response.close();
        }
      }
    }
  }

  Future<void> _handleRoute(dynamic result, HttpRequest request) async {
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

  Future close({bool force = true}) async {
    if (server != null) {
      await server!.close(force: force);
    }
  }
}

extension RequestHelpers on HttpRequest {
  Future<Object?> get body => HttpBodyHandler.processRequest(this);

  ContentType? get contentType => headers.contentType;
}

extension ResponseHelpers on HttpResponse {
  void setDownload({required String filename}) {
    headers.add("Content-Disposition", "attachment; filename=$filename");
  }

  void setContentTypeFromExtension(String extension) {
    final mime = mimeFromExtension(extension);
    if (mime != null) {
      final split = mime.split("/");
      headers.contentType = ContentType(split[0], split[1]);
    }
  }

  void setContentTypeFromFile(File file) {
    if (headers.contentType == null ||
        headers.contentType!.mimeType == "text/plain") {
      headers.contentType = file.contentType;
    } else {
      headers.contentType == ContentType.binary;
    }
  }

  Future json(Object? json) async {
    headers.contentType = ContentType.json;
    write(jsonEncode(json));
    await close();
  }

  //Just for expressjs users
  void send(Object? data) => write(data);
}

extension FileHelpers on File {
  String? get mimeType => mime(path);

  ContentType? get contentType {
    final mimeType = this.mimeType;
    if (mimeType != null) {
      final split = mimeType.split("/");
      return ContentType(split[0], split[1]);
    }
  }
}

void unawaited(Future future) {}

class WebserverException implements Exception {
  final Object? response;
  final int statusCode;

  WebserverException(this.statusCode, this.response);
}
