import 'package:alfred/alfred.dart';

main() async {
  final app = Alfred();

  app.get("/example", (req, res) => "Hello world");

  await app.listen();

  print("Listening on port 3000");
}
