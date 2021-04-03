import 'dart:io';

import 'package:alfred/alfred.dart';

Future<void> main() async {
  final app = Alfred();

  // Provide any static assets
  app.get('/frontend/*', (req, res) => Directory('spa'));

  // Let any other routes handle by client SPA
  app.get('/frontend/*', (req, res) => File('spa/index.html'));

  await app.listen();
}
