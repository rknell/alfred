import 'dart:io';

import 'package:alfred/alfred.dart';

exampleMiddlware(HttpRequest req, HttpResponse res) {
  // Do work
}

main() async {
  final app = Alfred();
  app.all("/example/:id/:name", (req, res) {
    req.params["id"] != null; //true
    req.params["name"] != null; //true;
  }, middleware: [exampleMiddlware]);

  final server = await app.listen();
}
