import 'dart:isolate';

import 'package:alfred/alfred.dart';

Future<void> main() async {
  // Fire up 5 isolates
  for (var i = 0; i < 5; i++) {
    unawaited(Isolate.spawn(startInstance, ''));
  }
  // Start listening on this isolate also
  startInstance(null);
}

/// The start function needs to be top level or static. You probably want to
/// run your entire app in an isolate so you don't run into trouble sharing DB
/// connections etc. However you can engineer this however you like.
///
void startInstance(dynamic message) async {
  final app = Alfred();

  app.all('/example', (req, res) => 'Hello world');

  await app.listen();
}

/// Simple function to prevent linting errors, can be ignored
void unawaited(Future future) {}
