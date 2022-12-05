import 'dart:async';
import 'dart:io';

import 'package:alfred/alfred.dart';
import 'package:alfred/src/type_handlers/websocket_type_handler.dart';

Future<void> main() async {
  final app = Alfred();

  // Path to this Dart file
  var dir = File(Platform.script.path).parent.path;

  // Deliver web client for chat
  app.get('/', (req, res) => File('$dir/chat-client.html'));

  // Track connected clients
  var users = <WebSocket>[];

  // WebSocket chat relay implementation
  app.get('/ws', (req, res) {
    return WebSocketSession(
      onOpen: (ws) {
        users.add(ws);
        users
            .where((user) => user != ws)
            .forEach((user) => user.send('A new user joined the chat.'));
      },
      onClose: (ws) {
        users.remove(ws);
        for (var user in users) {
          user.send('A user has left.');
        }
      },
      onMessage: (ws, dynamic data) async {
        for (var user in users) {
          user.send(data);
        }
      },
    );
  });

  final server = await app.listen();

  print('Listening on ${server.port}');
}
