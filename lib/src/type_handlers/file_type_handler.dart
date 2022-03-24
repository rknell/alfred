import 'dart:io';

import 'package:angel3_range_header/angel3_range_header.dart';
import 'package:mime_type/mime_type.dart';

import '../alfred.dart';
import '../extensions/response_helpers.dart';
import 'type_handler.dart';

TypeHandler get fileTypeHandler =>
    TypeHandler<File>((HttpRequest req, HttpResponse res, File file) async {
      if (file.existsSync()) {
        res.headers.add('accept-ranges', 'bytes');

        if (req.headers.value('range')?.startsWith('bytes=') != true) {
          res.setContentTypeFromFile(file);
          await res.addStream(file.openRead());
          return res.close();
        } else {
          var header = RangeHeader.parse(req.headers.value('range')!);
          final items = RangeHeader.foldItems(header.items);
          var totalFileSize = await file.length();
          header = RangeHeader(items);

          for (var item in header.items) {
            var invalid = false;

            if (item.start != -1) {
              invalid = item.end != -1 && item.end < item.start;
            } else {
              invalid = item.end == -1;
            }

            if (invalid) {
              res.statusCode = 416;
              res.write('416 Semantically invalid, or unbounded range.');
              return res.close();
            }

            if (item.end >= totalFileSize) {
              res.setContentTypeFromFile(file);
              await res.addStream(file.openRead());
              return res.close();
            }

            // Ensure it's within range.
            if (item.start >= totalFileSize || item.end >= totalFileSize) {
              res.statusCode = 416;
              res.write('416 Given range $item is out of bounds.');
              return res.close();
            }
          }

          if (header.items.isEmpty) {
            res.statusCode = 416;
            res.write('416 `Range` header may not be empty.');
            return res.close();
          } else if (header.items.length == 1) {
            var item = header.items[0];
            Stream<List<int>> stream;
            var len = 0;

            var total = totalFileSize;

            if (item.start == -1) {
              if (item.end == -1) {
                len = total;
                stream = file.openRead();
              } else {
                len = item.end + 1;
                stream = file.openRead(0, item.end + 1);
              }
            } else {
              if (item.end == -1) {
                len = total - item.start;
                stream = file.openRead(item.start);
              } else {
                len = item.end - item.start + 1;
                stream = file.openRead(item.start, item.end + 1);
              }
            }

            res.setContentTypeFromFile(file);

            res.statusCode = 206;
            res.headers.add('content-length', len.toString());
            res.headers.add(
              'content-range',
              'bytes ' + item.toContentRange(total),
            );
            await stream.cast<List<int>>().pipe(res);
            return res.close();
          } else {
            var transformer = RangeHeaderTransformer(
              header,
              mime(file.path) ?? 'application/octet-stream',
              await file.length(),
            );

            res.statusCode = 206;
            res.headers.add(
              'content-length',
              transformer.computeContentLength(totalFileSize).toString(),
            );

            res.headers.contentType = ContentType(
              'multipart',
              'byteranges',
              parameters: {
                'boundary': transformer.boundary,
              },
            );
            await file
                .openRead()
                .cast<List<int>>()
                .transform(transformer)
                .pipe(res);

            return res.close();
          }
        }
      } else {
        throw NotFoundError();
      }
    });
