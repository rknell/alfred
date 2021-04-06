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
        log.fine(messageFn());
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

  app.listen();
}
