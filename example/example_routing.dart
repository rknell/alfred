import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();
  app.all('/example/:id/:name', (req, res) {
    req.params['id'] != null;
    req.params['name'] != null;
  });
  await app.listen();
}
