/// Throw these exceptions to bubble up an error from sub functions and have them
/// handled automatically for the client
class AlfredException implements Exception {
  /// The response to send to the client
  ///
  Object? response;

  /// The statusCode to send to the client
  ///
  int statusCode;

  AlfredException(this.statusCode, this.response);
}

class BodyParserException implements AlfredException {
  @override
  Object? response;

  @override
  int statusCode;

  final Object exception;
  final StackTrace stacktrace;

  BodyParserException(
      {this.statusCode = 400,
      this.response = 'Bad Request',
      required this.exception,
      required this.stacktrace});
}
