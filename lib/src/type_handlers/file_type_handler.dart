import 'dart:io';

import '../alfred.dart';
import '../extensions/response_helpers.dart';
import 'type_handler.dart';

TypeHandler get fileTypeHandler =>
    TypeHandler<File>((HttpRequest req, HttpResponse res, dynamic file) async {
      file = file as File;
      if (!file.existsSync()) {
        throw NotFoundError();
      }

      final fileStats = await file.stat();
      final lastModified = fileStats.modified.toUtc();
      final totalSize = fileStats.size;

      // Generate ETag using size and mtime (strong validator)
      final etag = '"${totalSize}_${lastModified.millisecondsSinceEpoch}"';

      // Set common headers
      res.headers.add('accept-ranges', 'bytes');
      res.headers.add('etag', etag);
      res.headers.add('last-modified', HttpDate.format(lastModified));

      // Handle conditional requests (If-Match, If-None-Match, If-Modified-Since, If-Unmodified-Since)
      final ifMatch = req.headers.value('if-match');
      final ifNoneMatch = req.headers.value('if-none-match');
      final ifModifiedSince = req.headers.value('if-modified-since');
      final ifUnmodifiedSince = req.headers.value('if-unmodified-since');

      if (ifMatch != null &&
          ifMatch != '*' &&
          !ifMatch.split(',').map((e) => e.trim()).contains(etag)) {
        res.statusCode = HttpStatus.preconditionFailed;
        return res.close();
      }

      if (ifNoneMatch != null) {
        if (ifNoneMatch == '*' ||
            ifNoneMatch.split(',').map((e) => e.trim()).contains(etag)) {
          if (req.method == 'GET' || req.method == 'HEAD') {
            res.statusCode = HttpStatus.notModified;
            return res.close();
          } else {
            res.statusCode = HttpStatus.preconditionFailed;
            return res.close();
          }
        }
      }

      if (ifModifiedSince != null) {
        try {
          final modifiedSince = HttpDate.parse(ifModifiedSince);
          if (!lastModified.isAfter(modifiedSince)) {
            res.statusCode = HttpStatus.notModified;
            return res.close();
          }
        } catch (_) {
          // Invalid date format, ignore the header
        }
      }

      if (ifUnmodifiedSince != null) {
        try {
          final unmodifiedSince = HttpDate.parse(ifUnmodifiedSince);
          if (lastModified.isAfter(unmodifiedSince)) {
            res.statusCode = HttpStatus.preconditionFailed;
            return res.close();
          }
        } catch (_) {
          // Invalid date format, ignore the header
        }
      }

      final rangeHeader = req.headers.value('range');
      if (rangeHeader == null || !rangeHeader.startsWith('bytes=')) {
        res.setContentTypeFromFile(file);
        await res.addStream(file.openRead());
        return res.close();
      }

      // Check If-Range header (RFC9110 Section 13.1.3)
      final ifRangeHeader = req.headers.value('if-range');
      if (ifRangeHeader != null) {
        bool useRanges = false;
        if (ifRangeHeader.startsWith('"') || ifRangeHeader.startsWith('W/"')) {
          // It's an ETag
          useRanges = ifRangeHeader == etag;
        } else {
          // It's a Last-Modified date
          try {
            final rangeDate = HttpDate.parse(ifRangeHeader);
            useRanges = !lastModified.isAfter(rangeDate);
          } catch (_) {
            useRanges = false;
          }
        }

        if (!useRanges) {
          res.setContentTypeFromFile(file);
          await res.addStream(file.openRead());
          return res.close();
        }
      }

      // Parse range header (format: bytes=range1,range2,...)
      final ranges = rangeHeader
          .substring(6)
          .split(',')
          .map((range) {
            final parts = range.trim().split('-');
            if (parts.length != 2) return null;

            final startStr = parts[0];
            final endStr = parts[1];

            try {
              int? start, end;
              if (startStr.isEmpty) {
                // Suffix range (-500)
                start = totalSize - int.parse(endStr);
                end = totalSize - 1;
                if (start < 0) start = 0;
              } else {
                start = int.parse(startStr);
                end = endStr.isEmpty ? totalSize - 1 : int.parse(endStr);
              }

              // Validate range values
              if (start > end || start < 0 || end >= totalSize) {
                return null;
              }

              return _Range(start, end);
            } catch (e) {
              return null;
            }
          })
          .where((range) => range != null)
          .toList();

      if (ranges.isEmpty) {
        res.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        res.headers.add('content-range', 'bytes */$totalSize');
        return res.close();
      }

      if (ranges.length == 1) {
        // Single range request
        final range = ranges[0]!;
        final contentLength = range.end - range.start + 1;

        res.statusCode = HttpStatus.partialContent;
        res.setContentTypeFromFile(file);
        res.headers.add(
            'content-range', 'bytes ${range.start}-${range.end}/$totalSize');
        res.headers.add('content-length', contentLength.toString());

        await res.addStream(file.openRead(range.start, range.end + 1));
        return res.close();
      } else {
        // Multiple ranges - use multipart/byteranges
        final boundary = 'alfred-${DateTime.now().millisecondsSinceEpoch}';
        res.statusCode = HttpStatus.partialContent;
        res.headers
            .add('content-type', 'multipart/byteranges; boundary=$boundary');

        final contentType =
            res.headers.contentType?.toString() ?? 'application/octet-stream';

        for (final range in ranges) {
          res.write('\r\n--$boundary\r\n');
          res.write('content-type: $contentType\r\n');
          res.write(
              'content-range: bytes ${range!.start}-${range.end}/$totalSize\r\n\r\n');

          await res.addStream(file.openRead(range.start, range.end + 1));
        }

        res.write('\r\n--$boundary--\r\n');
        return res.close();
      }
    });

class _Range {
  final int start;
  final int end;

  _Range(this.start, this.end);
}
