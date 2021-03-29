import "dart:io";

import "package:alfred/alfred.dart";

Future<void> main() async {
  final app = Alfred();

  app.all("/example", (req, res) => "Hello world");

  app.get("/html", (req, res) {
    res.headers.contentType = ContentType.html;
    return "<html><body><h1>Title!</h1></body></html>";
  });

  app.get("/image", (req, res) => File("test/files/image.jpg"));

  app.get("/image/download", (req, res) {
    res.setDownload(filename: "model10.jpg");
    final file = File("test/files/image.jpg");
    res.headers.contentType = file.contentType;
    return file.openRead();
  }, middleware: [
    (req, res) => {"test": true}
  ]);

  app.get("/redirect",
      (req, res) => res.redirect(Uri.parse("https://www.google.com")));

  app.serveStatic("/files", Directory("test/files"));

  final server = await app.listen();

  print("Listening on ${server.port}");
}
