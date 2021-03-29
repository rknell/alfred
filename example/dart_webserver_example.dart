import 'package:alfred/alfred.dart';

void main() {
  final app = Alfred();

  app.listen();

  print("${app.server!.port}");
}
