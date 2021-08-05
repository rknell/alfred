import 'dart:async';
import 'dart:io';

import '../alfred.dart';
import 'alfred.dart';

class HttpRoute {
  final String route;
  final FutureOr Function(HttpRequest req, HttpResponse res) callback;
  final Method method;
  final List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware;

  final RegExp matcher;
  final List<String> parts;

  HttpRoute(this.route, this.callback, this.method,
      {this.middleware = const []}) : matcher = _buildMatcher(route), parts = route.split('/')..remove('');

  /// Returns `true` if route can match multiple routes due to usage of
  /// wildcards (`*`)
  bool get usesWildcardMatcher => route.contains('*');

  static RegExp _buildMatcher(String route) {
    /// Split route path into segments
    final segments = Uri.parse(route.normalizePath).pathSegments;

    var matcher = '^';
    for (var segment in segments) {
      if (segment == '*' &&
          segment != segments.first &&
          segment == segments.last) {
        /// Generously match path if last segment is wildcard (*)
        /// Example: 'some/path/*' => should match 'some/path'
        matcher += '/?.*';
      } else if (segment != segments.first) {
        /// Add path separators
        matcher += '/';
      }

      /// escape period character
      segment = segment.replaceAll('.', r'\.');

      /// parameter (':something') to anything but slash
      segment = segment.replaceAll(RegExp(':.+'), '[^/]+?');

      /// wildcard ('*') to anything
      segment = segment.replaceAll('*', '.*?');

      matcher += segment;
    }
    matcher += r'$';

    return RegExp(matcher, caseSensitive: false);
  }
}

extension _PathNormalizer on String {
  /// Trims all slashes at the start and end
  String get normalizePath {
    if (startsWith('/')) {
      return substring('/'.length).normalizePath;
    }
    if (endsWith('/')) {
      return substring(0, length - '/'.length).normalizePath;
    }
    return this;
  }
}
