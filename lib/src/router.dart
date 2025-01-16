import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';

import 'alfred.dart';
import 'http_route.dart';
import 'openapi/schema.dart';
import 'route_group.dart';

mixin Router {
  @protected
  Alfred get app;

  String get pathPrefix;

  /// Create a get route
  ///
  HttpRoute get(
    String path,
    FutureOr Function(HttpRequest req, HttpResponse res) callback, {
    List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
        const [],
    OpenAPIDoc? openAPIDoc,
  }) =>
      createRoute(Method.get, path, callback, middleware, openAPIDoc);

  /// Create a head route
  ///
  HttpRoute head(
    String path,
    FutureOr Function(HttpRequest req, HttpResponse res) callback, {
    List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
        const [],
    OpenAPIDoc? openAPIDoc,
  }) =>
      createRoute(Method.head, path, callback, middleware, openAPIDoc);

  /// Create a post route
  ///
  HttpRoute post(
    String path,
    FutureOr Function(HttpRequest req, HttpResponse res) callback, {
    List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
        const [],
    OpenAPIDoc? openAPIDoc,
  }) =>
      createRoute(Method.post, path, callback, middleware, openAPIDoc);

  /// Create a put route
  HttpRoute put(
    String path,
    FutureOr Function(HttpRequest req, HttpResponse res) callback, {
    List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
        const [],
    OpenAPIDoc? openAPIDoc,
  }) =>
      createRoute(Method.put, path, callback, middleware, openAPIDoc);

  /// Create a delete route
  ///
  HttpRoute delete(
    String path,
    FutureOr Function(HttpRequest req, HttpResponse res) callback, {
    List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
        const [],
    OpenAPIDoc? openAPIDoc,
  }) =>
      createRoute(Method.delete, path, callback, middleware, openAPIDoc);

  /// Create a patch route
  ///
  HttpRoute patch(
    String path,
    FutureOr Function(HttpRequest req, HttpResponse res) callback, {
    List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
        const [],
    OpenAPIDoc? openAPIDoc,
  }) =>
      createRoute(Method.patch, path, callback, middleware, openAPIDoc);

  /// Create an options route
  ///
  HttpRoute options(
    String path,
    FutureOr Function(HttpRequest req, HttpResponse res) callback, {
    List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
        const [],
    OpenAPIDoc? openAPIDoc,
  }) =>
      createRoute(Method.options, path, callback, middleware, openAPIDoc);

  /// Create a route that listens on all methods
  ///
  HttpRoute all(
    String path,
    FutureOr Function(HttpRequest req, HttpResponse res) callback, {
    List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
        const [],
    OpenAPIDoc? openAPIDoc,
  }) =>
      createRoute(Method.all, path, callback, middleware, openAPIDoc);

  HttpRoute createRoute(
    Method method,
    String path,
    FutureOr Function(HttpRequest req, HttpResponse res) callback, [
    List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware =
        const [],
    OpenAPIDoc? openAPIDoc,
  ]) {
    final route = HttpRoute(
      '${pathPrefix == '' ? '' : '$pathPrefix/'}$path',
      callback,
      method,
      middleware: middleware,
      openAPIDoc: openAPIDoc,
    );
    app.addRoute(route);
    return route;
  }

  /// Creates a route group with the given path prefix
  Router createRouteGroup(String path) {
    return RouteGroup(app, '${pathPrefix == '' ? '' : '$pathPrefix/'}$path');
  }
}
