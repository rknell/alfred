// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:alfred/src/body_parser/http_body.dart';
import 'package:test/test.dart';

import 'http_fakes.dart';

void _testHttpClientResponseBody() {
  void check(
      String mimeType, List<int> content, dynamic expectedBody, String type,
      [bool shouldFail = false]) async {
    var server = await HttpServer.bind('localhost', 0);
    server.listen((request) {
      request.listen((_) {}, onDone: () {
        request.response.headers.contentType = ContentType.parse(mimeType);
        request.response.add(content);
        request.response.close();
      });
    });

    var client = HttpClient();
    try {
      var request = await client.get('localhost', server.port, '/');
      var response = await request.close();
      var body = await HttpBodyHandler.processResponse(response);
      expect(shouldFail, isFalse);
      expect(body.type, equals(type));
      expect(body.response, isNotNull);
      switch (type) {
        case 'text':
        case 'json':
          expect(body.body, equals(expectedBody));
          break;

        default:
          fail('bad body type');
      }
    } catch (_) {
      if (!shouldFail) rethrow;
    } finally {
      client.close();
      await server.close();
    }
  }

  check('text/plain', 'body'.codeUnits, 'body', 'text');
  check('text/plain; charset=utf-8', 'body'.codeUnits, 'body', 'text');
  check('text/plain; charset=iso-8859-1', 'body'.codeUnits, 'body', 'text');
  check('text/plain; charset=us-ascii', 'body'.codeUnits, 'body', 'text');
  check('text/plain; charset=utf-8', [42], '*', 'text');
  check('text/plain; charset=us-ascii', [142], null, 'text', true);
  check('text/plain; charset=utf-8', [142], null, 'text', true);

  check('application/json', '{"val": 5}'.codeUnits, {'val': 5}, 'json');
  check('application/json', '{ bad json }'.codeUnits, null, 'json', true);
}

