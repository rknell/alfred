import 'package:alfred/alfred.dart';

main() async {
  final app = Alfred();

  app.post("/post-route", (req, res) async {
    final body = await req.body; //JSON body
  });

  await app.listen(); //Listening on port 3000
}
