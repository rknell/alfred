import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();
  app.all('*', (req, res) {
    // Perform action
    req.headers.add('x-custom-header', "Alfred isn't bad");

    /// No need to call next as we don't send a response.
    /// Alfred will find the next matching route
  });

  app.get('/otherFunction', (req, res) {
    //Action performed next
    return {'message': 'complete'};
  });

  await app.listen();
}
