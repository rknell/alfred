import 'dart:async';
import 'dart:io';

import 'package:alfred/alfred.dart';

FutureOr exampleMiddlware(HttpRequest req, HttpResponse res) {
  // Do work
}

void main() async {
  final app = Alfred();
  app.all("/example/:id/:name", (req, res) {
    req.params["id"] != null; //true
    req.params["name"] != null; //true;
  }, middleware: [exampleMiddlware]);

  await app.listen(); //Listening on port 3000
}
