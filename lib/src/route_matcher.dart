import '../alfred.dart';
import 'extensions/string_helpers.dart';
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

      if (option.matcher.hasMatch(inputPath)) {
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
          output[item] = Uri.decodeComponent(inputPart);
        }
      }
    }
    return output;
  }
}

/// Throws when trying to extract params and the route you are extracting from
/// does not match the supplied pattern
///
class NotMatchingRouteException implements Exception {}
