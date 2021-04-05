import 'dart:io';

import '../extensions/request_helpers.dart';
import '../extensions/response_helpers.dart';
import 'type_handler.dart';

TypeHandler get directoryTypeHandler =>
    TypeHandler<Directory>((req, res, dynamic val) async {
      final filePath =
          "${val.path}/${req.uri.path.replaceFirst(req.route.replaceAll("*", ""), "")}";
      final fileCandidates = <File>[
        File(filePath),
        File('$filePath/index.html'),
        File('$filePath/index.htm'),
      ];

      for (final file in fileCandidates) {
        if (file.existsSync()) {
          await _respondWithFile(res, file);
          break;
        }
      }
    });

Future _respondWithFile(HttpResponse res, File file) async {
  res.setContentTypeFromFile(file);
  await res.addStream(file.openRead());
  await res.close();
}
