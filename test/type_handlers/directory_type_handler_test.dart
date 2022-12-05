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

  test('it throws when passing a route without a wildcard in a get request',
      () async {
    app.get('/test', (req, res) => Directory.current);
    final response = await http.get(Uri.parse('http://localhost:$port/test'));
    expect(response.statusCode, 500);
  });

  test('it handles not finding a file', () async {
    app.get('/test/*', (req, res) => Directory.current);
    final response =
        await http.get(Uri.parse('http://localhost:$port/test/randomname.png'));
    expect(response.statusCode, 404);
  });

  test('it uploads a file', () async {
    final uploadedFile = File('test/files/tmp.jpg');

    if (uploadedFile.existsSync() == true) {
      uploadedFile.deleteSync();
    }

    app.post('/test', (req, res) => Directory('test/files'));

    final fileToUpload = File('test/files/image.jpg');

    final request =
        http.MultipartRequest('POST', Uri.parse('http://localhost:$port/test'))
          ..files.add(http.MultipartFile(
              'file', fileToUpload.openRead(), fileToUpload.lengthSync(),
              filename: 'tmp.jpg'));

    final response = await request.send();
    expect(response.statusCode, 200);
    expect(uploadedFile.existsSync(), true);
  });

  test('it uploads a file to a subdirectory, creating it if it doesnt exist',
      () async {
    final uploadedFile = File('test/files/subdir/tmp.jpg');
    final subdir = Directory('test/files/subdir');
    if (subdir.existsSync()) {
      subdir.deleteSync(recursive: true);
    }

    if (uploadedFile.existsSync() == true) {
      uploadedFile.deleteSync();
    }

    app.post('/test/*', (req, res) => Directory('test/files'));

    final fileToUpload = File('test/files/image.jpg');

    final request = http.MultipartRequest(
        'POST', Uri.parse('http://localhost:$port/test/subdir'))
      ..files.add(http.MultipartFile(
          'file', fileToUpload.openRead(), fileToUpload.lengthSync(),
          filename: 'tmp.jpg'));

    final response = await request.send();
    expect(response.statusCode, 200);
    expect(uploadedFile.existsSync(), true);
    uploadedFile.deleteSync();
  });

  test('it deletes a file', () async {
    File('test/files/image.jpg').copySync('test/files/tmp.jpg');
    final fileToDelete = File('test/files/tmp.jpg');
    expect(fileToDelete.existsSync(), true);

    app.delete('/test/*', (req, res) => Directory('test/files'));

    final response =
        await http.delete(Uri.parse('http://localhost:$port/test/tmp.jpg'));
    expect(response.statusCode, 200);
    expect(fileToDelete.existsSync(), false);
  });

  test('it cant delete a file that isnt there', () async {
    app.delete('/test/*', (req, res) => Directory('test/files'));

    final response = await http
        .delete(Uri.parse('http://localhost:$port/test/randomfile.jpg'));
    expect(response.statusCode, 404);
  });

  test('it refuses to serve a file not under the base directory', () async {
    app.get('/test/*', (req, res) => Directory('test/files'));
    final response = await http
        .get(Uri.parse('http://localhost:$port/test/..%2f/common.dart'));
    expect(response.statusCode, 403);
  });
}
