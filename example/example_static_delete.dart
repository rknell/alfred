import 'dart:async';
import 'dart:io';

import 'package:alfred/alfred.dart';

FutureOr isAuthenticatedMiddleware(HttpRequest req, HttpResponse res) {
  if (req.headers.value('Authorization') != 'MYAPIKEY') {
    throw AlfredException(
        401, {'error': 'You are not authorized to perform this operation'});
  }
}

void main() async {
  final app = Alfred();

  /// Note the wildcard (*) this is very important!!
  ///
  /// You almost certainly want to protect this endpoint with some middleware
  /// to authenticate a user.
  app.delete('/public/*', (req, res) => Directory('test/files'),
      middleware: [isAuthenticatedMiddleware]);

  await app.listen();
}
