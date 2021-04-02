import 'dart:io';

import '../extensions/response_helpers.dart';
import 'type_handler.dart';

TypeHandler get fileTypeHandler =>
    TypeHandler<File>((HttpRequest req, HttpResponse res, dynamic val) async {
      val = val as File;
      res.setContentTypeFromFile(val);
      await res.addStream(val.openRead());
      return res.close();
    });
