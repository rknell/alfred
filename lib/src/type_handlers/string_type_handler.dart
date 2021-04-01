import 'dart:io';

import 'package:alfred/src/type_handlers/type_handler.dart';

TypeHandler<String> get stringTypeHandler =>
    TypeHandler<String>((HttpRequest req, HttpResponse res, value) async {
      res.write(value);
      await res.close();
    });
