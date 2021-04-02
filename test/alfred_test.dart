import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:alfred/alfred.dart';
import 'package:alfred/src/middleware/cors.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  late Alfred app;
  late int port;

  setUp(() {
    port = Random().nextInt(65535 - 1024) + 1024;
    app = Alfred();
    return app.listen(port);
  });

  tearDown(() => app.close());

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
    app = Alfred(onInternalError: (req, res) {
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
    app = Alfred();
    await app.listen(port);
    app.get("/throwserror", (req, res) => throw Exception("generic exception"));

    final response =
        await http.get(Uri.parse("http://localhost:$port/throwserror"));
    expect(response.body, 'Exception: generic exception');
  });

  test("not found handling", () async {
    await app.close();
    app = Alfred(onNotFound: (req, res) {
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
    app = Alfred();
    await app.listen(port);

    final response =
        (await http.get(Uri.parse("http://localhost:$port/notfound")));
    expect(response.body, '404 not found');
    expect(response.statusCode, 404);
  });

  test("it handles a post request", () async {
    app.post("/test", (req, res) => "test string");
    final response = await http.post(Uri.parse("http://localhost:$port/test"));
    expect(response.body, "test string");
  });

  test("it handles a put request", () async {
    app.put("/test", (req, res) => "test string");
    final response = await http.put(Uri.parse("http://localhost:$port/test"));
    expect(response.body, "test string");
  });

  test("it handles a delete request", () async {
    app.delete("/test", (req, res) => "test string");
    final response =
        await http.delete(Uri.parse("http://localhost:$port/test"));
    expect(response.body, "test string");
  });

  test("it handles an options request", () async {
    app.options("/test", (req, res) => "test string");

    /// TODO: Need to find a way to send an options request. The HTTP library doesn't
    /// seem to support it.
    ///
    // final response = await http.head(Uri.parse("http://localhost:$port/test"));
    // expect(response.body, "test string");
  });

  test("it handles a patch request", () async {
    app.patch("/test", (req, res) => "test string");
    final response = await http.patch(Uri.parse("http://localhost:$port/test"));
    expect(response.body, "test string");
  });

  test("it handles a route that hits all methods", () async {
    app.all("/test", (req, res) => "test all");
    final responseGet =
        await http.get(Uri.parse("http://localhost:$port/test"));
    final responsePost =
        await http.post(Uri.parse("http://localhost:$port/test"));
    final responsePut =
        await http.put(Uri.parse("http://localhost:$port/test"));
    final responseDelete =
        await http.delete(Uri.parse("http://localhost:$port/test"));
    expect(responseGet.body, "test all");
    expect(responsePost.body, "test all");
    expect(responsePut.body, "test all");
    expect(responseDelete.body, "test all");
  });

  test("it executes middleware, but passes through", () async {
    bool hitMiddleware = false;
    app.get("/test", (req, res) => "test route", middleware: [
      (req, res) {
        hitMiddleware = true;
      }
    ]);
    final response = await http.get(Uri.parse("http://localhost:$port/test"));
    expect(response.body, "test route");
    expect(hitMiddleware, true);
  });

  test("it executes middleware, but handles it and stops executing", () async {
    app.get("/test", (req, res) => "test route", middleware: [
      (req, res) {
        return "hit middleware";
      }
    ]);
    final response = await http.get(Uri.parse("http://localhost:$port/test"));
    expect(response.body, "hit middleware");
  });

  test("it closes out a request if you fail to", () async {
    app.get("/test", (req, res) => null);
    final response = await http.get(Uri.parse("http://localhost:$port/test"));
    expect(response.body, '');
  });

  test("it throws and handles an exception", () async {
    app.get("/test", (req, res) => throw AlfredException(360, "exception"));
    final response = await http.get(Uri.parse("http://localhost:$port/test"));
    expect(response.body, 'exception');
    expect(response.statusCode, 360);
  });

  test("it handles a List<int>", () async {
    app.get("/test", (req, res) => <int>[1, 2, 3, 4, 5]);
    final response = await http.get(Uri.parse("http://localhost:$port/test"));
    expect(response.body, '\x01\x02\x03\x04\x05');
    expect(response.headers["content-type"], 'application/octet-stream');
  });

  test("it handles a Stream<List<int>>", () async {
    app.get(
        "/test",
        (req, res) => Stream.fromIterable([
              [1, 2, 3, 4, 5]
            ]));
    final response = await http.get(Uri.parse("http://localhost:$port/test"));
    expect(response.body, '\x01\x02\x03\x04\x05');
    expect(response.headers["content-type"], 'application/octet-stream');
  });

  test("it parses a body", () async {
    app.post("/test", (req, res) async {
      final body = await req.body;
      expect(body is Map, true);
      expect(req.contentType!.mimeType, "application/json");
      return "test result";
    });

    final response = await http.post(Uri.parse("http://localhost:$port/test"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"test": true}));
    expect(response.body, "test result");
  });

  test("it serves a file for download", () async {
    app.get("/test", (req, res) {
      res.setDownload(filename: "testfile.jpg");
      return File("./test/files/image.jpg");
    });

    final response = await http.get(Uri.parse("http://localhost:$port/test"));
    expect(response.headers["content-type"], 'image/jpeg');
    expect(response.headers["content-disposition"],
        'attachment; filename=testfile.jpg');
  });

  test("it serves a pdf, setting the extension from the filename", () async {
    app.get("/test", (req, res) {
      res.setContentTypeFromExtension("pdf");
      return File("./test/files/dummy.pdf");
    });

    final response = await http.get(Uri.parse("http://localhost:$port/test"));
    expect(response.headers["content-type"], 'application/pdf');
    expect(response.headers["content-disposition"], null);
  });

  test("it uses the json helper correctly", () async {
    app.get("/test", (req, res) async {
      await res.json({"success": true});
    });
    final response = await http.get(Uri.parse("http://localhost:$port/test"));
    expect(response.body, '{"success":true}');
  });

  test("it uses the send helper correctly", () async {
    app.get("/test", (req, res) async {
      await res.send("stuff");
    });
    final response = await http.get(Uri.parse("http://localhost:$port/test"));
    expect(response.body, 'stuff');
  });

  test("it serves static files", () async {
    app.get("/files/*", (req, res) => Directory("test/files"));

    final response =
        await http.get(Uri.parse("http://localhost:$port/files/dummy.pdf"));
    expect(response.statusCode, 200);
    expect(response.headers["content-type"], "application/pdf");

    final responseNotFound = await http
        .get(Uri.parse("http://localhost:$port/files/doesnotexist.png"));
    expect(responseNotFound.statusCode, 404);
    expect(responseNotFound.body, '{"message":"file not found"}');
  });

  test("it routes correctly for a / url", () async {
    app.get("/", (req, res) => "working");
    final response = await http.get(Uri.parse("http://localhost:$port/"));

    expect(response.body, "working");
  });

  test("it handles params", () async {
    app.get("/test/:id", (req, res) => req.params["id"]);
    final response =
        await http.get(Uri.parse("http://localhost:$port/test/15"));
    expect(response.body, "15");
  });

  test("it should implement cors correctly", () async {
    app.all("*", cors(origin: "test-origin"));

    final response = await http.get(Uri.parse("http://localhost:$port/test"));
    expect(response.headers.containsKey("access-control-allow-origin"), true);
    expect(response.headers["access-control-allow-origin"], "test-origin");
    expect(response.headers.containsKey("access-control-allow-headers"), true);
    expect(response.headers.containsKey("access-control-allow-methods"), true);
  });
}
