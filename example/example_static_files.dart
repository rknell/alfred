import 'dart:io';

import 'package:alfred/alfred.dart';

main() async {
  final app = Alfred();

  app.static("/public", Directory("test/files"));

  await app.listen();
}
