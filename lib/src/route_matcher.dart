import '../alfred.dart';
import 'alfred.dart';
import 'http_route.dart';

class RouteMatcher {
  static List<HttpRoute> match(
      String input, List<HttpRoute> options, Method method) {
    final inputParts = List<String>.from(Uri.parse(input).pathSegments);

    if (inputParts.isNotEmpty && inputParts.last == '') {
      inputParts.removeLast();
    }

    var output = <HttpRoute>[];

    for (var item in options) {
      var mustWildcard = false;

      if (item.method != method && item.method != Method.all) {
        continue;
      }

      if (item.route == '*') {
        output.add(item);
        continue;
      }

      /// Wildcard describes sub-path
      ///
      if (item.route.endsWith('/*')) {
        final routeWithoutSlash =
            item.route.normalizePath.substring(0, item.route.normalizePath.length - '/*'.length);
        var normalizedInput = input.normalizePath;
        if (normalizedInput.startsWith(routeWithoutSlash)) {
          output.add(item);
          continue;
        }
      }

      final itemParts = List<String>.from(Uri.parse(item.route).pathSegments);

      if (itemParts.isNotEmpty && itemParts.last == '') {
        itemParts.removeLast();
      }

      if (itemParts.length != inputParts.length) {
        mustWildcard = true;
      }

      if (itemParts.length > inputParts.length) {
        continue;
      }

      var matchesAll = true;
      var didWildcard = false;
      for (var i = 0; i < itemParts.length; i++) {
        if (itemParts[i].startsWith(':')) {
          continue;
        }
        if (itemParts[i] == '*') {
          didWildcard = true;
          break;
        }
        if (itemParts[i].endsWith('*')) {
          didWildcard = true;
          break;
        }
        if (!RegExp('^${itemParts[i]}\$', caseSensitive: false)
            .hasMatch(inputParts[i])) {
          matchesAll = false;
          break;
        }
      }
      if ((mustWildcard == false || mustWildcard && didWildcard) &&
          matchesAll) {
        output.add(item);
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
