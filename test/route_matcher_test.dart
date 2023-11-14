import 'package:alfred/alfred.dart';
import 'package:alfred/src/route_matcher.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    // used to register default param types
    Alfred();
  });

  tearDown(() {
    HttpRouteParam.paramTypes.clear();
  });

  test('it should match routes correctly', () {
    final testRoutes = [
      httpTestRoute('/a/:id/go'),
      httpTestRoute('/a'),
      httpTestRoute('/b/a/:input/another'),
      httpTestRoute('/b/a/:input'),
      httpTestRoute('/b/B/:input'),
      httpTestRoute('/[a-z]/yep'),
    ];

    expect(patterns(match('/a/123/go/a', testRoutes)), isEmpty);
    expect(patterns(match('/a', testRoutes)), ['/a']);
    expect(patterns(match('/%61', testRoutes)), ['/a']);
    expect(patterns(match('/a?query=true', testRoutes)), ['/a']);
    expect(patterns(match('/a/123/go', testRoutes)), ['/a/:id/go']);
    expect(patterns(match('/b/a/adskfjasjklf/another', testRoutes)),
        ['/b/a/:input/another']);
    expect(patterns(match('/b/a/adskf%2Fjasjklf/another', testRoutes)),
        ['/b/a/:input/another']);
    expect(patterns(match('/b/a/adskfjasj', testRoutes)), ['/b/a/:input']);
    expect(patterns(match('/d/yep', testRoutes)), ['/[a-z]/yep']);
    expect(patterns(match('/b/B/yep', testRoutes)), ['/b/B/:input']);
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
      patternRoute,
      intRoute,
      uintRoute,
      doubleRoute,
      dateRoute,
      tsRoute,
      uuidRoute,
      alphaRoute,
      hexRoute,
      genericRoute
    ];

    expect(routes(match('/xxx/123/test', testRoutes)), [
      patternRoute,
      intRoute,
      uintRoute,
      doubleRoute,
      tsRoute,
      alphaRoute,
      hexRoute,
      genericRoute
    ]);
    expect(routes(match('/xxx/%3123/test', testRoutes)), // %31 is character "1"
        [
          patternRoute,
          intRoute,
          uintRoute,
          doubleRoute,
          tsRoute,
          alphaRoute,
          hexRoute,
          genericRoute
        ]);
    expect(routes(match('/xxx/-123/test', testRoutes)),
        [intRoute, doubleRoute, tsRoute, genericRoute]);
    expect(routes(match('/xxx/123.4/test', testRoutes)),
        [doubleRoute, genericRoute]);
    expect(routes(match('/xxx/-123.4/test', testRoutes)),
        [doubleRoute, genericRoute]);
    expect(routes(match('/xxx/2021/08/23/test', testRoutes)), [dateRoute]);
    expect(routes(match('/xxx/-52/08/23/test', testRoutes)), [dateRoute]);
    expect(
        routes(match(
            '/xxx/01234567-0123-4567-89ab-cdef01234567/test', testRoutes)),
        [uuidRoute, genericRoute]);
    expect(routes(match('/xxx/cafe/test', testRoutes)),
        [alphaRoute, hexRoute, genericRoute]);
    expect(routes(match('/xxx/CAFE/test', testRoutes)),
        [alphaRoute, hexRoute, genericRoute]);
    expect(
        routes(match('/xxx/c%61fe/test', testRoutes)), // %61 is character "a"
        [alphaRoute, hexRoute, genericRoute]);
    expect(routes(match('/xxx/Name/test', testRoutes)),
        [alphaRoute, genericRoute]);
    expect(
        routes(match('/xxx/N%61me/test', testRoutes)), // %61 is character "a"
        [alphaRoute, genericRoute]);
    expect(routes(match('/xxx/Some%20text/test', testRoutes)), [genericRoute]);
  });

  test('it should match routes correctly - custom typed parameters', () {
    final frZip = FrenchPostalCodeTypeParameter();
    final frPhone = FrenchPhoneNumberTypeParameter();
    final recentDate = RecentDateTypeParameter();
    final refNumber = RefNumberTypeParameter();

    HttpRouteParam.paramTypes.add(frZip);
    HttpRouteParam.paramTypes.add(frPhone);
    HttpRouteParam.paramTypes.add(recentDate);
    HttpRouteParam.paramTypes.add(refNumber);
    try {
      final intRoute = httpTestRoute(r'/xxx/:number:int');
      final doubleRoute = httpTestRoute(r'/xxx/:number:double');
      final frenchZipRoute = httpTestRoute(r'/xxx/:zip:zip-fr');
      final frenchPhoneRoute = httpTestRoute(r'/xxx/:phone:phone-fr');
      final altDateRoute = httpTestRoute(r'/xxx/:date:recent');
      final refNumberRoute = httpTestRoute(r'/xxx/:ref:ref');

      final testRoutes = [
        intRoute,
        doubleRoute,
        frenchZipRoute,
        frenchPhoneRoute,
        altDateRoute,
        refNumberRoute
      ];

      expect(routes(match('/xxx/abc', testRoutes)), isEmpty);
      expect(routes(match('/xxx/123', testRoutes)), [intRoute, doubleRoute]);
      expect(routes(match('/xxx/123.456', testRoutes)), [doubleRoute]);
      expect(routes(match('/xxx/01.02.03', testRoutes)), isEmpty);
      expect(routes(match('/xxx/9-11-89', testRoutes)), isEmpty);
      expect(routes(match('/xxx/14-7-1789', testRoutes)), isEmpty);
      expect(routes(match('/xxx/abc%2F123', testRoutes)), isEmpty);
      expect(routes(match('/xxx/ab%2F1234', testRoutes)), isEmpty);

      expect(routes(match('/xxx/75001', testRoutes)),
          [intRoute, doubleRoute, frenchZipRoute]);
      expect(
          routes(match('/xxx/01.02.03.04.05', testRoutes)), [frenchPhoneRoute]);
      expect(
          routes(match('/xxx/01.02.03.04.05', testRoutes)), [frenchPhoneRoute]);
      expect(routes(match('/xxx/9-11-1989', testRoutes)), [altDateRoute]);
      expect(routes(match('/xxx/ab%2F123', testRoutes)), [refNumberRoute]);
    } finally {
      HttpRouteParam.paramTypes.remove(refNumber);
      HttpRouteParam.paramTypes.remove(recentDate);
      HttpRouteParam.paramTypes.remove(frPhone);
      HttpRouteParam.paramTypes.remove(frZip);
    }
  });

  test('it should match wildcards', () {
    final testRoutes = [
      httpTestRoute('*'),
      httpTestRoute('/a'),
      httpTestRoute('/b'),
    ];

    expect(patterns(match('/a', testRoutes)), ['*', '/a']);
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
    expect(patterns(match('/some/pathological', testRoutes)), ['/some/path*']);
  });

  test('it should respect the route method', () {
    final testRoutes = [
      httpTestRoute('*', Method.post),
      httpTestRoute('/a', Method.get),
      httpTestRoute('/b', Method.get),
    ];

    expect(patterns(match('/a', testRoutes)), ['/a']);
  });

  test('it should extract the route params correctly', () {
    final paramRoute = httpTestRoute('/xxx/:value/:value2');

    var matches =
        match('/xxx/input/%31%20Item%20inventory%20summary', [paramRoute]);
    expect(routes(matches), [paramRoute]);
    expect(params(matches), [
      {'value': 'input', 'value2': '1 Item inventory summary'}
    ]);

    matches = match(
        '/xxx/input/%31%20%2F%20Item%20inventory%20summary', [paramRoute]);
    expect(routes(matches), [paramRoute]);
    expect(params(matches), [
      {'value': 'input', 'value2': '1 / Item inventory summary'}
    ]);
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
      dateRoute,
      intRoute,
      uintRoute,
      uuidRoute,
      doubleRoute,
      tsRoute,
      alphaRoute,
      hexRoute
    ];

    var matches = match('/xxx/2021/02/32', testRoutes);
    expect(routes(matches), isEmpty);
    expect(params(matches), isEmpty);

    matches = match('/xxx/2021/13/01', testRoutes);
    expect(routes(matches), isEmpty);
    expect(params(matches), isEmpty);

    matches = match('/xxx/2021/08/23', testRoutes);
    expect(routes(matches), [dateRoute]);
    expect(params(matches), [
      {'value': DateTime.utc(2021, DateTime.august, 23)}
    ]);

    matches = match('/xxx/2021/02/31', testRoutes);
    expect(routes(matches), [dateRoute]);
    expect(params(matches), [
      {'value': DateTime.utc(2021, DateTime.march, 3)}
    ]);

    matches = match('/xxx/-52/09/11', testRoutes);
    expect(routes(matches), [dateRoute]);
    expect(params(matches), [
      {'value': DateTime.utc(-52, DateTime.september, 11)}
    ]);

    matches = match('/xxx/%312345', testRoutes);
    expect(routes(matches),
        [intRoute, uintRoute, doubleRoute, tsRoute, alphaRoute, hexRoute]);
    expect(params(matches), [
      {'value': 12345},
      {'value': 12345},
      {'value': 12345.0},
      {'value': DateTime.fromMillisecondsSinceEpoch(12345)},
      {'value': '12345'},
      {'value': '12345'},
    ]);

    matches = match('/xxx/12345', testRoutes);
    expect(routes(matches),
        [intRoute, uintRoute, doubleRoute, tsRoute, alphaRoute, hexRoute]);
    expect(params(matches), [
      {'value': 12345},
      {'value': 12345},
      {'value': 12345.0},
      {'value': DateTime.fromMillisecondsSinceEpoch(12345)},
      {'value': '12345'},
      {'value': '12345'},
    ]);

    matches = match('/xxx/-12345', testRoutes);
    expect(routes(matches), [intRoute, doubleRoute, tsRoute]);
    expect(params(matches), [
      {'value': -12345},
      {'value': -12345.0},
      {'value': DateTime.fromMillisecondsSinceEpoch(-12345)}
    ]);

    matches = match('/xxx/12345.34', testRoutes);
    expect(routes(matches), [doubleRoute]);
    expect(params(matches), [
      {'value': 12345.34}
    ]);

    matches = match('/xxx/-12345.34', testRoutes);
    expect(routes(matches), [doubleRoute]);
    expect(params(matches), [
      {'value': -12345.34}
    ]);

    matches = match('/xxx/01234567-89ab-cdef-0123-456789abcdef', testRoutes);
    expect(routes(matches), [uuidRoute]);
    expect(params(matches), [
      {'value': '01234567-89ab-cdef-0123-456789abcdef'}
    ]);

    matches = match('/xxx/cafe', testRoutes);
    expect(routes(matches), [alphaRoute, hexRoute]);
    expect(params(matches), [
      {'value': 'cafe'},
      {'value': 'cafe'}
    ]);

    matches = match('/xxx/text', testRoutes);
    expect(routes(matches), [alphaRoute]);
    expect(params(matches), [
      {'value': 'text'}
    ]);
  });

  test('it should extract the route params correctly - custom typed parameters',
      () {
    final frZip = FrenchPostalCodeTypeParameter();
    final frPhone = FrenchPhoneNumberTypeParameter();
    final recentDate = RecentDateTypeParameter();
    final refNumber = RefNumberTypeParameter();

    HttpRouteParam.paramTypes.add(frZip);
    HttpRouteParam.paramTypes.add(frPhone);
    HttpRouteParam.paramTypes.add(recentDate);
    HttpRouteParam.paramTypes.add(refNumber);
    try {
      final intRoute = httpTestRoute(r'/xxx/:number:int');
      final doubleRoute = httpTestRoute(r'/xxx/:number:double');
      final frenchZipRoute = httpTestRoute(r'/xxx/:zip:zip-fr');
      final frenchPhoneRoute = httpTestRoute(r'/xxx/:phone:phone-fr');
      final altDateRoute = httpTestRoute(r'/xxx/:date:recent');
      final refNumberRoute = httpTestRoute(r'/xxx/:ref:ref');

      final testRoutes = [
        intRoute,
        doubleRoute,
        frenchZipRoute,
        frenchPhoneRoute,
        altDateRoute,
        refNumberRoute
      ];

      var matches = match('/xxx/abc', testRoutes);
      expect(routes(matches), isEmpty);
      expect(params(matches), isEmpty);

      matches = match('/xxx/123', testRoutes);
      expect(routes(matches), [intRoute, doubleRoute]);
      expect(params(matches), [
        {'number': 123},
        {'number': 123.0}
      ]);

      matches = match('/xxx/123.456', testRoutes);
      expect(routes(matches), [doubleRoute]);
      expect(params(matches), [
        {'number': 123.456}
      ]);

      matches = match('/xxx/01.02.03', testRoutes);
      expect(routes(matches), isEmpty);
      expect(params(matches), isEmpty);

      matches = match('/xxx/9-11-89', testRoutes);
      expect(routes(matches), isEmpty);
      expect(params(matches), isEmpty);

      matches = match('/xxx/14-7-1789', testRoutes);
      expect(routes(matches), isEmpty);
      expect(params(matches), isEmpty);

      matches = match('/xxx/abc%2F123', testRoutes);
      expect(routes(matches), isEmpty);
      expect(params(matches), isEmpty);

      matches = match('/xxx/ab%2F1234', testRoutes);
      expect(routes(matches), isEmpty);
      expect(params(matches), isEmpty);

      matches = match('/xxx/75001', testRoutes);
      expect(routes(matches), [intRoute, doubleRoute, frenchZipRoute]);
      expect(params(matches), [
        {'number': 75001},
        {'number': 75001.0},
        {'zip': 75001}
      ]);

      matches = match('/xxx/01.02.03.04.05', testRoutes);
      expect(routes(matches), [frenchPhoneRoute]);
      expect(params(matches), [
        {'phone': '01.02.03.04.05'}
      ]);

      matches = match('/xxx/9-11-1989', testRoutes);
      expect(routes(matches), [altDateRoute]);
      expect(params(matches), [
        {'date': DateTime(1989, 11, 9)}
      ]);

      matches = match('/xxx/ab%2F123', testRoutes);
      expect(routes(matches), [refNumberRoute]);
      expect(params(matches), [
        {'ref': 'AB/123'}
      ]);
    } finally {
      HttpRouteParam.paramTypes.remove(recentDate);
      HttpRouteParam.paramTypes.remove(frPhone);
      HttpRouteParam.paramTypes.remove(frZip);
    }
  });

  test('it should correctly match routes that have a partial match', () {
    final testRoutes = [httpTestRoute('/image'), httpTestRoute('/imageSource')];

    expect(patterns(match('/imagesource', testRoutes)), ['/imageSource']);
  });

  test('it should ignore a trailing slash', () {
    final testRoute = httpTestRoute('/b/');

    expect(routes(match('/b?qs=true', [testRoute])), [testRoute]);
  });

  test('it should ignore a trailing slash in reverse', () {
    final testRoute = httpTestRoute('/b');

    expect(routes(match('/b/?qs=true', [testRoute])), [testRoute]);
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

    expect(patterns(match('/route', testRoutes)), ['/route*', '/route']);

    expect(
        patterns(match('/route/test', testRoutes)), ['/route*', '/route/test']);
  });

  test('it should match wildcards in the middle', () {
    final testRoutes = [
      httpTestRoute('/a/*/b'),
      httpTestRoute('/a/*/*/b'),
    ];

    expect(match('/a', testRoutes), isEmpty);
    expect(patterns(match('/a/x/b', testRoutes)), ['/a/*/b']);
    expect(patterns(match('/a/x/y/b', testRoutes)), ['/a/*/b', '/a/*/*/b']);
  });

  test('it should match wildcards at the beginning', () {
    final jpgRoute = httpTestRoute('*.jpg');

    final testRoutes = [jpgRoute];

    expect(match('xjpg', testRoutes), isEmpty);
    expect(routes(match('.jpg', testRoutes)), [jpgRoute]);
    expect(routes(match('path/to/picture.jpg', testRoutes)), [jpgRoute]);
  });

  test('it should match regex expressions within segments', () {
    final testRoutes = [
      httpTestRoute('[a-z]+/[0-9]+'),
      httpTestRoute('[a-z]{5}'),
      httpTestRoute('(a|b)/c'),
    ];

    expect(match('a/b', testRoutes), isEmpty);
    expect(match('3/a', testRoutes), isEmpty);
    expect(match('abc', testRoutes), isEmpty);
    expect(match('abc42', testRoutes), isEmpty);
    expect(patterns(match('x/323', testRoutes)), ['[a-z]+/[0-9]+']);
    expect(patterns(match('answer/42', testRoutes)), ['[a-z]+/[0-9]+']);
    expect(patterns(match('abcde', testRoutes)), ['[a-z]{5}']);
    expect(patterns(match('final', testRoutes)), ['[a-z]{5}']);
    expect(patterns(match('a/c', testRoutes)), ['(a|b)/c']);
    expect(patterns(match('b/c', testRoutes)), ['(a|b)/c']);
  });
}

