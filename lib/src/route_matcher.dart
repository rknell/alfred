import '../alfred.dart';
import 'alfred.dart';
import 'http_route.dart';

class RouteMatcher {
  static List<HttpRoute> match(
      String input, List<HttpRoute> options, Method method) {
    final output = <HttpRoute>[];

    final inputPath = Uri.parse(input).path.normalizePath;

    for (final option in options) {
      /// Check if http method matches
      if (option.method != method && option.method != Method.all) {
        continue;
      }

      /// Split route path into segments
      final segments = Uri.parse(option.route.normalizePath).pathSegments;

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

      if (RegExp(matcher, caseSensitive: false).hasMatch(inputPath)) {
        output.add(option);
      }
    }

    return output;
  }

  static Map<String, String> getParams(String route, String input) {
    final routeParts = route.split('/')..remove('');
    final inputParts = input.split('/')..remove('');

    if (inputParts.length != routeParts.length) {
      throw NotMatchingRouteException();
    }

    final output = <String, String>{};

    for (var i = 0; i < routeParts.length; i++) {
      final routePart = routeParts[i];
      final inputPart = inputParts[i];

      if (routePart.contains(':')) {
        final routeParams = routePart.split(':')..remove('');

        for (var item in routeParams) {
          output[item] = inputPart;
        }
      }
    }
    return output;
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

/// Throws when trying to extract params and the route you are extracting from
/// does not match the supplied pattern
///
class NotMatchingRouteException implements Exception {}
