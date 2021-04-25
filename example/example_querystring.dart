import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  app.post('/route', (req, res) async {
    /// Handle /route?qsvar=true
    final result = req.uri.queryParameters['qsvar'];
    result == 'true'; //true
  });

  await app.listen(); //Listening on port 3000
}
