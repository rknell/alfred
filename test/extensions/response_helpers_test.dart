import 'dart:io';

import 'package:alfred/alfred.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../common.dart';

void main() {
  late Alfred app;
  late int port;

  setUp(() async {
    app = Alfred();
    port = await app.listenForTest();
  });

  tearDown(() => app.close());

  test('it should set the mime type correctly for pdf files', () async {
    app.get('/pdfFile', (req, res) {
      var file = File('test/files/dummy.pdf');
      res.setContentTypeFromFile(file);
    });

    final response =
        await http.get(Uri.parse('http://localhost:$port/pdfFile'));

    expect(response.headers['content-type'], 'application/pdf');
  });
}
