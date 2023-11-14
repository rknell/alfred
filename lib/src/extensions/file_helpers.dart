import 'dart:io';

import 'package:mime_type/mime_type.dart';

/// A set of extensions on the file object which help in composing http responses
extension FileHelpers on File {
  /// Get the mimeType as a string
  ///
  String? get mimeType => mime(path);

  /// Get the contentType header from the current
  ///
  ContentType? get contentType {
    final mimeType = this.mimeType;
    if (mimeType != null) {
      final split = mimeType.split('/');
      return ContentType(split[0], split[1]);
    } else {
      return null;
    }
  }
}
