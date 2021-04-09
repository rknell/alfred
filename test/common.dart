import 'package:alfred/alfred.dart';

extension AlfredTestExtension on Alfred {
  Future<int> listenForTest() async {
    await listen(0);
    return server!.port;
  }
}
