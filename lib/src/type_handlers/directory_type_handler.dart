import 'dart:io';

import '../alfred_exception.dart';
import '../extensions/request_helpers.dart';
import '../extensions/response_helpers.dart';
import 'type_handler.dart';

TypeHandler get directoryTypeHandler =>
    TypeHandler<Directory>((req, res, val) async {
      final filePath =
          "${val.path}/${req.uri.path.replaceFirst(req.route.replaceAll("*", ""), "")}";
      final file = File(filePath);
      final exists = await file.exists();
      if (!exists) {
        throw AlfredException(404, {"message": "file not found"});
      }
      res.setContentTypeFromFile(file);
      await res.addStream(file.openRead());
      await res.close();
    });
