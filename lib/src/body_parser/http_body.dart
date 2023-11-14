// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' as typedData;

import 'package:alfred/alfred.dart';
import 'package:mime/mime.dart';

import 'http_multipart_form_data.dart';

/// A handler for processing and collecting HTTP message data in to an
/// [HttpBody].
///
/// The content body is parsed, depending on the `Content-Type` header field.
/// When the full body is read and parsed the body content is made available.
/// The class can be used to process both server requests and client responses.
///
/// The following content types are recognized:
///
/// - text/*
/// - application/json
/// - application/x-www-form-urlencoded
/// - multipart/form-data
///
/// For content type `text/*` the body is decoded into a string. The
/// 'charset' parameter of the content type specifies the encoding
/// used for decoding. If no 'charset' is present the default encoding
/// of ISO-8859-1 is used.
///
/// For content type `application/json` the body is decoded into a
/// string which is then parsed as JSON. The resulting body is a
/// [Map].  The 'charset' parameter of the content type specifies the
/// encoding used for decoding. If no 'charset' is present the default
/// encoding of UTF-8 is used.
///
/// For content type `application/x-www-form-urlencoded` the body is a
/// query string which is then split according to the rules for
/// splitting a query string. The resulting body is a `Map<String,
/// String>`.  If the same name is present several times in the query
/// string, then the last value seen for this name will be in the
/// resulting map. The encoding US-ASCII is always used for decoding
/// the body.
///
/// For content type `multipart/form-data` the body is parsed into
/// it's different fields. The resulting body is a `Map<String,
/// dynamic>`, where the value is a [String] for normal fields and a
/// [HttpBodyFileUpload] instance for file upload fields. If the same
/// name is present several times, then the last value seen for this
/// name will be in the resulting map.
///
/// When using content type `multipart/form-data` the encoding of
/// fields with [String] values is determined by the browser sending
/// the HTTP request with the form data. The encoding is specified
/// either by the attribute `accept-charset` on the HTML form, or by
/// the content type of the web page containing the form. If the HTML
/// form has an `accept-charset` attribute the browser will use the
/// encoding specified there. If the HTML form has no `accept-charset`
/// attribute the browser determines the encoding from the content
/// type of the web page containing the form. Using a content type of
/// `text/html; charset=utf-8` for the page and setting
/// `accept-charset` on the HTML form to `utf-8` is recommended as the
/// default for [HttpBodyHandler] is UTF-8. It is important to get
/// these encoding values right, as the actual `multipart/form-data`
/// HTTP request sent by the browser does _not_ contain any
/// information on the encoding. If something else than UTF-8 is used
/// `defaultEncoding` needs to be set in the [HttpBodyHandler]
/// constructor and calls to [processRequest] and [processResponse].
///
/// For all other content types the body will be treated as
/// uninterpreted binary data. The resulting body will be of type
/// `List<int>`.
///
/// To use with the [HttpServer] for request messages, [HttpBodyHandler] can be
/// used as either a [StreamTransformer] or as a per-request handler (see
/// [processRequest]).
///
/// ```dart
/// HttpServer server = ...
/// server.transform(HttpBodyHandler())
///     .listen((HttpRequestBody body) {
///       ...
///     });
/// ```
///
/// To use with the [HttpClient] for response messages, [HttpBodyHandler] can be
/// used as a per-request handler (see [processResponse]).
///
/// ```dart
/// HttpClient client = ...
/// var request = await client.get(...);
/// var response = await request.close();
/// var body = HttpBodyHandler.processResponse(response);
/// ```
class HttpBodyHandler
    extends StreamTransformerBase<HttpRequest, HttpRequestBody> {
  final Encoding _defaultEncoding;

  /// Create a new [HttpBodyHandler] to be used with a [Stream]<[HttpRequest]>,
  /// e.g. a [HttpServer].
  ///
  /// If the page is served using different encoding than UTF-8, set
  /// [defaultEncoding] accordingly. This is required for parsing
  /// `multipart/form-data` content correctly. See the class comment
  /// for more information on `multipart/form-data`.
  HttpBodyHandler({Encoding defaultEncoding = utf8})
      : _defaultEncoding = defaultEncoding;

  /// Process and parse an incoming [HttpRequest].
  ///
  /// The returned [HttpRequestBody] contains a `response` field for accessing
  /// the [HttpResponse].
  ///
  /// See [HttpBodyHandler] for more info on [defaultEncoding].
  static Future<HttpRequestBody> processRequest(HttpRequest request,
      {Encoding defaultEncoding = utf8}) async {
    try {
      var body = await _process(request, request.headers, defaultEncoding);
      return HttpRequestBody._(request, body);
    } catch (e, s) {
      throw BodyParserException(exception: e, stacktrace: s);
    }
  }

  /// Process and parse an incoming [HttpClientResponse].
  ///
  /// See [HttpBodyHandler] for more info on [defaultEncoding].
  static Future<HttpClientResponseBody> processResponse(
      HttpClientResponse response,
      {Encoding defaultEncoding = utf8}) async {
    var body = await _process(response, response.headers, defaultEncoding);
    return HttpClientResponseBody._(response, body);
  }

  @override
  Stream<HttpRequestBody> bind(Stream<HttpRequest> stream) {
    var pending = 0;
    var closed = false;
    return stream.transform(
        StreamTransformer.fromHandlers(handleData: (request, sink) async {
      pending++;
      try {
        var body =
            await processRequest(request, defaultEncoding: _defaultEncoding);
        sink.add(body);
      } catch (e, st) {
        sink.addError(e, st);
      } finally {
        pending--;
        if (closed && pending == 0) sink.close();
      }
    }, handleDone: (sink) {
      closed = true;
      if (pending == 0) sink.close();
    }));
  }
}

