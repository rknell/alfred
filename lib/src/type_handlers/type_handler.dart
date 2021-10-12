import 'dart:async';
import 'dart:io';

class TypeHandler<T> {
  TypeHandler(this._handler);

  final FutureOr Function(HttpRequest, HttpResponse, T) _handler;

  FutureOr handler(HttpRequest req, HttpResponse res, dynamic item) =>
      _handler(req, res, item as T);

  bool shouldHandle(dynamic item) => item is T;
}