void _testHttpServerRequestBody() {
  void check(
      String? mimeType, List<int> content, dynamic expectedBody, String type,
      {bool shouldFail = false, Encoding defaultEncoding = utf8}) async {
    var server = await HttpServer.bind('localhost', 0);
    server.transform(HttpBodyHandler(defaultEncoding: defaultEncoding)).listen(
        (body) {
      if (shouldFail) return;
      expect(shouldFail, isFalse);
      expect(body.type, equals(type));
      switch (type) {
        case 'text':
          expect(
              body.request.headers.contentType!.mimeType, equals('text/plain'));
          expect(body.body, equals(expectedBody));
          break;

        case 'json':
          expect(body.request.headers.contentType!.mimeType,
              equals('application/json'));
          expect(body.body, equals(expectedBody));
          break;

        case 'binary':
          expect(body.request.headers.contentType, isNull);
          expect(body.body, equals(expectedBody));
          break;

        case 'form':
          var mimeType = body.request.headers.contentType!.mimeType;
          expect(
              mimeType,
              anyOf(equals('multipart/form-data'),
                  equals('application/x-www-form-urlencoded')));
          expect(body.body.keys.toSet(), equals(expectedBody.keys.toSet()));
          for (var key in expectedBody.keys) {
            dynamic found = body.body[key];
            dynamic expected = expectedBody[key];
            if (found is HttpBodyFileUpload) {
              expect(found.contentType.toString(),
                  equals(expected['contentType']));
              expect(found.filename, equals(expected['filename']));
              expect(found.content, equals(expected['content']));
            } else {
              expect(found, equals(expected));
            }
          }
          break;

        default:
          throw StateError('bad body type');
      }
      body.request.response.close();
    }, onError: (Object error) {
      // ignore: only_throw_errors
      if (!shouldFail) throw error;
    });

    var client = HttpClient();
    try {
      var request = await client.post('localhost', server.port, '/');
      if (mimeType != null) {
        request.headers.contentType = ContentType.parse(mimeType);
      }
      request.add(content);
      var response = await request.close();
      if (shouldFail) {
        expect(response.statusCode, equals(HttpStatus.badRequest));
      }
      return response.drain();
    } catch (_) {
      if (!shouldFail) rethrow;
    } finally {
      client.close();
      await server.close();
    }
  }

  check('text/plain', 'body'.codeUnits, 'body', 'text');
  check('text/plain; charset=utf-8', 'body'.codeUnits, 'body', 'text');
  check('text/plain; charset=utf-8', [42], '*', 'text');
  check('text/plain; charset=us-ascii', [142], null, 'text', shouldFail: true);
  check('text/plain; charset=utf-8', [142], null, 'text', shouldFail: true);

  check('application/json', '{"val": 5}'.codeUnits, {'val': 5}, 'json');
  check('application/json', '{ bad json }'.codeUnits, null, 'json',
      shouldFail: true);

  check(null, 'body'.codeUnits, 'body'.codeUnits, 'binary');

  check(
      'multipart/form-data; boundary=AaB03x',
      '''
--AaB03x\r
Content-Disposition: form-data; name="name"\r
\r
Larry\r
--AaB03x--\r\n'''
          .codeUnits,
      {'name': 'Larry'},
      'form');

  check(
      'multipart/form-data; boundary=AaB03x',
      '''
--AaB03x\r
Content-Disposition: form-data; name="files"; filename="myfile"\r
Content-Type: application/octet-stream\r
\r
File content\r
--AaB03x--\r\n'''
          .codeUnits,
      {
        'files': {
          'filename': 'myfile',
          'contentType': 'application/octet-stream',
          'content': 'File content'.codeUnits
        }
      },
      'form');

  check(
      'multipart/form-data; boundary=AaB03x',
      '''
--AaB03x\r
Content-Disposition: form-data; name="files"; filename="myfile"\r
Content-Type: application/octet-stream\r
\r
File content\r
--AaB03x\r
Content-Disposition: form-data; name="files"; filename="myfile"\r
Content-Type: text/plain\r
\r
File content\r
--AaB03x--\r\n'''
          .codeUnits,
      {
        'files': {
          'filename': 'myfile',
          'contentType': 'text/plain',
          'content': 'File content'
        }
      },
      'form');

  check(
      'multipart/form-data; boundary=AaB03x',
      '''
--AaB03x\r
Content-Disposition: form-data; name="files"; filename="myfile"\r
Content-Type: application/json\r
\r
File content\r
--AaB03x--\r\n'''
          .codeUnits,
      {
        'files': {
          'filename': 'myfile',
          'contentType': 'application/json',
          'content': 'File content'
        }
      },
      'form');

  check(
      'application/x-www-form-urlencoded',
      '%E5%B9%B3%3D%E4%BB%AE%E5%90%8D=%E5%B9%B3%E4%BB%AE%E5%90%8D&b'
              '=%E5%B9%B3%E4%BB%AE%E5%90%8D'
          .codeUnits,
      {'平=仮名': '平仮名', 'b': '平仮名'},
      'form');

  check('application/x-www-form-urlencoded', 'a=%F8+%26%23548%3B'.codeUnits,
      null, 'form',
      shouldFail: true);

  check('application/x-www-form-urlencoded', 'a=%C0%A0'.codeUnits, null, 'form',
      shouldFail: true);

  check('application/x-www-form-urlencoded', 'a=x%A0x'.codeUnits, null, 'form',
      shouldFail: true);

  check('application/x-www-form-urlencoded', 'a=x%C0x'.codeUnits, null, 'form',
      shouldFail: true);

  check('application/x-www-form-urlencoded', 'a=%C3%B8+%C8%A4'.codeUnits,
      {'a': 'ø Ȥ'}, 'form');

  check('application/x-www-form-urlencoded', 'a=%F8+%26%23548%3B'.codeUnits,
      {'a': 'ø &#548;'}, 'form',
      defaultEncoding: latin1);

  check('application/x-www-form-urlencoded', 'name=%26'.codeUnits,
      {'name': '&'}, 'form',
      defaultEncoding: latin1);

  check('application/x-www-form-urlencoded', 'name=%F8%26'.codeUnits,
      {'name': 'ø&'}, 'form',
      defaultEncoding: latin1);

  check('application/x-www-form-urlencoded', 'name=%26%3B'.codeUnits,
      {'name': '&;'}, 'form',
      defaultEncoding: latin1);

  check(
      'application/x-www-form-urlencoded',
      'name=%26%23548%3B%26%23548%3B'.codeUnits,
      {'name': '&#548;&#548;'},
      'form',
      defaultEncoding: latin1);

  check('application/x-www-form-urlencoded', 'name=%26'.codeUnits,
      {'name': '&'}, 'form');

  check('application/x-www-form-urlencoded', 'name=%C3%B8%26'.codeUnits,
      {'name': 'ø&'}, 'form');

  check('application/x-www-form-urlencoded', 'name=%26%3B'.codeUnits,
      {'name': '&;'}, 'form');

  check('application/x-www-form-urlencoded',
      'name=%C8%A4%26%23548%3B'.codeUnits, {'name': 'Ȥ&#548;'}, 'form');

  check('application/x-www-form-urlencoded', 'name=%C8%A4%C8%A4'.codeUnits,
      {'name': 'ȤȤ'}, 'form');
}

void main() {
  test('client response body', _testHttpClientResponseBody);
  test('server request body', _testHttpServerRequestBody);

  test('Does not close stream while requests are pending', () async {
    var data = StreamController<Uint8List>();
    var requests = Stream<HttpRequest>.fromIterable(
        [FakeHttpRequest(Uri(), data: data.stream)]);
    var isDone = false;
    requests
        .transform(HttpBodyHandler())
        .listen((_) {}, onDone: () => isDone = true);
    await pumpEventQueue();
    expect(isDone, isFalse);
    await data.close();
    expect(isDone, isTrue);
  });

  test('Closes stream while no requests are pending', () async {
    var requests = Stream<HttpRequest>.empty();
    var isDone = false;
    requests
        .transform(HttpBodyHandler())
        .listen((_) {}, onDone: () => isDone = true);
    await pumpEventQueue();
    expect(isDone, isTrue);
  });
}
