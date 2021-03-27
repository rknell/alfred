import 'package:test/test.dart';
import 'package:webserver/src/route_matcher.dart';
import 'package:webserver/webserver.dart';

void main() {
  test("it should match routes correctly", () {
    final testRoutes = [
      HttpRoute("/a/:id/go", (req, res) async {}, RouteMethod.get),
      HttpRoute("/a", (req, res) async {}, RouteMethod.get),
      HttpRoute("/b/a/:input/another", (req, res) async {}, RouteMethod.get),
      HttpRoute("/b/a/:input", (req, res) async {}, RouteMethod.get),
      HttpRoute("/b/B/:input", (req, res) async {}, RouteMethod.get),
      HttpRoute("/[a-z]/yep", (req, res) async {}, RouteMethod.get),
    ];

    expect(
        RouteMatcher.match("/a", testRoutes, RouteMethod.get)
            .map((e) => e.route)
            .toList(),
        ["/a"]);
    expect(
        RouteMatcher.match("/a?query=true", testRoutes, RouteMethod.get)
            .map((e) => e.route)
            .toList(),
        ["/a"]);
    expect(
        RouteMatcher.match("/a/123/go", testRoutes, RouteMethod.get)
            .map((e) => e.route)
            .toList(),
        ["/a/:id/go"]);
    expect(
        RouteMatcher.match("/a/123/go/a", testRoutes, RouteMethod.get)
            .map((e) => e.route)
            .toList(),
        []);
    expect(
        RouteMatcher.match(
                "/b/a/adskfjasjklf/another", testRoutes, RouteMethod.get)
            .map((e) => e.route)
            .toList(),
        ["/b/a/:input/another"]);
    expect(
        RouteMatcher.match("/b/a/adskfjasj", testRoutes, RouteMethod.get)
            .map((e) => e.route)
            .toList(),
        ["/b/a/:input"]);
    expect(
        RouteMatcher.match("/d/yep", testRoutes, RouteMethod.get)
            .map((e) => e.route)
            .toList(),
        ["/[a-z]/yep"]);
    expect(
        RouteMatcher.match("/b/B/yep", testRoutes, RouteMethod.get)
            .map((e) => e.route)
            .toList(),
        ["/b/B/:input"]);
  });

  test("it should match wildcards", () {
    final testRoutes = [
      HttpRoute("*", (req, res) async {}, RouteMethod.get),
      HttpRoute("/a", (req, res) async {}, RouteMethod.get),
      HttpRoute("/b", (req, res) async {}, RouteMethod.get),
    ];

    expect(
        RouteMatcher.match("/a", testRoutes, RouteMethod.get)
            .map((e) => e.route)
            .toList(),
        ["*", "/a"]);
  });

  test("it should respect the routemethod", () {
    final testRoutes = [
      HttpRoute("*", (req, res) async {}, RouteMethod.post),
      HttpRoute("/a", (req, res) async {}, RouteMethod.get),
      HttpRoute("/b", (req, res) async {}, RouteMethod.get),
    ];

    expect(
        RouteMatcher.match("/a", testRoutes, RouteMethod.get)
            .map((e) => e.route)
            .toList(),
        ["/a"]);
  });

  test("it should extract the route params correctly", () {
    expect(RouteMatcher.getParams("/a/:value/:value2", "/a/input/input2"), {
      "value": "input",
      "value2": "input2",
    });
  });

  test("it should correctly match routes that have a partial match", () {
    final testRoutes = [
      HttpRoute("/image", (req, res) async {}, RouteMethod.get),
      HttpRoute("/imageSource", (req, res) async {}, RouteMethod.get)
    ];

    expect(
        RouteMatcher.match("/imagesource", testRoutes, RouteMethod.get)
            .map((e) => e.route)
            .toList(),
        ["/imageSource"]);
  });
}
