import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  app.post('/post-route', (req, res) async {
    final body = await req.body; //JSON body
    body != null; //true
  });

  await app.listen(); //Listening on port 3000
}
