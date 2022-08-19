import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../alfred.dart';
import '../alfred_exception.dart';
import '../body_parser/http_body.dart';
import '../extensions/request_helpers.dart';
import '../extensions/response_helpers.dart';
import 'type_handler.dart';

TypeHandler get directoryTypeHandler =>
    TypeHandler<Directory>((req, res, Directory directory) async {
      directory = directory.absolute;
      final usedRoute = req.route;
      String? virtualPath;
      if (usedRoute.contains('*')) {
        virtualPath = req.uri.path
            .substring(min(req.uri.path.length, usedRoute.indexOf('*')));
      }
 
      if (req.method == 'GET' || req.method == 'HEAD') {
        assert(usedRoute.contains('*'),
            'TypeHandler of type Directory  GET request needs a route declaration that contains a wildcard (*). Found: $usedRoute');

        final filePath =
            '${directory.path}/${Uri.decodeComponent(virtualPath!)}';

        req.preventTraversal(filePath, directory);

        req.log(() => 'Resolve virtual path: $virtualPath');

        final fileCandidates = <File>[
          File(filePath),
          File('$filePath/index.html'),
          File('$filePath/index.htm'),
        ];

        try {
          var match = fileCandidates.firstWhere((file) => file.existsSync());
          req.log(() => 'Respond with file: ${match.path}');
          await _respondWithFile(res, match, headerOnly: req.method == 'HEAD');
        } on StateError {
          req.log(() =>
              'Could not match with any file. Expected file at: $filePath');
        }
      }
      if (req.method == 'POST' || req.method == 'PUT') {
        //Upload file
        final body = await req.body;

        if (body is Map && body['file'] is HttpBodyFileUpload) {
          if (virtualPath != null) {
            req.preventTraversal('${directory.path}/$virtualPath', directory);
            directory = Directory('${directory.path}/$virtualPath').absolute;
          }
          if (await directory.exists() == false) {
            await directory.create(recursive: true);
          }
          final fileName = (body['file'] as HttpBodyFileUpload).filename;
          
          final fileToWrite =
              File('${directory.path}/$fileName');

          req.preventTraversal(fileToWrite.path, directory);

          await fileToWrite.writeAsBytes(
              (body['file'] as HttpBodyFileUpload).content as List<int>);
          final publicPath =
              "${req.requestedUri.toString() + (virtualPath != null ? '/$virtualPath' : '')}/$fileName";
          req.log(() => 'Uploaded file $publicPath');

          await res.json({'path': publicPath});
        }
      }
      if (req.method == 'DELETE') {
        final fileToDelete =
            File('${directory.path}/${Uri.decodeComponent(virtualPath!)}');

        req.preventTraversal(fileToDelete.path, directory);

        if (await fileToDelete.exists()) {
          await fileToDelete.delete();
          await res.json({'success': 'true'});
        } else {
          res.statusCode = 404;
          await res.json({'error': 'file not found'});
        }
      }
    });

Future _respondWithFile(HttpResponse res, File file,
    {bool headerOnly = false}) async {
  res.setContentTypeFromFile(file);

  // This is necessary to deal with 'HEAD' requests
  if (headerOnly == false) {
    await res.addStream(file.openRead());
  }
  await res.close();
}

extension _Logger on HttpRequest {
  void log(String Function() msgFn) =>
      alfred.logWriter(() => 'DirectoryTypeHandler: ${msgFn()}', LogType.debug);

  void preventTraversal(String filePath, Directory absDir) {
    final check = File(filePath).absolute;
    final absDirPath = p.canonicalize(absDir.path);
    if (!p.canonicalize(check.path).startsWith(absDirPath)) {
      log(() => 'Server directory traversal attempt: ${check.path}');
      throw AlfredException(403, '403 forbidden');
    }
  }
}
