import 'dart:io';

import 'type_handler.dart';

TypeHandler<String> get stringTypeHandler =>
    TypeHandler<String>((HttpRequest req, HttpResponse res, String value) {
      res.write(value);
      return res.close();
    });
