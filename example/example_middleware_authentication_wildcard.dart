import 'dart:async';

import 'package:alfred/alfred.dart';

FutureOr _authenticationMiddleware(HttpRequest req, HttpResponse res) async {
  res.statusCode = 401;
  await res.close();
}

void main() async {
  final app = Alfred();

  app.all('/resource*', (req, res) => _authenticationMiddleware);

  app.get('/resource', (req, res) {}); //Will not be hit
  app.post('/resource', (req, res) {}); //Will not be hit
  app.post('/resource/1', (req, res) {}); //Will not be hit

  await app.listen();
}
