import 'package:alfred/alfred.dart';
import 'package:alfred/src/route_matcher.dart';
import 'package:test/test.dart';

void main() {
  test('it should match routes correctly', () {
    final testRoutes = [
      HttpRoute('/a/:id/go', (req, res) async {}, Method.get),
      HttpRoute('/a', (req, res) async {}, Method.get),
      HttpRoute('/b/a/:input/another', (req, res) async {}, Method.get),
      HttpRoute('/b/a/:input', (req, res) async {}, Method.get),
      HttpRoute('/b/B/:input', (req, res) async {}, Method.get),
      HttpRoute('/[a-z]/yep', (req, res) async {}, Method.get),
    ];

    expect(
        RouteMatcher.match('/a', testRoutes, Method.get)
            .map((e) => e.route)
            .toList(),
        ['/a']);
    expect(
        RouteMatcher.match('/a?query=true', testRoutes, Method.get)
            .map((e) => e.route)
            .toList(),
        ['/a']);
    expect(
        RouteMatcher.match('/a/123/go', testRoutes, Method.get)
            .map((e) => e.route)
            .toList(),
        ['/a/:id/go']);
    expect(
        RouteMatcher.match('/a/123/go/a', testRoutes, Method.get)
            .map((e) => e.route)
            .toList(),
        <String>[]);
    expect(
        RouteMatcher.match('/b/a/adskfjasjklf/another', testRoutes, Method.get)
            .map((e) => e.route)
            .toList(),
        ['/b/a/:input/another']);
    expect(
        RouteMatcher.match('/b/a/adskfjasj', testRoutes, Method.get)
            .map((e) => e.route)
            .toList(),
        ['/b/a/:input']);
    expect(
        RouteMatcher.match('/d/yep', testRoutes, Method.get)
            .map((e) => e.route)
            .toList(),
        ['/[a-z]/yep']);
    expect(
        RouteMatcher.match('/b/B/yep', testRoutes, Method.get)
            .map((e) => e.route)
            .toList(),
        ['/b/B/:input']);
  });

  test('it should match wildcards', () {
    final testRoutes = [
      HttpRoute('*', (req, res) async {}, Method.get),
      HttpRoute('/a', (req, res) async {}, Method.get),
      HttpRoute('/b', (req, res) async {}, Method.get),
    ];

    expect(
        RouteMatcher.match('/a', testRoutes, Method.get)
            .map((e) => e.route)
            .toList(),
        ['*', '/a']);
  });

  test('it should generously match wildcards for sub-paths', () {
    final testRoutes = [
      HttpRoute('path/*', (req, res) async {}, Method.get),
    ];

    expect(
        RouteMatcher.match('/path/to', testRoutes, Method.get).isNotEmpty, true);
    expect(
        RouteMatcher.match('/path/', testRoutes, Method.get).isNotEmpty, true);
    expect(
        RouteMatcher.match('/path', testRoutes, Method.get).isNotEmpty, true);
  });

  test('it should respect the routemethod', () {
    final testRoutes = [
      HttpRoute('*', (req, res) async {}, Method.post),
      HttpRoute('/a', (req, res) async {}, Method.get),
      HttpRoute('/b', (req, res) async {}, Method.get),
    ];

    expect(
        RouteMatcher.match('/a', testRoutes, Method.get)
            .map((e) => e.route)
            .toList(),
        ['/a']);
  });

  test('it should extract the route params correctly', () {
    expect(RouteMatcher.getParams('/a/:value/:value2', '/a/input/input2'), {
      'value': 'input',
      'value2': 'input2',
    });
  });

  test('it should correctly match routes that have a partial match', () {
    final testRoutes = [
      HttpRoute('/image', (req, res) async {}, Method.get),
      HttpRoute('/imageSource', (req, res) async {}, Method.get)
    ];

    expect(
        RouteMatcher.match('/imagesource', testRoutes, Method.get)
            .map((e) => e.route)
            .toList(),
        ['/imageSource']);
  });

  test('it handles a dodgy getParams request', () {
    var hitError = false;

    try {
      RouteMatcher.getParams('/id/:id/abc', '/id/10');
    } on NotMatchingRouteException catch (_) {
      hitError = true;
    }
    expect(hitError, true);
  });

  test('it should ignore a trailing slash', () {
    final testRoutes = [
      HttpRoute('/b/', (req, res) async {}, Method.get),
    ];

    expect(
        RouteMatcher.match('/b?qs=true', testRoutes, Method.get)
            .map((e) => e.route)
            .toList(),
        ['/b/']);
  });

  test('it should ignore a trailing slash in reverse', () {
    final testRoutes = [
      HttpRoute('/b', (req, res) async {}, Method.get),
    ];

    expect(
        RouteMatcher.match('/b/?qs=true', testRoutes, Method.get)
            .map((e) => e.route)
            .toList(),
        ['/b']);
  });

  test('it should hit a wildcard route halfway through the uri', () {
    final testRoutes = [
      HttpRoute('/route/*', (req, res) async {}, Method.get),
      HttpRoute('/route/route2', (req, res) async {}, Method.get),
    ];

    expect(
        RouteMatcher.match('/route/route2', testRoutes, Method.get)
            .map((e) => e.route)
            .toList(),
        ['/route/*', '/route/route2']);
  });

  test('it should hit a wildcard route halfway through the uri - sibling', () {
    final testRoutes = [
      HttpRoute('/route*', (req, res) async {}, Method.get),
      HttpRoute('/route', (req, res) async {}, Method.get),
      HttpRoute('/route/test', (req, res) async {}, Method.get),
    ];

    expect(
        RouteMatcher.match('/route', testRoutes, Method.get)
            .map((e) => e.route)
            .toList(),
        ['/route*', '/route']);

    expect(
        RouteMatcher.match('/route/test', testRoutes, Method.get)
            .map((e) => e.route)
            .toList(),
        ['/route*', '/route/test']);
  });
}
