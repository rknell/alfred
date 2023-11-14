import 'dart:async';

import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred(onNotFound: missingHandler);
  await app.listen();
}

FutureOr missingHandler(HttpRequest req, HttpResponse res) {
  res.statusCode = 404;
  return {'message': 'not found'};
}
