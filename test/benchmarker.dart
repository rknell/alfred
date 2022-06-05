import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:queue/queue.dart';

void main() async {
  final stopwatch = Stopwatch()..start();
  final queue = Queue(parallel: 500);
  for (var i = 0; i < 10000; i++) {
    unawaited(queue.add(
        () => http.get(Uri.parse('http://localhost:3000/files/dummy.pdf'))));
  }
  await queue.onComplete;
  print(stopwatch.elapsed);
}
