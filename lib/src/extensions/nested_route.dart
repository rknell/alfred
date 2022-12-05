import 'dart:async';

import '../../alfred.dart';

extension NestedRouteExtension on Alfred {
  /// Creates one or multiple route segments that can be used
  /// as a common base for specifying routes with [get], [post], etc.
  ///
  /// You can define middleware that effects all sub-routes.
  NestedRoute route(String path,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      NestedRoute(alfred: this, basePath: path, baseMiddleware: middleware);
}

class NestedRoute {
  final Alfred _alfred;
  final String _basePath;
  final List<FutureOr Function(HttpRequest req, HttpResponse res)>
      _baseMiddleware;

  NestedRoute(
      {required Alfred alfred,
      required String basePath,
      required List<FutureOr Function(HttpRequest req, HttpResponse res)>
          baseMiddleware})
      : _alfred = alfred,
        _basePath = basePath,
        _baseMiddleware = baseMiddleware;

  /// Create a get route
  ///
  HttpRoute get(String path,
          FutureOr Function(HttpRequest req, HttpResponse res) callback,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      _createRoute(path, callback, Method.get, middleware);

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

  /// Creates one or multiple route segments that can be used
  /// as a common base for specifying routes with [get], [post], etc.
  ///
  /// You can define middleware that effects all sub-routes.
  NestedRoute route(String path,
          {List<FutureOr Function(HttpRequest req, HttpResponse res)>
              middleware = const []}) =>
      NestedRoute(
          alfred: _alfred,
          basePath: _composePath(_basePath, path),
          baseMiddleware: [..._baseMiddleware, ...middleware]);

  HttpRoute _createRoute(
      String path,
      FutureOr Function(HttpRequest req, HttpResponse res) callback,
      Method method,
      [List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
          const []]) {
    final route = HttpRoute(_composePath(_basePath, path), callback, method,
        middleware: [..._baseMiddleware, ...middleware]);
    _alfred.routes.add(route);
    return route;
  }
}

String _composePath(String first, String second) {
  if (first.endsWith('/') && second.startsWith('/')) {
    return first + second.substring(1);
  } else if (!first.endsWith('/') && !second.startsWith('/')) {
    return '$first/$second';
  }
  return first + second;
}
