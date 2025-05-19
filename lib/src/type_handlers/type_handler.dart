import 'dart:async';
import 'dart:io';

class TypeHandler<T> {
  TypeHandler(this._handler);

  final FutureOr Function(HttpRequest, HttpResponse, T) _handler;

  FutureOr handler(HttpRequest req, HttpResponse res, dynamic item) =>
      _handler(req, res, item as T);

  bool shouldHandle(dynamic item) => item is T;
}

/// TypeHandler for Future<void> (no-op, response already sent)
TypeHandler<Future<void>> get futureVoidTypeHandler =>
    TypeHandler<Future<void>>(
        (HttpRequest req, HttpResponse res, Future<void> value) async {
      // Await the future to ensure completion, but do nothing else.
      await value;
      return true; // Indicate handled
    });

/// TypeHandler for HttpResponse (no-op, response already sent)
TypeHandler<HttpResponse> get httpResponseTypeHandler =>
    TypeHandler<HttpResponse>(
        (HttpRequest req, HttpResponse res, HttpResponse value) {
      // Do nothing, response is already sent
      return true; // Indicate handled
    });
