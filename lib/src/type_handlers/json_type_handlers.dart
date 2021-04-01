import 'dart:convert';
import 'dart:io';

import 'package:alfred/src/type_handlers/type_handler.dart';

_jsonHandler(req, res, val) async {
  res.headers.contentType = ContentType.json;
  res.write(jsonEncode(val));
  await res.close();
}

TypeHandler get jsonMapTypeHandler =>
    TypeHandler<Map<String, dynamic>>(_jsonHandler);
TypeHandler get jsonListTypeHandler => TypeHandler<List<dynamic>>(_jsonHandler);
