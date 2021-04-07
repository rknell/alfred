import 'dart:io';
import 'dart:math';

import 'package:alfred/alfred.dart';

import '../extensions/request_helpers.dart';
import '../extensions/response_helpers.dart';
import 'type_handler.dart';

TypeHandler get directoryTypeHandler =>
    TypeHandler<Directory>((req, res, dynamic directory) async {
      directory = directory as Directory;
      var usedRoute = req.route;

      assert(usedRoute.endsWith('*'),
          'TypeHandler of type Directory needs a route declaration that ends with a wildcard (*). Found: $usedRoute');

      final virtualPath = req.uri.path
          .substring(min(req.uri.path.length, usedRoute.indexOf('*')));
      final filePath = '${directory.path}/$virtualPath';

      req.log(() => 'Resolve virtual path: $virtualPath');

      final fileCandidates = <File>[
        File(filePath),
        File('$filePath/index.html'),
        File('$filePath/index.htm'),
      ];

      try {
        var match = fileCandidates.firstWhere((file) => file.existsSync());
        req.log(() => 'Respond with file: ${match.path}');
        await _respondWithFile(res, match);
      } on StateError {
        req.log(
            () => 'Could not match with any file. Expected file at: $filePath');
      }
    });

Future _respondWithFile(HttpResponse res, File file) async {
  res.setContentTypeFromFile(file);
  await res.addStream(file.openRead());
  await res.close();
}

extension _Logger on HttpRequest {
  void log(String Function() msgFn) =>
      alfred.logWriter(() => 'DirectoryTypeHandler: ${msgFn()}', LogType.debug);
}
