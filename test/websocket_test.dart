import 'dart:math';

import 'package:alfred/alfred.dart';
import 'package:alfred/src/type_handlers/websocket_type_handler.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  late Alfred app;
  late int port;

  setUp(() {
    port = Random().nextInt(65535 - 1024) + 1024;
    app = Alfred();
    return app.listen(port);
  });

  tearDown(() => app.close());

  test('it can handle websockets', () async {
    var opened = false;
    var closed = false;
    String? message;

    app.get(
        '/ws',
        (req, res) => WebSocketSession(
              onOpen: (ws) => opened = true,
              onClose: (ws) => closed = true,
              onMessage: (ws, dynamic data) {
                message = data as String;
                ws.send('echo $data');
              },
            ));

    final channel = IOWebSocketChannel.connect('ws://localhost:$port/ws');

    channel.sink.add('hi');

    var response = (await channel.stream.first) as String;
    expect(opened, true);
    expect(closed, false);
    expect(message, 'hi');
    expect(response, 'echo hi');

    await channel.sink.close();
    await Future<void>.delayed(Duration(milliseconds: 10));
    expect(closed, true);
  });

  test('it correctly handles a websocket error', () async {
    app.get(
        '/ws',
        (req, res) => WebSocketSession(
              onOpen: (ws) {
                throw 'Test';
              },
              onError: (ws, dynamic error) => error = true,
            ));

    final channel = IOWebSocketChannel.connect('ws://localhost:$port/ws');

    channel.sink.add('test');
  });
}
