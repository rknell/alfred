import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  app.get('/html', (req, res) {});

  app.printRoutes(); //Will print the routes to the console

  await app.listen();
}
