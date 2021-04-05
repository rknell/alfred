import 'package:alfred/alfred.dart';

/// Data structure to keep all request-related data
final storePluginData = <HttpRequest, RequestStore>{};

/// Integrates [RequestStore] mechanism on [HttpRequest]
extension StorePlugin on HttpRequest {
  /// Returns the [RequestStore] dedicated to this request.
  RequestStore get store {
    storePluginData[this] ??= RequestStore();
    return storePluginData[this]!;
  }
}

/// Key-Value-Store for reading and writing request-related data
class RequestStore {
  final _data = <String, dynamic>{};

  /// Stores a [value] associated with a specified [key].
  ///
  /// Example:
  /// ```dart
  /// req.store.set('foo', Foo());
  /// ```
  void set(String key, dynamic value) => _data[key] = value;

  /// Returns the stored value that has been associated with the specified [key].
  /// Returns `null` if no value has been written.
  ///
  /// Example:
  /// ```dart
  /// var foo = req.store.get<Foo>('foo');
  /// ```
  T get<T>(String key) {
    assert(_data[key] is T, 'Store value for key $key does not match type $T');
    return _data[key] as T;
  }
}

/// Used within [Alfred] to remove request-related data after
/// the request has been resolved.
void storePluginOnDoneHandler(HttpRequest req, HttpResponse res) {
  storePluginData.remove(req);
}
