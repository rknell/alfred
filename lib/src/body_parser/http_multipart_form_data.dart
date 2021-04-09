// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

/// The data in a `multipart/form-data` part.
///
/// ## Example
///
/// ```dart
/// HttpServer server = ...;
/// server.listen((request) {
///   var boundary = request.headers.contentType.parameters['boundary'];
///   request
///       .transform(MimeMultipartTransformer(boundary))
///       .map(HttpMultipartFormData.parse)
///       .map((HttpMultipartFormData formData) {
///         // form data object available here.
///       });
/// ```
///
/// [HttpMultipartFormData] is a Stream, serving either bytes or decoded
/// Strings. Use [isText] or [isBinary] to see what type of data is provided.
class HttpMultipartFormData extends Stream<dynamic> {
  /// The parsed `Content-Type` header value.
  ///
  /// `null` if not present.
  final ContentType? contentType;

  /// The parsed `Content-Disposition` header value.
  ///
  /// This field is always present. Use this to extract e.g. name (form field
  /// name) and filename (client provided name of uploaded file) parameters.
  final HeaderValue contentDisposition;

  /// The parsed `Content-Transfer-Encoding` header value.
  ///
  /// This field is used to determine how to decode the data. Returns `null`
  /// if not present.
  final HeaderValue? contentTransferEncoding;

  /// Whether the data is decoded as [String].
  final bool isText;

  /// Whether the data is raw bytes.
  bool get isBinary => !isText;

  /// The values which indicate that no incoding was performed.
  ///
  /// https://www.w3.org/Protocols/rfc1341/5_Content-Transfer-Encoding.html
  static const _transparentEncodings = ['7bit', '8bit', 'binary'];

  /// Parse a [MimeMultipart] and return a [HttpMultipartFormData].
  ///
  /// If the `Content-Disposition` header is missing or invalid, an
  /// [HttpException] is thrown.
  ///
  /// If the [MimeMultipart] is identified as text, and the `Content-Type`
  /// header is missing, the data is decoded using [defaultEncoding]. See more
  /// information in the
  /// [HTML5 spec](http://dev.w3.org/html5/spec-preview/
  /// constraints.html#multipart-form-data).
  static HttpMultipartFormData parse(MimeMultipart multipart,
      {Encoding defaultEncoding = utf8}) {
    ContentType? contentType;
    HeaderValue? encoding;
    HeaderValue? disposition;
    for (var key in multipart.headers.keys) {
      switch (key) {
        case 'content-type':
          contentType = ContentType.parse(multipart.headers[key]!);
          break;

        case 'content-transfer-encoding':
          encoding = HeaderValue.parse(multipart.headers[key]!);
          break;

        case 'content-disposition':
          disposition = HeaderValue.parse(multipart.headers[key]!,
              preserveBackslash: true);
          break;

        default:
          break;
      }
    }
    if (disposition == null) {
      throw const HttpException(
          "Mime Multipart doesn't contain a Content-Disposition header value");
    }
    if (encoding != null &&
        !_transparentEncodings.contains(encoding.value.toLowerCase())) {
      // TODO(ajohnsen): Support BASE64, etc.
      throw HttpException('Unsupported contentTransferEncoding: '
          '${encoding.value}');
    }

    Stream stream = multipart;
    var isText = contentType == null ||
        contentType.primaryType == 'text' ||
        contentType.mimeType == 'application/json';
    if (isText) {
      Encoding? encoding;
      if (contentType?.charset != null) {
        encoding = Encoding.getByName(contentType!.charset);
      }
      encoding ??= defaultEncoding;
      stream = stream.transform<dynamic>(encoding.decoder);
    }
    return HttpMultipartFormData._(
        contentType, disposition, encoding, multipart, stream, isText);
  }

  final MimeMultipart _mimeMultipart;

  final Stream _stream;

  HttpMultipartFormData._(
      this.contentType,
      this.contentDisposition,
      this.contentTransferEncoding,
      this._mimeMultipart,
      this._stream,
      this.isText);

  @override
  StreamSubscription listen(void Function(dynamic)? onData,
      {void Function()? onDone, Function? onError, bool? cancelOnError}) {
    return _stream.listen(onData,
        onDone: onDone, onError: onError, cancelOnError: cancelOnError);
  }

  /// Returns the value for the header named [name].
  ///
  /// If there is no header with the provided name, `null` will be returned.
  ///
  /// Use this method to index other headers available in the original
  /// [MimeMultipart].
  String? value(String name) {
    return _mimeMultipart.headers[name];
  }
}
