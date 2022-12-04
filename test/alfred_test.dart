import 'dart:convert';
import 'dart:io';

import 'package:alfred/alfred.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'common.dart';

void main() {
  late Alfred app;
  late int port;

  setUp(() async {
    app = Alfred();
    port = await app.listenForTest();
  });

  tearDown(() => app.close());

  test('it should return a string correctly', () async {
    app.get('/test', (req, res) => 'test string');
    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.body, 'test string');
  });

  test('it should return json', () async {
    app.get('/test', (req, res) => {'test': true});
    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.headers['content-type'], 'application/json; charset=utf-8');
    expect(response.body, '{"test":true}');
  });

  test('it should return an image', () async {
    app.get('/test', (req, res) => File('test/files/image.jpg'));
    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.headers['content-type'], 'image/jpeg');
  });

  test('it should return a pdf', () async {
    app.get('/test', (req, res) => File('test/files/dummy.pdf'));
    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.headers['content-type'], 'application/pdf');
  });

  test('routing should, you know, work', () async {
    app.get('/test', (req, res) => 'test_route');
    app.get('/testRoute', (req, res) => 'test_route_route');
    app.get('/a', (req, res) => 'a_route');
    expect((await http.get(Uri.parse('http://localhost:$port/test'))).body,
        'test_route');
    expect((await http.get(Uri.parse('http://localhost:$port/testRoute'))).body,
        'test_route_route');
    expect((await http.get(Uri.parse('http://localhost:$port/a'))).body,
        'a_route');
  });

  test('error handling', () async {
    await app.close();
    app = Alfred(onInternalError: (req, res) {
      res.statusCode = 500;
      return {'message': 'error not handled'};
    });
    await app.listen(port);
    app.get('/throwserror', (req, res) => throw Exception('generic exception'));

    expect(
        (await http.get(Uri.parse('http://localhost:$port/throwserror'))).body,
        '{"message":"error not handled"}');
  });

  test('error default handling', () async {
    await app.close();
    app = Alfred();
    await app.listen(port);
    app.get('/throwserror', (req, res) => throw Exception('generic exception'));

    final response =
        await http.get(Uri.parse('http://localhost:$port/throwserror'));
    expect(response.body, 'Exception: generic exception');
  });

  test('not found handling', () async {
    await app.close();
    app = Alfred(onNotFound: (req, res) {
      res.statusCode = 404;
      return {'message': 'not found'};
    });
    await app.listen(port);

    final response =
        (await http.get(Uri.parse('http://localhost:$port/notfound')));
    expect(response.body, '{"message":"not found"}');
    expect(response.statusCode, 404);
  });

  test('not found default handling', () async {
    await app.close();
    app = Alfred();
    await app.listen(port);

    final response =
        (await http.get(Uri.parse('http://localhost:$port/notfound')));
    expect(response.body, '404 not found');
    expect(response.statusCode, 404);
  });

  test('Invalid ssl chain & key - file', () async {
    await app.close();
    app = Alfred();

    try {
      var context = SecurityContext();
      context.useCertificateChain('');
      context.usePrivateKey('');

      await app.listenSecure(
        port: port,
        securityContext: context,
      );
      fail('Was not for this server to have started.');
    } catch (e) {
      expect(
        e.toString(),
        contains('FileSystemException: Cannot open file, path'),
      );
    }
  });

  test('Invalid ssl chain & key - bytes', () async {
    await app.close();
    app = Alfred();

    try {
      var context = SecurityContext();
      context.useCertificateChainBytes([]);
      context.usePrivateKeyBytes([]);

      await app.listenSecure(
        port: port,
        securityContext: context,
      );
      fail('Was not for this server to have started.');
    } catch (e) {
      expect(
        e.toString(),
        contains('TlsException: Failure in useCertificateChainBytes'),
      );
    }
  });

  test('not found with middleware', () async {
    app.all('*', cors());
    app.get('resource2', (req, res) {});

    final r1 = await http.get(Uri.parse('http://localhost:$port/resource1'));
    expect(r1.body, '404 not found');
    expect(r1.statusCode, 404);

    final r2 = await http.get(Uri.parse('http://localhost:$port/resource2'));
    expect(r2.body, '');
    expect(r2.statusCode, 200);
  });

  test('not found with directory type handler', () async {
    app.get('/files/*', (req, res) => Directory('test/files'));

    final r =
        await http.get(Uri.parse('http://localhost:$port/files/no-file.zip'));
    expect(r.body, '404 not found');
    expect(r.statusCode, 404);
  });

  test('not found with file type handler', () async {
    app.onNotFound = (req, res) {
      res.statusCode = HttpStatus.notFound;
      return 'Custom404Message';
    };
    app.get('/index.html', (req, res) => File('does-not.exists'));

    final r = await http.get(Uri.parse('http://localhost:$port/index.html'));
    expect(r.body, 'Custom404Message');
    expect(r.statusCode, 404);
  });

  test('it handles a post request', () async {
    app.post('/test', (req, res) => 'test string');
    final response = await http.post(Uri.parse('http://localhost:$port/test'));
    expect(response.body, 'test string');
  });

  test('it handles a put request', () async {
    app.put('/test', (req, res) => 'test string');
    final response = await http.put(Uri.parse('http://localhost:$port/test'));
    expect(response.body, 'test string');
  });

  test('it handles a delete request', () async {
    app.delete('/test', (req, res) => 'test string');
    final response =
        await http.delete(Uri.parse('http://localhost:$port/test'));
    expect(response.body, 'test string');
  });

  test('it handles an options request', () async {
    app.options('/test', (req, res) => 'test string');

    /// TODO: Need to find a way to send an options request. The HTTP library doesn't
    /// seem to support it.
    ///
    // final response = await http.options(Uri.parse('http://localhost:$port/test'));
    // expect(response.body, 'test string');
  });

  test('it handles a HEAD request', () async {
    app.head('/test', (req, res) => 'test string');
    final response = await http.head(Uri.parse('http://localhost:$port/test'));
    expect(response.body.isEmpty, true);
  });

  test('it handles a patch request', () async {
    app.patch('/test', (req, res) => 'test string');
    final response = await http.patch(Uri.parse('http://localhost:$port/test'));
    expect(response.body, 'test string');
  });

  test('it handles a route that hits all methods', () async {
    app.all('/test', (req, res) => 'test all');
    final responseGet =
        await http.get(Uri.parse('http://localhost:$port/test'));
    final responsePost =
        await http.post(Uri.parse('http://localhost:$port/test'));
    final responsePut =
        await http.put(Uri.parse('http://localhost:$port/test'));
    final responseDelete =
        await http.delete(Uri.parse('http://localhost:$port/test'));
    expect(responseGet.body, 'test all');
    expect(responsePost.body, 'test all');
    expect(responsePut.body, 'test all');
    expect(responseDelete.body, 'test all');
  });

  test('it executes middleware, but passes through', () async {
    var hitMiddleware = false;
    app.get('/test', (req, res) => 'test route', middleware: [
      (req, res) {
        hitMiddleware = true;
      }
    ]);
    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.body, 'test route');
    expect(hitMiddleware, true);
  });

  test('it executes middleware, but handles it and stops executing', () async {
    app.get('/test', (req, res) => 'test route', middleware: [
      (req, res) {
        return 'hit middleware';
      }
    ]);
    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.body, 'hit middleware');
  });

  test('it closes out a request if you fail to', () async {
    app.get('/test', (req, res) => null);
    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.body, '');
  });

  test('it throws and handles an exception', () async {
    app.get('/test', (req, res) => throw AlfredException(360, 'exception'));
    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.body, 'exception');
    expect(response.statusCode, 360);
  });

  test('it handles a List<int>', () async {
    app.get('/test', (req, res) => <int>[1, 2, 3, 4, 5]);
    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.body, '\x01\x02\x03\x04\x05');
    expect(response.headers['content-type'], 'application/octet-stream');
  });

  test('it handles a Stream<List<int>>', () async {
    app.get(
        '/test',
        (req, res) => Stream.fromIterable([
              [1, 2, 3, 4, 5]
            ]));
    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.body, '\x01\x02\x03\x04\x05');
    expect(response.headers['content-type'], 'application/octet-stream');
  });

  test('it parses a body', () async {
    app.post('/test', (req, res) async {
      final body = await req.body;
      expect(body is Map, true);
      expect(req.contentType!.mimeType, 'application/json');
      return 'test result';
    });

    final response = await http.post(Uri.parse('http://localhost:$port/test'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'test': true}));
    expect(response.body, 'test result');
  });

  test('it serves a file for download', () async {
    app.get('/test', (req, res) {
      res.setDownload(filename: 'testfile.jpg');
      return File('./test/files/image.jpg');
    });

    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.headers['content-type'], 'image/jpeg');
    expect(response.headers['content-disposition'],
        'attachment; filename=testfile.jpg');
  });

  test('it serves a pdf, setting the extension from the filename', () async {
    app.get('/test', (req, res) {
      res.setContentTypeFromExtension('pdf');
      return File('./test/files/dummy.pdf');
    });

    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.headers['content-type'], 'application/pdf');
    expect(response.headers['content-disposition'], null);
  });

  test('it uses the json helper correctly', () async {
    app.get('/test', (req, res) async {
      await res.json({'success': true});
    });
    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.body, '{"success":true}');
  });

  test('it uses the send helper correctly', () async {
    app.get('/test', (req, res) async {
      await res.send('stuff');
    });
    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.body, 'stuff');
  });

  test('it serves static files', () async {
    app.get('/files/*', (req, res) => Directory('test/files'));

    final response =
        await http.get(Uri.parse('http://localhost:$port/files/dummy.pdf'));
    expect(response.statusCode, 200);
    expect(response.headers['content-type'], 'application/pdf');
  });

  test('it serves static files with a trailing slash', () async {
    app.get('/files/*', (req, res) => Directory('test/files/'));

    final response =
        await http.get(Uri.parse('http://localhost:$port/files/dummy.pdf'));
    expect(response.statusCode, 200);
    expect(response.headers['content-type'], 'application/pdf');
  });

  test('it serves static files although directories do not match', () async {
    app.get('/my/directory/*', (req, res) => Directory('test/files'));

    final response = await http
        .get(Uri.parse('http://localhost:$port/my/directory/dummy.pdf'));
    expect(response.statusCode, 200);
    expect(response.headers['content-type'], 'application/pdf');
  });

  test('it cant exit the directory', () async {
    app.get('/my/directory/*', (req, res) => Directory('test/files'));

    final response = await http.get(
        Uri.parse('http://localhost:$port/my/directory/../alfred_test.dart'));
    expect(response.statusCode, 404);
  });

  test('it serves static files with basic filtering', () async {
    app.get('/my/directory/*.pdf', (req, res) => Directory('test/files'));

    final r1 = await http
        .get(Uri.parse('http://localhost:$port/my/directory/dummy.pdf'));
    expect(r1.statusCode, 200);
    expect(r1.headers['content-type'], 'application/pdf');

    final r2 = await http
        .get(Uri.parse('http://localhost:$port/my/directory/image.jpg'));
    expect(r2.statusCode, 404);
  });

  test('it sets the mime type correctly for txt', () async {
    app.get('/spa/*', (req, res) => Directory('test/files/spa'));
    app.get('/spa/*', (req, res) => File('test/files/spa/index.html'));

    final r4 =
        await http.get(Uri.parse('http://localhost:$port/spa/assets/some.txt'));
    expect(r4.statusCode, 200);
    expect(r4.body.contains('This is some txt'), true);
    expect(r4.headers['content-type'], 'text/plain');
  });

  test('it sets the mime type correctly for pdf', () async {
    app.get('/spa/*', (req, res) => Directory('test/files/spa'));
    app.get('/spa/*', (req, res) => File('test/files/spa/index.html'));

    final r4 = await http
        .get(Uri.parse('http://localhost:$port/spa/assets/dummy.pdf'));
    expect(r4.statusCode, 200);
    expect(r4.headers['content-type'], 'application/pdf');
  });

  test('it serves SPA projects', () async {
    app.get('/spa/*', (req, res) => Directory('test/files/spa'));
    app.get('/spa/*', (req, res) => File('test/files/spa/index.html'));

    final r1 = await http.get(Uri.parse('http://localhost:$port/spa'));
    expect(r1.statusCode, 200);
    expect(r1.headers['content-type'], 'text/html');
    expect(r1.body.contains('I am a SPA Application'), true);

    final r2 = await http.get(Uri.parse('http://localhost:$port/spa/'));
    expect(r2.statusCode, 200);
    expect(r2.headers['content-type'], 'text/html');
    expect(r2.body.contains('I am a SPA Application'), true);

    final r3 =
        await http.get(Uri.parse('http://localhost:$port/spa/index.html'));
    expect(r3.statusCode, 200);
    expect(r3.headers['content-type'], 'text/html');
    expect(r3.body.contains('I am a SPA Application'), true);

    final r4 =
        await http.get(Uri.parse('http://localhost:$port/spa/assets/some.txt'));
    expect(r4.statusCode, 200);
    expect(r4.headers['content-type'], 'text/plain');
    expect(r4.body.contains('This is some txt'), true);
  });

  test('it does not crash when File not exists', () async {
    app.get('error', (req, res) => File('does-not-exists'));
    app.get('works', (req, res) => 'works!');

    await http.get(Uri.parse('http://localhost:$port/error'));
    final request = await http.get(Uri.parse('http://localhost:$port/works'));
    expect(request.statusCode, 200);
  });

  test('it routes correctly for a / url', () async {
    app.get('/', (req, res) => 'working');
    final response = await http.get(Uri.parse('http://localhost:$port/'));

    expect(response.body, 'working');
  });

  test('it handles params', () async {
    app.get('/test/:id', (req, res) => req.params['id']);
    final response =
        await http.get(Uri.parse('http://localhost:$port/test/15'));
    expect(response.body, '15');
  });

  test('it handles params on the root', () async {
    app.get('/:id', (req, res) => req.params['id']);
    final response = await http.get(Uri.parse('http://localhost:$port/15'));
    expect(response.body, '15');
  });

  test('it handles typed params', () async {
    app.get('/blog/:year:int',
        (req, res) => 'Blog Entries for year ${req.params['year']}');
    app.get('/blog/:date:date',
        (req, res) => 'Blog Entries for ${req.params['date']}');
    app.get(
        '/blog/:date:date/:id:uint/:title:.*',
        (req, res) =>
            'Blog Entry #${req.params['id']} - ${req.params['date']} - ${req.params['title']}');
    var response = await http.get(
        Uri.parse('http://localhost:$port/blog/2021/03/27/1/Initial%20Commit'));
    expect(response.body,
        'Blog Entry #1 - ${DateTime.utc(2021, 3, 27)} - Initial Commit');
    response = await http.get(Uri.parse(
        'http://localhost:$port/blog/2021/08/20/59/Merged%20commit%20c391fcc'));
    expect(response.body,
        'Blog Entry #59 - ${DateTime.utc(2021, 8, 20)} - Merged commit c391fcc');
    response = await http.get(Uri.parse('http://localhost:$port/blog/2021'));
    expect(response.body, 'Blog Entries for year 2021');
    response =
        await http.get(Uri.parse('http://localhost:$port/blog/2021/08/20'));
    expect(response.body, 'Blog Entries for ${DateTime.utc(2021, 8, 20)}');
  });

  test('it handles custom typed params', () async {
    final recentDate = RecentDateTypeParameter();
    final refNumber = RefNumberTypeParameter();

    HttpRouteParam.paramTypes.add(recentDate);
    HttpRouteParam.paramTypes.add(refNumber);
    try {
      app.get('/catalog/:ref:ref',
          (req, res) => 'Catalog Item ${req.params['ref']}');
      app.get('/history/:date:recent/:event:.*',
          (req, res) => '${req.params['date']}: ${req.params['event']}');

      var response =
          await http.get(Uri.parse('http://localhost:$port/catalog/ab%2F123'));
      expect(response.body, 'Catalog Item AB/123');
      response =
          await http.get(Uri.parse('http://localhost:$port/catalog/ab/123'));
      expect(response.statusCode, 404);

      response = await http.get(Uri.parse(
          'http://localhost:$port/history/9-11-1989/Fall%20of%20the%20Berlin%20Wall'));
      expect(
          response.body, '${DateTime(1989, 11, 9)}: Fall of the Berlin Wall');
      response = await http.get(
          Uri.parse('http://localhost:$port/history/14-7-1789/Bastille%20Day'));
      expect(response.statusCode, 404);
    } finally {
      HttpRouteParam.paramTypes.remove(refNumber);
      HttpRouteParam.paramTypes.remove(recentDate);
    }
  });

  test('it handles params in routes with wildcards', () async {
    app.get('/test/*/:id', (req, res) => req.params['id']);
    var response =
        await http.get(Uri.parse('http://localhost:$port/test/onelevel/15'));
    expect(response.body, '15');
    response =
        await http.get(Uri.parse('http://localhost:$port/test/two/levels/15'));
    expect(response.body, '15');
  });

  test('it should implement cors correctly', () async {
    app.all('*', cors(origin: 'test-origin'));

    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.headers.containsKey('access-control-allow-origin'), true);
    expect(response.headers['access-control-allow-origin'], 'test-origin');
    expect(response.headers.containsKey('access-control-allow-headers'), true);
    expect(response.headers.containsKey('access-control-allow-methods'), true);
  });

  test("it should throw an appropriate error when a return type isn't found",
      () async {
    app.get('/test', (req, res) => _UnknownType());
    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.statusCode, 500);
    expect(response.body.contains('_UnknownType'), true);
  });

  test('it should log out request information', () async {
    app.get('/resource', (req, res) => 'response', middleware: [cors()]);
    var logs = <String>[];
    app.logWriter = (msgFn, type) => logs.add('$type ${msgFn()}');
    await http.get(Uri.parse('http://localhost:$port/resource'));

    bool inLog(String part) =>
        logs.isNotEmpty && logs.where((log) => log.contains(part)).isNotEmpty;

    expect(inLog('info GET - /resource'), true);
    expect(inLog('debug Match route: /resource'), true);
    expect(inLog('debug Apply middleware'), true);
    expect(inLog('debug Apply TypeHandler for result type: String'), true);
    expect(inLog('debug Response sent to client'), true);
  });

  test('it prints the routes without error', () {
    app.get('/test', (req, res) => 'response');
    app.post('/test', (req, res) => 'response');
    app.put('/test', (req, res) => 'response');
    app.delete('/test', (req, res) => 'response');
    app.options('/test', (req, res) => 'response');
    app.all('/test', (req, res) => 'response');
    app.head('/test', (req, res) => 'response');
    app.printRoutes();
  });

  test('it handles cyrillic bodies', () async {
    app.post('/ctr', (req, res) async {
      // complex tender request
      await req.body;
      // print(req.contentType); //application/json; charset=utf-8
      // print('data: $data'); //data: {selected_region: [Республика Адыгея]}
      // print(data.runtimeType); //_InternalLinkedHashMap<String, dynamic>
      await res.json({'data': 'ok'});
    });

    await http.post(Uri.parse('http://localhost:$port/ctr'),
        body: '{"selected_region": ["Республика Адыгея"]}',
        headers: {'Content-Type': 'application/json'});
  });

  test('it doesnt overwrite content types', () async {
    app.get('/test', (req, res) {
      res.headers.contentType = ContentType.parse('application/javascript');
      return File('test/files/dummy.js');
    });
    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.headers['content-type'], 'application/javascript');
  });

  test('it can parse the body twice and not freak out', () async {
    app.post('/test', (req, res) async {
      await req.body;
    }, middleware: [
      (req, res) async {
        await req.body;
      }
    ]);
    final response = await http
        .post(Uri.parse('http://localhost:$port/test'), body: {'test': 'true'});
    expect(response.statusCode, 200);
  });

  test('it handles invalid json input', () async {
    app.post('/test', (req, res) async {
      await req.body;
    });
    final response = await http.post(Uri.parse('http://localhost:$port/test'),
        body: ' ', headers: {'Content-Type': 'application/json'});
    expect(response.statusCode, 400);
  });

  test(
      'it handles a failed body parser wrapped in a try catch block with an alfred exception',
      () async {
    app.post('/test', (req, res) async {
      try {
        await req.body;
      } catch (e) {
        throw AlfredException(500, {'test': 'response'});
      }
    });
    final response = await http.post(Uri.parse('http://localhost:$port/test'),
        body: '{ "email": "test@test.com",}',
        headers: {'Content-Type': 'application/json'});
    expect(response.statusCode, 400);
  });

  test(
      'it handles a failed body parser wrapped in a try catch block with a manual return (setting the header twice)',
      () async {
    app.post('/test', (req, res) async {
      try {
        await req.body;
      } catch (e) {
        res.statusCode = 500;
        return {'error': true};
      }
    });
    final response = await http.post(Uri.parse('http://localhost:$port/test'),
        body: '{ "email": "test@test.com",}',
        headers: {'Content-Type': 'application/json'});
    expect(response.statusCode, 400);
  });
}

class _UnknownType {}

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
