import 'dart:io';

import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred(onNotFound: (req, res) {
    res.statusCode = 404;
    return View('404');
  });

  app.typeHandlers.add(jinjaTypeHandler('example/jinja/views'));

  app.get(
      '/users',
      (req, res) => View('users', <String, dynamic>{
            'users': [
              {'fullname': 'Jhon Doe', 'email': 'jhondoe@dev.py'},
            ]
          }));

  app.get('/', (req, res) => View('index'));

  app.get('/*', (req, res) => Directory('example/jinja/assets'));

  await app.listen();
}
