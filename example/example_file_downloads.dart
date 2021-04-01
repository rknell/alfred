import 'dart:io';

import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  app.get("/image/download", (req, res) {
    res.setDownload(filename: "image.jpg");
    return File("test/files/image.jpg");
  });

  await app.listen(); //Listening on port 3000
}
