import 'dart:async';
import 'dart:io';

/// CORS Middlware.
///
/// Has some sensible defaults. You probably want to change the origin
///
/// Multiple origin accept [String] [RegExp], [List<String>] and [Function]
///
///  - [Function] must return true or false

FutureOr Function(HttpRequest, HttpResponse) cors({
  int age = 86400,
  String headers = '*',
  String methods = 'POST, GET, OPTIONS, PUT, PATCH, DELETE',
  dynamic origin = '*',
}) {
  return (HttpRequest req, HttpResponse res) {
    final host = req.headers.host;

    String org;

    if (origin is String) {
      org = origin == host ? host! : origin;
    } else if (origin is RegExp) {
      org = RegExp(origin as String).hasMatch(host!) ? host : origin as String;
    } else if (origin is List) {
      org = origin.contains(host) ? host! : origin as String;
    } else if (origin is Function) {
      org = origin.call() ? host! : origin as String;
    } else {
      org = origin;
    }

    res.headers.set('Access-Control-Allow-Origin', org);
    res.headers.set('Access-Control-Allow-Methods', methods);
    res.headers.set('Access-Control-Allow-Headers', headers);
    res.headers.set('Access-Control-Expose-Headers', headers);
    res.headers.set('Access-Control-Max-Age', age);

    if (req.method == 'OPTIONS') {
      res.close();
    }
  };
}
