import 'dart:async';
import 'dart:io';

import '../alfred.dart';
import 'extensions/string_helpers.dart';
import 'alfred.dart';

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

  HttpRoute(this.route, this.callback, this.method, {this.middleware = const []})
    : usesWildcardMatcher = route.contains('*')
  {
    // Split route path into segments
    final segments = Uri.parse(route.normalizePath).pathSegments;

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

      // escape period character
      segment = segment.replaceAll('.', r'\.');

      // parse parameter if any
      final param = HttpRouteParam.tryParse(segment);
      if (param != null) {
        if (_params.containsKey(param.name)) throw DuplicateParameterException(param.name);
        _params[param.name] = param;
        segment = r'(?<' + param.name + r'>' + param.pattern + ')';
      }

      // wildcard ('*') to anything
      segment = segment.replaceAll('*', '.*?');
      pattern += segment;
    }

    pattern += r'$';
    matcher = RegExp(pattern, caseSensitive: false);
  }

  @override
  String toString() => route;
}

// Throws when a route contains duplicate parameters
//
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

  Object getValue(String value) {
    // path has been decoded already except for '/'
    value = value.decodeUri(DecodeMode.SlashOnly);
    switch (type) {
      case HttpRouteParamType.int:
        return int.parse(value);
      case HttpRouteParamType.uint:
        return int.parse(value);
      case HttpRouteParamType.double:
        return double.parse(value);
      case HttpRouteParamType.date:
        // note: the RegExp enforces month between 1 and 12 and day between 1 and 31
        // but it does not care about leap years and actual number of days in month
        // DateTime will accept "invalid" dates and adjust the result accordingly
        // eg. 2021-02-31 --> 2021-03-03 
        final components = value.split('/').map(int.parse).toList();
        return DateTime.utc(components[0], components[1], components[2]);
      case HttpRouteParamType.timestamp:
        return DateTime.fromMillisecondsSinceEpoch(int.parse(value));
      case HttpRouteParamType.hex:
        return value;
      case HttpRouteParamType.alpha:
        return value;
      case HttpRouteParamType.uuid:
        // Dart does not have a builtin Uuid or Guid type
        // no effort is made to ensure UUID conforms to RFC4122
        return value;
      default:
        return value;
    }
  }

  static HttpRouteParam? tryParse(String segment) {
    if (!segment.startsWith(':')) return null;
    HttpRouteParamType? type;
    var pattern = '';
    var name = segment.substring(1);
    final idx = name.indexOf(':');
    if (idx > 0) {
      pattern = name.substring(idx + 1);
      name = name.substring(0, idx);
      switch (pattern.toLowerCase()) {
        case 'int':
          type = HttpRouteParamType.int;
          pattern = r'-?\d+';
          break;
        case 'uint':
          type = HttpRouteParamType.uint;
          pattern = r'\d+';
          break;
        case 'double':
          type = HttpRouteParamType.double;
          pattern = r'-?\d+(?:\.\d+)?';
          break;
        case 'date':
          type = HttpRouteParamType.date;
          // note: make sure month is in range 01-12 and day is in range 01-31
          pattern = r'-?\d{1,6}/(?:0[1-9]|1[012])/(?:0[1-9]|[12][0-9]|3[01])';
          break;
        case 'timestamp':
          type = HttpRouteParamType.timestamp;
          pattern = r'-?\d+';
          break;
        case 'hex':
          type = HttpRouteParamType.hex;
          pattern = r'[0-9a-f]+';
          break;
        case 'alpha':
          type = HttpRouteParamType.alpha;
          pattern = r'[a-z0-9_]+';
          break;
        case 'uuid':
          type = HttpRouteParamType.uuid;
          pattern = r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}';
          break;
      }
    } else {
      pattern = r'[^/]+?';
    }
    return HttpRouteParam(name, pattern, type);
  }
}

enum HttpRouteParamType {
  int,
  uint,
  double,
  date,
  timestamp,
  hex,
  alpha,
  uuid
}
