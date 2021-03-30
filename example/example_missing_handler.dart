import 'package:alfred/alfred.dart';

main() async {
  final app = Alfred(onNotFound: missingHandler);
  await app.listen();
}

missingHandler(req, res) {
  res.statusCode = 404;
  return {"message": "not found"};
}
