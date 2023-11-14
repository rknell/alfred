import 'dart:convert';
import 'dart:io';

import 'package:mime_type/mime_type.dart';

import 'file_helpers.dart';

/// A set of extensions on the [HttpResponse] object, mostly for convenience
///
extension ResponseHelpers on HttpResponse {
  /// Set the appropriate headers to download the file
  ///
  void setDownload({required String filename}) {
    headers.add('Content-Disposition', 'attachment; filename=$filename');
  }

  /// Set the content type from the extension ie. 'pdf'
  ///
  void setContentTypeFromExtension(String extension) {
    final mime = mimeFromExtension(extension);
    if (mime != null) {
      final split = mime.split('/');
      headers.contentType = ContentType(split[0], split[1]);
    }
  }

  /// Set the content type given a file
  ///
  void setContentTypeFromFile(File file) {
    final setContentType = headers.contentType;

    if (setContentType == null || setContentType.mimeType == 'text/plain') {
      final fileContentType = file.contentType;
      if (fileContentType != null) {
        headers.contentType = file.contentType;
      } else {
        final extension = file.path.split('.').last;
        final suggestedMime = mimeFromExtension(extension);
        if (suggestedMime != null) {
          setContentTypeFromExtension(extension);
        } else {
          headers.contentType = ContentType.binary;
        }
      }
    }
  }

  /// Helper method for those used to res.json()
  ///
  Future json(Object? json) {
    headers.contentType = ContentType.json;
    write(jsonEncode(json));
    return close();
  }

  /// Helper method to just send data;
  Future send(Object? data) {
    write(data);
    return close();
  }
}
