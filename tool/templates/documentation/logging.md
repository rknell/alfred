# Logging

Alfred is able to lower the log level or to integrate in a third-party
logging solution.

## Log level

While developing, you can set the log level to "debug" to uncover
more details on the request processing.

@code example/example_log_level.dart


## Custom logging

You can integrate Alfred's logging into any third party logging
solutions or create your own.

Here is an example integrating with [dart.dev logging package](https://pub.dev/packages/logging):

@code example/example_custom_logging.dart
