import 'dart:io';

import '../extensions/response_helpers.dart';
import 'type_handler.dart';

TypeHandler get fileTypeHandler => TypeHandler<File>((req, res, val) async {
      res.setContentTypeFromFile(val);
      await res.addStream(val.openRead());
      return res.close();
    });
