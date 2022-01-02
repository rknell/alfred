import 'dart:async';

import '../alfred.dart';

class HttpRoute {
  final Method method;
  final String route;
  final FutureOr Function(HttpRequest req, HttpResponse res) callback;
  final List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware;

  // The RegExp used to match the input URI
  late final RegExp matcher;

  // Returns `true` if route can match multiple routes due to usage of
  // wildcards (`*`)
  final bool usesWildcardMatcher;

  // The route parameters (name, type and pattern)
  final Map<String, HttpRouteParam> _params = <String, HttpRouteParam>{};

  Iterable<HttpRouteParam> get params => _params.values;

  HttpRoute(this.route, this.callback, this.method,
      {this.middleware = const []})
      : usesWildcardMatcher = route.contains('*') {
    // Split route path into segments
    final segments = Uri.tryParse(route.normalizePath)?.pathSegments ??
        [route.normalizePath];

    var pattern = '^';
    for (var segment in segments) {
      if (segment == '*' &&
          segment != segments.first &&
          segment == segments.last) {
        // Generously match path if last segment is wildcard (*)
        // Example: 'some/path/*' => should match 'some/path', 'some/path/', 'some/path/with/children'
        //                           but not 'some/pathological'
        pattern += r'(?:/.*|)';
        break;
      } else if (segment != segments.first) {
        // Add path separators
        pattern += '/';
      }

      // parse parameter if any
      final param = HttpRouteParam.tryParse(segment);
      if (param != null) {
        if (_params.containsKey(param.name)) {
          throw DuplicateParameterException(param.name);
        }
        _params[param.name] = param;
        segment = r'(?<' + param.name + r'>' + param.pattern + ')';
      } else {
        // escape period character
        segment = segment.replaceAll('.', r'\.');
        // wildcard ('*') to anything
        segment = segment.replaceAll('*', '.*?');
      }

      pattern += segment;
    }

    pattern += r'$';
    matcher = RegExp(pattern, caseSensitive: false);
  }

  @override
  String toString() => route;
}

/// Throws when a route contains duplicate parameters
///
class DuplicateParameterException implements Exception {
  DuplicateParameterException(this.name);

  final String name;
}

/// Class used to retain parameter information (name, type, pattern)
///
class HttpRouteParam {
  HttpRouteParam(this.name, this.pattern, this.type);

  final String name;
  final String pattern;
  final HttpRouteParamType? type;

  dynamic getValue(String value) {
    // path has been decoded already except for '/'
    value = value.decodeUri(DecodeMode.SlashOnly);
    return type?.parse(value) ?? value;
  }

  static final paramTypes = <HttpRouteParamType>[];

  static HttpRouteParam? tryParse(String segment) {
    /// route param is of the form ":name" or ":name:pattern"
    /// the ":pattern" part can be a regular expression
    /// or a param type name
    if (!segment.startsWith(':')) return null;
    var pattern = '';
    var name = segment.substring(1);
    HttpRouteParamType? type;
    final idx = name.indexOf(':');
    if (idx > 0) {
      pattern = name.substring(idx + 1);
      name = name.substring(0, idx);
      final typeName = pattern.toLowerCase();
      type = paramTypes
          .cast<HttpRouteParamType?>()
          .firstWhere((t) => t!.name == typeName, orElse: () => null);
      if (type != null) {
        // the pattern matches a param type name
        pattern = type.pattern;
      }
    } else {
      // anything but a slash
      pattern = r'[^/]+?';
    }
    return HttpRouteParam(name, pattern, type);
  }
}
