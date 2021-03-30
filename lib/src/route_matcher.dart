import 'dart:async';
import 'dart:io';

import '../alfred.dart';

class RouteMatcher {
  static List<HttpRoute> match(
      String input, List<HttpRoute> options, RouteMethod method) {
    final inputParts = List<String>.from(Uri.parse(input).pathSegments);

    if (inputParts.isNotEmpty && inputParts.last == "") {
      inputParts.removeLast();
    }

    var output = <HttpRoute>[];

    for (var item in options) {
      if (item.method != method && item.method != RouteMethod.all) {
        continue;
      }

      if (item.route == "*") {
        output.add(item);
        continue;
      }

      final itemParts = List<String>.from(Uri.parse(item.route).pathSegments);

      if (itemParts.isNotEmpty && itemParts.last == "") {
        itemParts.removeLast();
      }

      if (itemParts.length != inputParts.length) {
        continue;
      }

      var matchesAll = true;
      for (var i = 0; i < inputParts.length; i++) {
        if (itemParts[i].startsWith(":")) {
          continue;
        }
        if (!RegExp("^${itemParts[i]}\$", caseSensitive: false)
            .hasMatch(inputParts[i])) {
          matchesAll = false;
          break;
        }
      }
      if (matchesAll) {
        output.add(item);
      }
    }
    return output;
  }

  static Map<String, String> getParams(String route, String input) {
    final routeParts = route.split("/")..remove("");
    final inputParts = input.split("/")..remove("");

    if (inputParts.length != routeParts.length) {
      throw NotMatchingRouteException();
    }

    final output = <String, String>{};

    for (var i = 0; i < routeParts.length; i++) {
      final routePart = routeParts[i];
      final inputPart = inputParts[i];

      if (routePart.contains(":")) {
        final routeParams = routePart.split(":")..remove("");

        for (var item in routeParams) {
          output[item] = inputPart;
        }
      }
    }
    return output;
  }
}

class HttpRoute {
  final String route;
  final FutureOr Function(HttpRequest req, HttpResponse res) callback;
  final RouteMethod method;
  final List<FutureOr Function(HttpRequest req, HttpResponse res)> middleware;

  HttpRoute(this.route, this.callback, this.method,
      {this.middleware = const []});
}

class NotMatchingRouteException implements Exception {}
