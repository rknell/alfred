import 'dart:io';

cors(
    {int age = 86400,
    String headers = "Content-Type",
    String methods = "POST, GET, OPTIONS, PUT, PATCH",
    String origin = "*"}) {
  return (HttpRequest req, HttpResponse res) {
    res.headers.set("Access-Control-Allow-Origin", origin);
    res.headers.set("Access-Control-Allow-Methods", methods);
    res.headers.set("Access-Control-Allow-Headers", headers);
    res.headers.set("Access-Control-Max-Age", age);
  };
}
