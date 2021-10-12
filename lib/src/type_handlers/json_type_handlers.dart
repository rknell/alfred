import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'type_handler.dart';

FutureOr _jsonHandler(HttpRequest req, HttpResponse res, dynamic val) {
  res.headers.contentType = ContentType.json;
  res.write(jsonEncode(val));
  return res.close();
}

TypeHandler get jsonMapTypeHandler =>
    TypeHandler<Map<String, dynamic>>(_jsonHandler);

TypeHandler get jsonListTypeHandler => TypeHandler<List<dynamic>>(_jsonHandler);

TypeHandler get jsonNumberTypeHandler => TypeHandler<num>(_jsonHandler);

TypeHandler get jsonBooleanTypeHandler => TypeHandler<bool>(_jsonHandler);
