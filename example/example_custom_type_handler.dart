import 'package:alfred/alfred.dart';

class Chicken {
  String get response => 'I am a chicken';
}

void main() {
  final app = Alfred();

  app.typeHandlers.add(TypeHandler<Chicken>((req, res, Chicken val) async {
    res.write(val.response);
    await res.close();
  }));

  /// The app will now return the Chicken.response if you return one from a route

  app.get('/kfc', (req, res) => Chicken()); //I am a chicken;

  app.listen(); //Listening on 3000
}
