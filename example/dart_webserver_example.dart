import 'package:webserver/webserver.dart';

void main() {
  final app = Webserver();

  app.listen();

  print("${app.server!.port}");
}
