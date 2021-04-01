import 'dart:io';

import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  app.get("/html", (req, res) {
    res.headers.contentType = ContentType.html;
    return "<html><body><h1>Title!</h1></body></html>";
  });

  await app.listen(); //Listening on port 3000
}
