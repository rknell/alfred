import 'dart:math';

import 'package:alfred/alfred.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

main() {
  late Alfred app;
  late int port;

  setUp(() async {
    port = Random().nextInt(65535 - 1024) + 1024;
    app = Alfred();
    await app.listen(port);
  });

  tearDown(() async {
    await app.close();
  });

  test("it should store and retrieve a value on a request", () async {
    bool didHit = false;
    app.all("/test", (req, res) {
      expect(req.route, "/test");
      req.setStoreValue("testValue", "bah!");
      expect(req.getStoreValue("testValue"), "bah!");
      didHit = true;
      return "done";
    });
    await http.get(Uri.parse("http://localhost:$port/test"));
    expect(didHit, true);
  });

  test("it handles an on done listener and cleans up the store", () async {
    var hitCount = 0;
    final listener = app.registerOnDoneListener((req, res) {
      hitCount++;
    });

    app.get("/test", (req, res) => "done");
    await http.get(Uri.parse("http://localhost:$port/test"));
    expect(hitCount, 1);
    app.removeOnDoneListener(listener);
    await http.get(Uri.parse("http://localhost:$port/test"));
    expect(hitCount, 1);
    expect(app.storeOutstandingRequests.isEmpty, true);
  });

  test("the store is correctly available across multiple routes", () async {
    var didHit = false;
    app.get("*", (req, res) {
      req.setStoreValue("userid", "123456");
    });
    app.get("/user", (req, res) {
      didHit = true;
      expect(req.getStoreValue("userid"), "123456");
    });
    await http.get(Uri.parse("http://localhost:$port/user"));
    expect(didHit, true);
  });
}
