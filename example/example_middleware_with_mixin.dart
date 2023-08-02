import 'dart:async';

import 'package:alfred/alfred.dart';

class _ExampleMiddleware with CallableRequestMixin{
  @override
  FutureOr call(HttpRequest req, HttpResponse res) {
    if (req.headers.value('Authorization') != 'apikey') {
      throw AlfredException(401, {'message': 'authentication failed'});
    }
  }
}
void main() async {
  final app = Alfred();
  app.all('/example/:id/:name', (req, res) {}, middleware: [_ExampleMiddleware()]);

  await app.listen(); //Listening on port 3000
}