HttpRoute httpTestRoute(String route, [Method method = Method.get]) =>
    HttpRoute(route, _callback, method);

List<HttpRouteMatch> match(String input, List<HttpRoute> routes) =>
    RouteMatcher.match(input, routes, Method.get).toList();

List<HttpRoute> routes(Iterable<HttpRouteMatch> matches) =>
    matches.map((e) => e.route).toList();

List<String> patterns(Iterable<HttpRouteMatch> matches) =>
    matches.map((e) => e.route.route).toList();

List<Map<String, dynamic>> params(Iterable<HttpRouteMatch> matches) =>
    matches.map((e) => e.params).toList();

Future Function(HttpRequest, HttpResponse) get _callback => (req, res) async {};

class FrenchPostalCodeTypeParameter implements HttpRouteParamType {
  @override
  final String name = 'zip-fr';

  @override
  final String pattern = r'\d{5}';

  @override
  int parse(String value) {
    return int.parse(value);
  }
}

class FrenchPhoneNumberTypeParameter implements HttpRouteParamType {
  @override
  final String name = 'phone-fr';

  @override
  final String pattern = r'\d{2}\.\d{2}\.\d{2}\.\d{2}\.\d{2}';

  @override
  String parse(String value) {
    return value;
  }
}

class RecentDateTypeParameter implements HttpRouteParamType {
  @override
  final String name = 'recent';

  @override
  final String pattern = r'\d{1,2}-\d{1,2}-(?:19|20)\d{2}';

  @override
  DateTime parse(String value) {
    // day-month-year
    final parts = value.split('-');
    return DateTime(
        int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
  }
}

class RefNumberTypeParameter implements HttpRouteParamType {
  @override
  final String name = 'ref';

  // to match a value containing a / in a single segment,
  // / must be URI-encoded (= %2F) in the reg exp
  @override
  final String pattern = r'[a-z]{2}%2F\d{3}';

  @override
  String parse(String value) {
    return value.toUpperCase();
  }
}
