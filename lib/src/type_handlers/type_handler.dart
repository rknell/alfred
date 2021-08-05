import 'dart:async';
import 'dart:io';

typedef TypeHandlerFunction<T> = FutureOr Function(HttpRequest req, HttpResponse res, T value);

class TypeHandler<T> {
  TypeHandler(TypeHandlerFunction<T> handler) : handler = _wrap(handler);

  TypeHandlerFunction<dynamic> handler;

  bool shouldHandle(dynamic item) => item is T;
}

TypeHandlerFunction<dynamic> _wrap<T>(TypeHandlerFunction<T> handler) {
  return (HttpRequest req, HttpResponse res, dynamic value) => handler(req, res, value as T);
}
