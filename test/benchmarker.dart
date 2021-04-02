import 'package:http/http.dart' as http;

void main() async {
  final stopwatch = Stopwatch()..start();
  final actions = <Future>[];
  for (var i = 0; i < 1000; i++) {
    actions.add(http.get(Uri.parse('http://localhost:12345/files/dummy.pdf')));
  }
  await Future.wait<void>(actions);
  print(stopwatch.elapsed);
}
