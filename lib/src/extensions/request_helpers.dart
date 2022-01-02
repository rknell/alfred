import 'dart:io';

import '../../alfred.dart';
import '../route_matcher.dart';

/// Some convenience methods on the [HttpRequest] object to make the api
/// more like ExpressJS
///
extension RequestHelpers on HttpRequest {
  /// Parse the body automatically and return the result
  ///
  Future<Object?> get body async {
    const cachedBodyKey = '_cachedBodyResponse';
    final cachedBody = store.tryGet<Object?>(cachedBodyKey);
    if (cachedBody != null) {
      return cachedBody;
    } else {
      final dynamic body = (await HttpBodyHandler.processRequest(this)).body;
      store.set(cachedBodyKey, body);
      return body;
    }
  }

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
  Map<String, dynamic> get params =>
      store.tryGet<HttpRouteMatch>('_internal_match')?.params ??
      <String, dynamic>{};

  /// Get the matched route URI of the current request
  ///
  String get route =>
      store.tryGet<HttpRouteMatch>('_internal_match')?.route.route ?? '';

  /// Get the matched route of the current request
  ///
  HttpRouteMatch? get match => store.tryGet<HttpRouteMatch>('_internal_match');

  /// Get the intercepted exception
  ///
  dynamic get exception => store.tryGet<dynamic>('_internal_exception');

  /// Get Alfred instance which is associated with this request
  ///
  Alfred get alfred => store.get<Alfred>('_internal_alfred');
}
