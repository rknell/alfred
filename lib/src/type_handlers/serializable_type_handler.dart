import 'dart:convert';
import 'dart:io';

import 'type_handler.dart';

TypeHandler<dynamic> get serializableTypeHandler =>
    TypeHandler<dynamic>((HttpRequest req, HttpResponse res, dynamic value) {
      try {
        if (value.toJson != null) {
          res.write(jsonEncode(value.toJson()));
          return res.close();
        }
      } catch (e) {
        if (!e.toString().contains('has no instance getter')) {
          rethrow;
        }
      }

      try {
        if (value.toJSON != null) {
          res.write(jsonEncode(value.toJSON()));
          return res.close();
        }
      } catch (e) {
        if (!e.toString().contains('has no instance getter')) {
          rethrow;
        }
      }

      return false;
    });
