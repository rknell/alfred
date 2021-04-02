import 'package:alfred/alfred.dart';

final _store = <String, Map<String, dynamic>>{};

extension StorePlugin on HttpRequest {
  void setStoreValue(String key, dynamic value) {
    _store[requestId] ??= <String, dynamic>{};
    _store[requestId]![key] = value;
  }

  dynamic getStoreValue(String key) => (_store[requestId])?[key];
}

extension StorePluginData on Alfred {
  List<String> get storeOutstandingRequests => _store.keys.toList();
}

void storePluginOnDoneHandler(HttpRequest req, HttpResponse res) {
  _store.remove(req.requestId);
}
