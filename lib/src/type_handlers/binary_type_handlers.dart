import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:alfred/src/type_handlers/type_handler.dart';

FutureOr _binaryTypeHandler(req, res, val) async {
  if (res.headers.contentType == null ||
      res.headers.contentType!.value == 'text/plain') {
    res.headers.contentType = ContentType.binary;
  }
  res.add(val);
  await res.close();
}

TypeHandler get listIntTypeHandler =>
    TypeHandler<List<int>>(_binaryTypeHandler);
TypeHandler get uint8listTypeHandler =>
    TypeHandler<Uint8List>(_binaryTypeHandler);

TypeHandler get binaryStreamTypeHandler => TypeHandler<Stream<List<int>>>(
        (HttpRequest req, HttpResponse res, val) async {
      if (res.headers.contentType == null ||
          res.headers.contentType!.value == 'text/plain') {
        res.headers.contentType = ContentType.binary;
      }
      await res.addStream(val);
      await res.close();
    });
