import 'dart:io';

import 'package:alfred/alfred.dart';

final _uploadDirectory = Directory('uploadedFiles');

Future<void> main() async {
  final app = Alfred();

  app.get('/files/*', (req, res) => _uploadDirectory);

  /// Example of handling a multipart/form-data file upload
  app.post('/upload', (req, res) async {
    final body = await req.bodyAsJsonMap;

    // Create the upload directory if it doesn't exist
    if (await _uploadDirectory.exists() == false) {
      await _uploadDirectory.create();
    }

    // Get the uploaded file content
    final uploadedFile = (body['file'] as HttpBodyFileUpload);
    var fileBytes = (uploadedFile.content as List<int>);

    // Create the local file name and save the file
    await File('${_uploadDirectory.absolute}/${uploadedFile.filename}')
        .writeAsBytes(fileBytes);

    /// Return the path to the user
    ///
    /// The path is served from the /files route above
    return ({
      'path': 'https://${req.headers.host ?? ''}/files/${uploadedFile.filename}'
    });
  });

  await app.listen();
}