/// A HTTP content body produced by [HttpBodyHandler] for either [HttpRequest]
/// or [HttpClientResponse].
class HttpBody {
  /// A high-level type value, that reflects how the body was parsed, e.g.
  /// "text", "binary" and "json".
  final String type;

  /// The content of the body with a type depending on [type].
  final dynamic body;

  HttpBody._(this.type, this.body);
}

/// The body of a [HttpClientResponse].
///
/// Headers can be read through the original [response].
class HttpClientResponseBody extends HttpBody {
  /// The wrapped response.
  final HttpClientResponse response;

  HttpClientResponseBody._(this.response, HttpBody body)
      : super._(body.type, body.body);
}

/// The body of a [HttpRequest].
///
/// Headers can be read, and a response can be sent, through [request].
class HttpRequestBody extends HttpBody {
  /// The wrapped request.
  ///
  /// Note that the [HttpRequest] is already drained, so the
  /// `Stream` methods cannot be used.
  final HttpRequest request;

  HttpRequestBody._(this.request, HttpBody body)
      : super._(body.type, body.body);
}

/// A wrapper around a file upload.
class HttpBodyFileUpload {
  /// The filename of the uploaded file.
  final String filename;

  /// The [ContentType] of the uploaded file.
  ///
  /// For `text/*` and `application/json` the [content] field will a String.
  final ContentType? contentType;

  /// The content of the file.
  ///
  /// Either a [String] or a [List<int>].
  final dynamic content;

  HttpBodyFileUpload._(this.contentType, this.filename, this.content);
}

Future<HttpBody> _process(Stream<List<int>> stream, HttpHeaders headers,
    Encoding defaultEncoding) async {
  Future<HttpBody> asBinary() async {
    var builder = await stream.fold<typedData.BytesBuilder>(
        typedData.BytesBuilder(), (builder, data) => builder..add(data));
    return HttpBody._('binary', builder.takeBytes());
  }

  if (headers.contentType == null) {
    return asBinary();
  }

  var contentType = headers.contentType!;

  Future<HttpBody> asText(Encoding defaultEncoding) async {
    Encoding? encoding;
    var charset = contentType.charset;
    if (charset != null) encoding = Encoding.getByName(charset);
    encoding ??= defaultEncoding;
    dynamic buffer = await encoding.decoder.bind(stream).fold<dynamic>(
        StringBuffer(), (dynamic buffer, data) => buffer..write(data));
    return HttpBody._('text', buffer.toString());
  }

  Future<HttpBody> asFormData() async {
    var values = await MimeMultipartTransformer(
            contentType.parameters['boundary']!)
        .bind(stream)
        .map((part) =>
            HttpMultipartFormData.parse(part, defaultEncoding: defaultEncoding))
        .map((multipart) async {
      dynamic data;
      if (multipart.isText) {
        var buffer = await multipart.fold<StringBuffer>(
            StringBuffer(), (b, dynamic s) => b..write(s));
        data = buffer.toString();
      } else {
        var buffer = await multipart.fold<typedData.BytesBuilder>(
            typedData.BytesBuilder(), (b, dynamic d) => b..add(d as List<int>));
        data = buffer.takeBytes();
      }
      var filename = multipart.contentDisposition.parameters['filename'];
      if (filename != null) {
        data = HttpBodyFileUpload._(multipart.contentType, filename, data);
      }
      return <dynamic>[multipart.contentDisposition.parameters['name'], data];
    }).toList();
    var parts = await Future.wait(values);
    var map = <String, dynamic>{};
    for (var part in parts) {
      map[part[0] as String] = part[1]; // Override existing entries.
    }
    return HttpBody._('form', map);
  }

  switch (contentType.primaryType) {
    case 'text':
      return asText(defaultEncoding);

    case 'application':
      switch (contentType.subType) {
        case 'json':
          var body = await asText(utf8);
          return HttpBody._('json', jsonDecode(body.body as String));

        case 'x-www-form-urlencoded':
          var body = await asText(ascii);
          var map = Uri.splitQueryString(body.body as String,
              encoding: defaultEncoding);
          var result = <dynamic, dynamic>{};
          for (var key in map.keys) {
            result[key] = map[key];
          }
          return HttpBody._('form', result);

        default:
          break;
      }
      break;

    case 'multipart':
      switch (contentType.subType) {
        case 'form-data':
          return asFormData();

        default:
          break;
      }
      break;

    default:
      break;
  }

  return asBinary();
}
