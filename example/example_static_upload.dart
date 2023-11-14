import 'dart:io';

import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  app.post('/public', (req, res) => Directory('test/files'));

  await app.listen();
}
