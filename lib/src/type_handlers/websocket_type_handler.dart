import 'dart:async';
import 'dart:io';

import 'type_handler.dart';

TypeHandler<WebSocketSession> get websocketTypeHandler =>
    TypeHandler<WebSocketSession>(
        (HttpRequest req, HttpResponse res, WebSocketSession value) async {
      var ws = await WebSocketTransformer.upgrade(req);
      value._start(ws);
    });

/// Convenience wrapper around Dart IO WebSocket implementation
class WebSocketSession {
  late WebSocket socket;

  FutureOr<void> Function(WebSocket webSocket)? onOpen;
  FutureOr<void> Function(WebSocket webSocket, dynamic data)? onMessage;
  FutureOr<void> Function(WebSocket webSocket)? onClose;
  FutureOr<void> Function(WebSocket webSocket, dynamic error)? onError;

  WebSocketSession({this.onOpen, this.onMessage, this.onClose, this.onError});

  void _start(WebSocket webSocket) {
    socket = webSocket;
    try {
      if (onOpen != null) {
        onOpen!(socket);
      }
      socket.listen((dynamic data) {
        if (onMessage != null) {
          onMessage!(socket, data);
        }
      }, onDone: () {
        if (onClose != null) {
          onClose!(socket);
        }
      }, onError: (dynamic error) {
        if (onError != null) {
          onError!(socket, error);
        }
      });
    } catch (e) {
      print('WebSocket Error: $e');
      try {
        socket.close();
        // ignore: empty_catches
      } catch (e) {}
    }
  }
}

extension WebSocketHelper on WebSocket {
  /// Sends data to the client
  void send(dynamic data) => add(data);
}
