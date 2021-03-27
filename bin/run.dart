import "dart:io";

import "package:webserver/webserver.dart";

Future<void> main() async {
  final app = Webserver();

  app.all("/example", (req, res) => "Hello world");

  app.get("/html", (req, res) {
    res.headers.contentType = ContentType.html;
    return "<html><body><h1>Title!</h1></body></html>";
  });

  app.get("/image", (req, res) => File('model10.jpg'));

  app.get("/image/download", (req, res) {
    res.setDownload(filename: "model10.jpg");
    final file = File("model10.jpg");
    res.headers.contentType = file.contentType;
    return file.openRead();
  });

  app.get("/redirect",
      (req, res) => res.redirect(Uri.parse("https://www.google.com")));

  final server = await app.listen();

  print("Listening on ${server.port}");
}
