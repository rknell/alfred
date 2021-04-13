import 'package:alfred/alfred.dart';
import 'package:alfred/src/route_matcher.dart';
import 'package:test/test.dart';

void main() {
  test('it should match routes correctly', () {
    final testRoutes = [
      HttpRoute('/a/:id/go', _callback, Method.get),
      HttpRoute('/a', _callback, Method.get),
      HttpRoute('/b/a/:input/another', _callback, Method.get),
      HttpRoute('/b/a/:input', _callback, Method.get),
      HttpRoute('/b/B/:input', _callback, Method.get),
      HttpRoute('/[a-z]/yep', _callback, Method.get),
    ];

    expect(match('/a', testRoutes), ['/a']);
    expect(match('/a?query=true', testRoutes), ['/a']);
    expect(match('/a/123/go', testRoutes), ['/a/:id/go']);
    expect(match('/a/123/go/a', testRoutes), <String>[]);
    expect(match('/b/a/adskfjasjklf/another', testRoutes),
        ['/b/a/:input/another']);
    expect(match('/b/a/adskfjasj', testRoutes), ['/b/a/:input']);
    expect(match('/d/yep', testRoutes), ['/[a-z]/yep']);
    expect(match('/b/B/yep', testRoutes), ['/b/B/:input']);
  });

  test('it should match wildcards', () {
    final testRoutes = [
      HttpRoute('*', _callback, Method.get),
      HttpRoute('/a', _callback, Method.get),
      HttpRoute('/b', _callback, Method.get),
    ];

    expect(match('/a', testRoutes), ['*', '/a']);
  });

  test('it should generously match wildcards for sub-paths', () {
    final testRoutes = [
      HttpRoute('path/*', _callback, Method.get),
    ];

    expect(match('/path/to', testRoutes), ['path/*']);
    expect(match('/path/', testRoutes), ['path/*']);
    expect(match('/path', testRoutes), ['path/*']);
  });

  test('it should respect the route method', () {
    final testRoutes = [
      HttpRoute('*', _callback, Method.post),
      HttpRoute('/a', _callback, Method.get),
      HttpRoute('/b', _callback, Method.get),
    ];

    expect(match('/a', testRoutes), ['/a']);
  });

  test('it should extract the route params correctly', () {
    expect(RouteMatcher.getParams('/a/:value/:value2', '/a/input/input2'), {
      'value': 'input',
      'value2': 'input2',
    });
  });

  test('it should correctly match routes that have a partial match', () {
    final testRoutes = [
      HttpRoute('/image', _callback, Method.get),
      HttpRoute('/imageSource', _callback, Method.get)
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
      HttpRoute('/b/', _callback, Method.get),
    ];

    expect(match('/b?qs=true', testRoutes), ['/b/']);
  });

  test('it should ignore a trailing slash in reverse', () {
    final testRoutes = [
      HttpRoute('/b', _callback, Method.get),
    ];

    expect(match('/b/?qs=true', testRoutes), ['/b']);
  });

  test('it should hit a wildcard route halfway through the uri', () {
    final testRoutes = [
      HttpRoute('/route/*', _callback, Method.get),
      HttpRoute('/route/route2', _callback, Method.get),
    ];

    expect(match('/route/route2', testRoutes), ['/route/*', '/route/route2']);
  });

  test('it should hit a wildcard route halfway through the uri - sibling', () {
    final testRoutes = [
      HttpRoute('/route*', _callback, Method.get),
      HttpRoute('/route', _callback, Method.get),
      HttpRoute('/route/test', _callback, Method.get),
    ];

    expect(match('/route', testRoutes), ['/route*', '/route']);

    expect(match('/route/test', testRoutes), ['/route*', '/route/test']);
  });

  test('it should match wildcards in the middle', () {
    final testRoutes = [
      HttpRoute('/a/*/b', _callback, Method.get),
      HttpRoute('/a/*/*/b', _callback, Method.get),
    ];

    expect(match('/a', testRoutes), <String>[]);
    expect(match('/a/x/b', testRoutes), ['/a/*/b']);
    expect(match('/a/x/y/b', testRoutes), ['/a/*/b', '/a/*/*/b']);
  });

  test('it should match wildcards at the beginning', () {
    final testRoutes = [
      HttpRoute('*.jpg', _callback, Method.get),
    ];

    expect(match('xjpg', testRoutes), <String>[]);
    expect(match('.jpg', testRoutes), <String>['*.jpg']);
    expect(match('path/to/picture.jpg', testRoutes), <String>['*.jpg']);
  });

  test('it should match regex expressions within segments', () {
    final testRoutes = [
      HttpRoute('[a-z]+/[0-9]+', _callback, Method.get),
      HttpRoute('[a-z]{5}', _callback, Method.get),
      HttpRoute('(a|b)/c', _callback, Method.get),
    ];

    expect(match('a/b', testRoutes), <String>[]);
    expect(match('3/a', testRoutes), <String>[]);
    expect(match('x/323', testRoutes), <String>['[a-z]+/[0-9]+']);
    expect(match('answer/42', testRoutes), <String>['[a-z]+/[0-9]+']);
    expect(match('abc', testRoutes), <String>[]);
    expect(match('abc42', testRoutes), <String>[]);
    expect(match('abcde', testRoutes), <String>['[a-z]{5}']);
    expect(match('final', testRoutes), <String>['[a-z]{5}']);
    expect(match('a/c', testRoutes), <String>['(a|b)/c']);
    expect(match('b/c', testRoutes), <String>['(a|b)/c']);
  });
}

List<String> match(String input, List<HttpRoute> routes) =>
    RouteMatcher.match(input, routes, Method.get).map((e) => e.route).toList();

Future Function(HttpRequest, HttpResponse) get _callback => (req, res) async {};
