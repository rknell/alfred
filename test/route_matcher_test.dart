import 'package:alfred/alfred.dart';
import 'package:alfred/src/route_matcher.dart';
import 'package:test/test.dart';

void main() {
  test('it should match routes correctly', () {
    final testRoutes = [
      httpTestRoute('/a/:id/go'),
      httpTestRoute('/a'),
      httpTestRoute('/b/a/:input/another'),
      httpTestRoute('/b/a/:input'),
      httpTestRoute('/b/B/:input'),
      httpTestRoute('/[a-z]/yep'),
    ];

    expect(patterns(match('/a/123/go/a', testRoutes)),
        isEmpty);
    expect(patterns(match('/a', testRoutes)),
        ['/a']);
    expect(patterns(match('/%61', testRoutes)),
        ['/a']);
    expect(patterns(match('/a?query=true', testRoutes)),
        ['/a']);
    expect(patterns(match('/a/123/go', testRoutes)),
        ['/a/:id/go']);
    expect(patterns(match('/b/a/adskfjasjklf/another', testRoutes)),
        ['/b/a/:input/another']);
    expect(patterns(match('/b/a/adskf%2Fjasjklf/another', testRoutes)),
        ['/b/a/:input/another']);
    expect(patterns(match('/b/a/adskfjasj', testRoutes)),
        ['/b/a/:input']);
    expect(patterns(match('/d/yep', testRoutes)),
        ['/[a-z]/yep']);
    expect(patterns(match('/b/B/yep', testRoutes)),
        ['/b/B/:input']);
  });

  test('it should match routes correctly - typed parameters', () {
    final patternRoute = httpTestRoute(r'/xxx/:value1:\d+/:value2');
    final intRoute = httpTestRoute(r'/xxx/:value1:int/:value2');
    final uintRoute = httpTestRoute(r'/xxx/:value1:uint/:value2');
    final doubleRoute = httpTestRoute(r'/xxx/:value1:double/:value2');
    final dateRoute = httpTestRoute(r'/xxx/:value1:date/:value2');
    final tsRoute = httpTestRoute(r'/xxx/:value1:timestamp/:value2');
    final uuidRoute = httpTestRoute(r'/xxx/:value1:uuid/:value2');
    final alphaRoute = httpTestRoute(r'/xxx/:value1:alpha/:value2');
    final hexRoute = httpTestRoute(r'/xxx/:value1:hex/:value2');
    final genericRoute = httpTestRoute(r'/xxx/:value1/:value2');

    final testRoutes = [
      patternRoute, intRoute, uintRoute,
      doubleRoute, dateRoute, tsRoute,
      uuidRoute, alphaRoute, hexRoute,
      genericRoute
    ];

    expect(routes(match('/xxx/123/test', testRoutes)),
        [ patternRoute, intRoute, uintRoute,
          doubleRoute, tsRoute, alphaRoute,
          hexRoute, genericRoute ]);
    expect(routes(match('/xxx/%3123/test', testRoutes)), // %31 is character "1"
        [ patternRoute, intRoute, uintRoute,
          doubleRoute, tsRoute, alphaRoute,
          hexRoute, genericRoute ]);
    expect(routes(match('/xxx/-123/test', testRoutes)),
        [ intRoute, doubleRoute,
          tsRoute, genericRoute ]);
    expect(routes(match('/xxx/123.4/test', testRoutes)),
        [ doubleRoute, genericRoute ]);
    expect(routes(match('/xxx/-123.4/test', testRoutes)),
        [ doubleRoute, genericRoute ]);
    expect(routes(match('/xxx/2021/08/23/test', testRoutes)),
        [ dateRoute ]);
    expect(routes(match('/xxx/-52/08/23/test', testRoutes)),
        [ dateRoute ]);
    expect(routes(match('/xxx/01234567-0123-4567-89ab-cdef01234567/test', testRoutes)),
        [ uuidRoute, genericRoute ]);
    expect(routes(match('/xxx/cafe/test', testRoutes)),
        [ alphaRoute, hexRoute, genericRoute ]);
    expect(routes(match('/xxx/CAFE/test', testRoutes)),
        [ alphaRoute, hexRoute, genericRoute ]);
    expect(routes(match('/xxx/c%61fe/test', testRoutes)), // %61 is character "a"
        [ alphaRoute, hexRoute, genericRoute ]);
    expect(routes(match('/xxx/Name/test', testRoutes)),
        [ alphaRoute, genericRoute ]);
    expect(routes(match('/xxx/N%61me/test', testRoutes)), // %61 is character "a"
        [ alphaRoute, genericRoute ]);
    expect(routes(match('/xxx/Some%20text/test', testRoutes)),
        [ genericRoute ]);
  });

  test('it should match wildcards', () {
    final testRoutes = [
      httpTestRoute('*'),
      httpTestRoute('/a'),
      httpTestRoute('/b'),
    ];

    expect(patterns(match('/a', testRoutes)),
        ['*', '/a']);
  });

  test('it should generously match wildcards for sub-paths', () {
    final testRoutes = [
      httpTestRoute('/some/path/*'),
      httpTestRoute('/some/path*'),
    ];

    expect(patterns(match('/some/path/to', testRoutes)),
        ['/some/path/*', '/some/path*']);
    expect(patterns(match('/some/path/to/something/else', testRoutes)),
        ['/some/path/*', '/some/path*']);
    expect(patterns(match('/some/path/', testRoutes)),
        ['/some/path/*', '/some/path*']);
    expect(patterns(match('/some/path', testRoutes)),
        ['/some/path/*', '/some/path*']);
    expect(patterns(match('/some/pathological', testRoutes)),
        ['/some/path*']);
  });

  test('it should respect the route method', () {
    final testRoutes = [
      httpTestRoute('*', Method.post),
      httpTestRoute('/a', Method.get),
      httpTestRoute('/b', Method.get),
    ];

    expect(patterns(match('/a', testRoutes)),
        ['/a']);
  });

  test('it should extract the route params correctly', () {
    final paramRoute = httpTestRoute('/xxx/:value/:value2');

    var matches = match('/xxx/input/%31%20Item%20inventory%20summary', [ paramRoute ]);
    expect(routes(matches),
        [ paramRoute ]);
    expect(params(matches),
        [ {
            'value': 'input',
            'value2': '1 Item inventory summary'
        } ]
    );

    matches = match('/xxx/input/%31%20%2F%20Item%20inventory%20summary', [ paramRoute ]);
    expect(routes(matches),
        [ paramRoute ]);
    expect(params(matches),
        [ {
            'value': 'input',
            'value2': '1 / Item inventory summary'
        } ]
    );
  });

  test('it should extract the route params correctly - typed parameters', () {
    final dateRoute = httpTestRoute('/xxx/:value:date');
    final intRoute = httpTestRoute('/xxx/:value:int');
    final uintRoute = httpTestRoute('/xxx/:value:uint');
    final uuidRoute = httpTestRoute('/xxx/:value:uuid');
    final doubleRoute = httpTestRoute('/xxx/:value:double');
    final tsRoute = httpTestRoute('/xxx/:value:timestamp');
    final alphaRoute = httpTestRoute('/xxx/:value:alpha');
    final hexRoute = httpTestRoute('/xxx/:value:hex');

    final testRoutes = [ 
        dateRoute, intRoute, uintRoute,
        uuidRoute, doubleRoute, tsRoute,
        alphaRoute, hexRoute
    ];

    var matches = match('/xxx/2021/02/32', testRoutes);
    expect(routes(matches), isEmpty);
    matches = match('/xxx/2021/13/01', testRoutes);
    expect(routes(matches), isEmpty);

    matches = match('/xxx/2021/08/23', testRoutes);
    expect(routes(matches), 
        [ dateRoute ]);
    expect(params(matches), 
        [ { 'value': DateTime.utc(2021, DateTime.august, 23) } ]);

    matches = match('/xxx/2021/02/31', testRoutes);
    expect(routes(matches), 
        [ dateRoute ]);
    expect(params(matches),
        [ { 'value': DateTime.utc(2021, DateTime.march, 3) } ]);

    matches = match('/xxx/-52/09/11', testRoutes);
    expect(routes(matches), 
        [ dateRoute ]);
    expect(params(matches), 
        [ { 'value': DateTime.utc(-52, DateTime.september, 11) } ]);

    matches = match('/xxx/%312345', testRoutes);
    expect(routes(matches), 
        [ intRoute,  uintRoute, doubleRoute, tsRoute, alphaRoute, hexRoute ]);
    expect(params(matches), 
        [ { 'value': 12345 }, { 'value': 12345 }, { 'value': 12345.0 },
          { 'value': DateTime.fromMillisecondsSinceEpoch(12345) },
          { 'value': '12345' }, { 'value': '12345' }, ]);

    matches = match('/xxx/12345', testRoutes);
    expect(routes(matches), 
        [ intRoute,  uintRoute, doubleRoute, tsRoute, alphaRoute, hexRoute ]);
    expect(params(matches), 
        [ { 'value': 12345 }, { 'value': 12345 }, { 'value': 12345.0 },
          { 'value': DateTime.fromMillisecondsSinceEpoch(12345) },
          { 'value': '12345' }, { 'value': '12345' }, ]);

    matches = match('/xxx/-12345', testRoutes);
    expect(routes(matches),
        [ intRoute, doubleRoute, tsRoute ]);
    expect(params(matches),
        [ { 'value': -12345 }, { 'value': -12345.0 },
          { 'value': DateTime.fromMillisecondsSinceEpoch(-12345) } ]);

    matches = match('/xxx/12345.34', testRoutes);
    expect(routes(matches), [ doubleRoute ]);
    expect(params(matches), [ { 'value': 12345.34 } ]);

    matches = match('/xxx/-12345.34', testRoutes);
    expect(routes(matches), [ doubleRoute ]);
    expect(params(matches), [ { 'value': -12345.34 } ]);

    matches = match('/xxx/01234567-89ab-cdef-0123-456789abcdef', testRoutes);
    expect(routes(matches), [ uuidRoute ]);
    expect(params(matches), [ { 'value': '01234567-89ab-cdef-0123-456789abcdef' } ]);

    matches = match('/xxx/cafe', testRoutes);
    expect(routes(matches), [ alphaRoute, hexRoute ]);
    expect(params(matches), [ { 'value': 'cafe' }, { 'value': 'cafe' } ]);

    matches = match('/xxx/text', testRoutes);
    expect(routes(matches), [ alphaRoute ]);
    expect(params(matches), [ { 'value': 'text' } ]);
  });

  test('it should correctly match routes that have a partial match', () {
    final testRoutes = [
      httpTestRoute('/image'),
      httpTestRoute('/imageSource')
    ];

    expect(patterns(match('/imagesource', testRoutes)),
        ['/imageSource']);
  });

  test('it should ignore a trailing slash', () {
    final testRoute = httpTestRoute('/b/');

    expect(routes(match('/b?qs=true', [ testRoute ])),
        [ testRoute ]);
  });

  test('it should ignore a trailing slash in reverse', () {
    final testRoute = httpTestRoute('/b');

    expect(routes(match('/b/?qs=true', [ testRoute ])),
        [ testRoute ]);
  });

  test('it should hit a wildcard route halfway through the uri', () {
    final testRoutes = [
      httpTestRoute('/route/*'),
      httpTestRoute('/route/route2'),
    ];

    expect(patterns(match('/route/route2', testRoutes)),
        ['/route/*', '/route/route2']);
  });

  test('it should hit a wildcard route halfway through the uri - sibling', () {
    final testRoutes = [
      httpTestRoute('/route*'),
      httpTestRoute('/route'),
      httpTestRoute('/route/test'),
    ];

    expect(patterns(match('/route', testRoutes)),
        ['/route*', '/route']);

    expect(patterns(match('/route/test', testRoutes)),
        ['/route*', '/route/test']);
  });

  test('it should match wildcards in the middle', () {
    final testRoutes = [
      httpTestRoute('/a/*/b'),
      httpTestRoute('/a/*/*/b'),
    ];

    expect(match('/a', testRoutes),
        isEmpty);
    expect(patterns(match('/a/x/b', testRoutes)),
        ['/a/*/b']);
    expect(patterns(match('/a/x/y/b', testRoutes)),
        ['/a/*/b', '/a/*/*/b']);
  });

  test('it should match wildcards at the beginning', () {
    final jpgRoute = httpTestRoute('*.jpg');

    final testRoutes = [ jpgRoute ];

    expect(match('xjpg', testRoutes),
        isEmpty);
    expect(routes(match('.jpg', testRoutes)),
        [ jpgRoute ]);
    expect(routes(match('path/to/picture.jpg', testRoutes)), 
        [ jpgRoute ]);
  });

  test('it should match regex expressions within segments', () {
    final testRoutes = [
      httpTestRoute('[a-z]+/[0-9]+'),
      httpTestRoute('[a-z]{5}'),
      httpTestRoute('(a|b)/c'),
    ];

    expect(match('a/b', testRoutes),
        isEmpty);
    expect(match('3/a', testRoutes),
        isEmpty);
    expect(match('abc', testRoutes),
        isEmpty);
    expect(match('abc42', testRoutes),
        isEmpty);
    expect(patterns(match('x/323', testRoutes)), 
        ['[a-z]+/[0-9]+']);
    expect(patterns(match('answer/42', testRoutes)),
        ['[a-z]+/[0-9]+']);
    expect(patterns(match('abcde', testRoutes)),
        ['[a-z]{5}']);
    expect(patterns(match('final', testRoutes)), 
        ['[a-z]{5}']);
    expect(patterns(match('a/c', testRoutes)), 
        ['(a|b)/c']);
    expect(patterns(match('b/c', testRoutes)), 
        ['(a|b)/c']);
  });
}

HttpRoute httpTestRoute(String route, [ Method method = Method.get ]) =>
    HttpRoute(route, _callback, method);

List<HttpRouteMatch> match(String input, List<HttpRoute> routes) =>
    RouteMatcher.match(input, routes, Method.get).toList();

List<HttpRoute> routes(Iterable<HttpRouteMatch> matches) =>
    matches.map((e) => e.route).toList();

List<String> patterns(Iterable<HttpRouteMatch> matches) =>
    matches.map((e) => e.route.route).toList();

List<Map<String, dynamic>> params(Iterable<HttpRouteMatch> matches) =>
    matches.map((e) => e.params).toList();

Future Function(HttpRequest, HttpResponse) get _callback =>
    (req, res) async {};
