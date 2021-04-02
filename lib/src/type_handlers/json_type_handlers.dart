import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alfred/src/type_handlers/type_handler.dart';


FutureOr _jsonHandler(req, res, val) {
  res.headers.contentType = ContentType.json;
  res.write(jsonEncode(val));
  return res.close();
}

TypeHandler get jsonMapTypeHandler =>
    TypeHandler<Map<String, dynamic>>(_jsonHandler);

TypeHandler get jsonListTypeHandler => TypeHandler<List<dynamic>>(_jsonHandler);
