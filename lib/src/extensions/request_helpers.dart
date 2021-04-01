import 'dart:io';

import 'package:http_server/http_server.dart';

import '../route_matcher.dart';

/// Some convenience methods on the [HttpRequest] object to make the api
/// more like ExpressJS
///
extension RequestHelpers on HttpRequest {
  /// Parse the body automatically and return the result
  ///
  Future<Object?> get body async =>
      (await HttpBodyHandler.processRequest(this)).body;

  /// Get the content type
  ///
  ContentType? get contentType => headers.contentType;

  /// Get params
  ///
  Map<String, String> get params => RouteMatcher.getParams(route, uri.path);

  /// Get the matched route of the current request
  ///
  String get route => response.headers.value('x-alfred-route') ?? '';
}
