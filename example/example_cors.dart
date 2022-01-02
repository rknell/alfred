import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  // Warning: defaults to origin "*"
  app.all('*', cors(origin: 'myorigin.com'));

  await app.listen();
}
