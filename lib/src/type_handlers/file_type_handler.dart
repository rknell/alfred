import 'dart:io';

import '../alfred.dart';
import '../extensions/response_helpers.dart';
import 'type_handler.dart';

TypeHandler get fileTypeHandler =>
    TypeHandler<File>((HttpRequest req, HttpResponse res, dynamic file) async {
      file = file as File;
      if (file.existsSync()) {
        res.setContentTypeFromFile(file);
        await res.addStream(file.openRead());
        return res.close();
      } else {
        throw NotFoundError();
      }
    });
