import 'dart:io';

import '../extensions/response_helpers.dart';
import 'type_handler.dart';

TypeHandler get fileTypeHandler =>
    TypeHandler<File>((req, res, dynamic val) async {
      var file = val as File;
      res.setContentTypeFromFile(file);
      await res.addStream(file.openRead());
      await res.close();
    });
