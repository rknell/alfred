import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();
  app.all('/typed-example/:id:int/:name', (req, res) {
    req.params['id'] != null;
    req.params['id'] is int;
    req.params['name'] != null;
  });
  app.all('/example/:id/:name', (req, res) {
    req.params['id'] != null;
    req.params['name'] != null;
  });
  await app.listen();
}
