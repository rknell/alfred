import 'dart:async';

import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred(onInternalError: errorHandler);
  await app.listen();
  app.get("/throwserror", (req, res) => throw Exception("generic exception"));
}

FutureOr errorHandler(req, res) {
  res.statusCode = 500;
  return {"message": "error not handled"};
}
