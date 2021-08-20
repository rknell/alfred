import 'dart:io';

import 'package:alfred/src/body_parser/http_body.dart';

import '../../alfred.dart';
import '../plugins/store_plugin.dart';
import '../route_matcher.dart';

/// Some convenience methods on the [HttpRequest] object to make the api
/// more like ExpressJS
///
extension RequestHelpers on HttpRequest {
  /// Parse the body automatically and return the result
  ///
  Future<Object?> get body async =>
      (await HttpBodyHandler.processRequest(this)).body;

  /// Parse the body, and convert it to a json map
  ///
  Future<Map<String, dynamic>> get bodyAsJsonMap async =>
      Map<String, dynamic>.from((await body) as Map);

  /// Parse the body, and convert it to a json list
  ///
  Future<List<dynamic>> get bodyAsJsonList async => (await body) as List;

  /// Get the content type
  ///
  ContentType? get contentType => headers.contentType;

  /// Get params
  ///
  Map<String, String> get params =>
      store.getOrSet<Map<String, String>>('_internal_params',
        () => RouteMatcher.getParams(route, uri.path));

  /// Get the matched route of the current request
  ///
  String get route => store.tryGet<String>('_internal_route') ?? '';

  /// Get Alfred instance which is associated with this request
  ///
  Alfred get alfred => store.get<Alfred>('_internal_alfred');
}
