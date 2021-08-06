import 'dart:async';
import 'dart:io';

import '../alfred.dart';
import 'extensions/string_helpers.dart';
import 'alfred.dart';

class HttpRoute {
  final String route;
  final FutureOr Function(HttpRequest req, HttpResponse res) callback;
  final Method method;
  final List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware;

  final RegExp matcher;

  /// Returns `true` if route can match multiple routes due to usage of
  /// wildcards (`*`)
  final bool usesWildcardMatcher;

  HttpRoute(this.route, this.callback, this.method, {this.middleware = const []})
    : matcher = _buildMatcher(route), usesWildcardMatcher = route.contains('*');

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
        break;
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
