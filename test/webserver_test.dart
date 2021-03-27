import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:webserver/webserver.dart';

void main() {
  late Webserver app;
  late int port;

  setUp(() async {
    port = Random().nextInt(65535 - 1024);
    app = Webserver();
    await app.listen(port);
  });

  tearDown(() async {
    await app.close();
  });

  test("it should return a string correctly", () async {
    app.get("/test", (req, res) => "test string");
    final response = await http.get(Uri.parse("http://localhost:$port/test"));
    expect(response.body, "test string");
  });

  test("it should return json", () async {
    app.get("/test", (req, res) => {"test": true});
    final response = await http.get(Uri.parse("http://localhost:$port/test"));
    expect(response.headers["content-type"], "application/json; charset=utf-8");
    expect(response.body, '{"test":true}');
  });

  test("it should return an image", () async {
    app.get("/test", (req, res) => File("test/files/image.jpg"));
    final response = await http.get(Uri.parse("http://localhost:$port/test"));
    expect(response.headers["content-type"], "image/jpeg");
  });

  test("it should return a pdf", () async {
    app.get("/test", (req, res) => File("test/files/dummy.pdf"));
    final response = await http.get(Uri.parse("http://localhost:$port/test"));
    expect(response.headers["content-type"], "application/pdf");
  });

  test("routing should, you know, work", () async {
    app.get("/test", (req, res) => "test_route");
    app.get("/testRoute", (req, res) => "test_route_route");
    app.get("/a", (req, res) => "a_route");
    expect((await http.get(Uri.parse("http://localhost:$port/test"))).body,
        "test_route");
    expect((await http.get(Uri.parse("http://localhost:$port/testRoute"))).body,
        "test_route_route");
    expect((await http.get(Uri.parse("http://localhost:$port/a"))).body,
        "a_route");
  });

  test("error handling", () async {
    await app.close();
    app = Webserver(on500: (req, res) {
      res.statusCode = 500;
      return {"message": "error not handled"};
    });
    await app.listen(port);
    app.get("/throwserror", (req, res) => throw Exception("generic exception"));

    expect(
        (await http.get(Uri.parse("http://localhost:$port/throwserror"))).body,
        '{"message":"error not handled"}');
  });

  test("error default handling", () async {
    await app.close();
    app = Webserver();
    await app.listen(port);
    app.get("/throwserror", (req, res) => throw Exception("generic exception"));

    final response =
        await http.get(Uri.parse("http://localhost:$port/throwserror"));
    expect(response.body, 'Exception: generic exception');
  });

  test("not found handling", () async {
    await app.close();
    app = Webserver(on404: (req, res) {
      res.statusCode = 404;
      return {"message": "not found"};
    });
    await app.listen(port);

    final response =
        (await http.get(Uri.parse("http://localhost:$port/notfound")));
    expect(response.body, '{"message":"not found"}');
    expect(response.statusCode, 404);
  });

  test("not found default handling", () async {
    await app.close();
    app = Webserver();
    await app.listen(port);

    final response =
        (await http.get(Uri.parse("http://localhost:$port/notfound")));
    expect(response.body, '404 not found');
    expect(response.statusCode, 404);
  });
}
