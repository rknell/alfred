import 'dart:async';
import 'dart:io';

class TypeHandler<T> {
  Type get type => T.runtimeType;

  TypeHandler(this.handler);

  FutureOr Function(HttpRequest req, HttpResponse res, dynamic value) handler;

  bool shouldHandle(Object item) => item is T;
}
