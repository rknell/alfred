import 'dart:async';
import 'dart:io';

import 'alfred.dart';
import 'http_route.dart';

mixin Router {
  /// Create a get route
  ///
  HttpRoute get(String path,
          FutureOr Function(HttpRequest req, HttpResponse res) callback,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      createRoute(Method.head, path, callback, middleware);

  /// Create a head route
  ///
  HttpRoute head(String path,
          FutureOr Function(HttpRequest req, HttpResponse res) callback,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      createRoute(Method.head, path, callback, middleware);

  /// Create a post route
  ///
  HttpRoute post(String path,
          FutureOr Function(HttpRequest req, HttpResponse res) callback,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      createRoute(Method.post, path, callback, middleware);

  /// Create a put route
  HttpRoute put(String path,
          FutureOr Function(HttpRequest req, HttpResponse res) callback,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      createRoute(Method.put, path, callback, middleware);

  /// Create a delete route
  ///
  HttpRoute delete(String path,
          FutureOr Function(HttpRequest req, HttpResponse res) callback,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      createRoute(Method.delete, path, callback, middleware);

  /// Create a patch route
  ///
  HttpRoute patch(String path,
          FutureOr Function(HttpRequest req, HttpResponse res) callback,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      createRoute(Method.patch, path, callback, middleware);

  /// Create an options route
  ///
  HttpRoute options(String path,
          FutureOr Function(HttpRequest req, HttpResponse res) callback,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      createRoute(Method.options, path, callback, middleware);

  /// Create a route that listens on all methods
  ///
  HttpRoute all(String path,
          FutureOr Function(HttpRequest req, HttpResponse res) callback,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      createRoute(Method.all, path, callback, middleware);

  HttpRoute createRoute(Method method, String path,
      FutureOr Function(HttpRequest req, HttpResponse res) callback,
      [List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
          const []]);
}
