import '../alfred.dart';

class RouteMatcher {
  static Iterable<HttpRouteMatch> match(
      String input, List<HttpRoute> options, Method method) sync* {
    // decode URL path before matching except for "/"
    final inputPath =
        Uri.parse(input).path.normalizePath.decodeUri(DecodeMode.AllButSlash);

    for (final option in options) {
      // Check if http method matches
      if (option.method != method && option.method != Method.all) {
        continue;
      }

      // Match against route RegExp and capture params if valid
      final match = option.matcher.firstMatch(inputPath);
      if (match != null) {
        final routeMatch = HttpRouteMatch.tryParse(option, match);
        if (routeMatch != null) {
          yield routeMatch;
        }
      }
    }
  }
}

/// Retains the matched route and parameter values extracted
/// from the Uri
///
class HttpRouteMatch {
  HttpRouteMatch._(this.route, this.params);

  static HttpRouteMatch? tryParse(HttpRoute route, RegExpMatch match) {
    try {
      final params = <String, dynamic>{};
      for (var param in route.params) {
        var value = match.namedGroup(param.name);
        if (value == null) {
          if (param.pattern != '*') {
            return null;
          }
          value = '';
        }
        params[param.name] = param.getValue(value);
      }
      return HttpRouteMatch._(route, params);
    } catch (e) {
      return null;
    }
  }

  final HttpRoute route;
  final Map<String, dynamic> params;
}
