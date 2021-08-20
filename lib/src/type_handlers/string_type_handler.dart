import 'dart:io';

import 'package:alfred/src/type_handlers/type_handler.dart';

TypeHandler<String> get stringTypeHandler =>
    TypeHandler<String>((HttpRequest req, HttpResponse res, String value) {
      res.write(value);
      return res.close();
    });
