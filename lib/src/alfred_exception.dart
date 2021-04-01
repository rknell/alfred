/// Throw these exceptions to bubble up an error from sub functions and have them
/// handled automatically for the client
class AlfredException implements Exception {
  /// The response to send to the client
  ///
  final Object? response;

  /// The statusCode to send to the client
  ///
  final int statusCode;

  AlfredException(this.statusCode, this.response);
}
