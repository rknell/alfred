import 'package:alfred/alfred.dart';

main() async {
  final app = Alfred(onInternalError: errorHandler);
  await app.listen();
  app.get("/throwserror", (req, res) => throw Exception("generic exception"));
}

errorHandler(req, res) {
  res.statusCode = 500;
  return {"message": "error not handled"};
}
