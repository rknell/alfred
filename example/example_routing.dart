import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();
  app.all('/example/:id/:name', (req, res) {
    req.params['id'] != null;
    req.params['name'] != null;
  });
  app.all('/typed-example/:id:int/:name', (req, res) {
    req.params['id'] != null;
    req.params['id'] is int;
    req.params['name'] != null;
  });
  app.get('/blog/:date:date/:id:int', (req, res) {
    req.params['date'] != null;
    req.params['date'] is DateTime;
    req.params['id'] != null;
    req.params['id'] is int;
  });
  await app.listen();
}
