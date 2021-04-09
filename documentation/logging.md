# Logging

Alfred is able to lower the log level or to integrate in a third-party
logging solution.

## Log level

While developing, you can set the log level to "debug" to uncover
more details on the request processing.

```dart
import 'dart:io';

import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred(logLevel: LogType.debug);

  app.get('/static/*', (req, res) => Directory('path/to/files'));

  await app.listen();
}
```


## Custom logging

You can integrate Alfred's logging into any third party logging
solutions or create your own.

Here is an example integrating with [dart.dev logging package](https://pub.dev/packages/logging):

```dart
import 'package:alfred/alfred.dart';
import 'package:logging/logging.dart';

// Use 'logging' package instead of default logger

void main() {
  var app = Alfred();

  // Configure root logger
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Create logger for Alfred app
  var log = Logger('HttpServer');

  // Create custom logWriter and map to logging package
  app.logWriter = (messageFn, type) {
    switch (type) {
      case LogType.debug:
        // avoid evaluating too much debug messages
        if (log.level <= Level.FINE) {
          log.fine(messageFn());
        }
        break;
      case LogType.info:
        log.info(messageFn());
        break;
      case LogType.warn:
        log.warning(messageFn());
        break;
      case LogType.error:
        log.severe(messageFn());
        break;
    }
  };

  // Configure routing...
  app.get('/resource', (req, res) => 'response');

  app.listen();
}
```