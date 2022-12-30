import 'package:alfred/alfred.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../common.dart';

void main() {
  late Alfred app;
  late int port;

  setUp(() async {
    app = Alfred();
    port = await app.listenForTest();
  });

  tearDown(() => app.close());

  test('it uses the serializable helper correctly', () async {
    app.get('/testSerializable1', (req, res) async {
      return _SerializableObjType1();
    });
    app.get('/testSerializable2', (req, res) async {
      return _SerializableObjType1();
    });
    app.get('/testNoSerialize', (req, res) async {
      return _NonSerializableObj();
    });
    final response1 =
        await http.get(Uri.parse('http://localhost:$port/testSerializable1'));
    expect(response1.body, '{"test":true}');

    final response2 =
        await http.get(Uri.parse('http://localhost:$port/testSerializable2'));
    expect(response2.body, '{"test":true}');

    final response3 =
        await http.get(Uri.parse('http://localhost:$port/testNoSerialize'));
    expect(response3.statusCode, 500);
    expect(response3.body.contains('_NonSerializableObj'), true);
  });

  test('it sets the mime type correctly for serializable types', () async {
    app.get('/testSerializable1', (req, res) async {
      return _SerializableObjType1();
    });
    app.get('/testSerializable2', (req, res) async {
      return _SerializableObjType1();
    });
    app.get('/testNoSerialize', (req, res) async {
      return _NonSerializableObj();
    });

    final response1 =
        await http.get(Uri.parse('http://localhost:$port/testSerializable1'));
    expect(
      response1.headers['content-type'],
      'application/json; charset=utf-8',
    );

    final response2 =
        await http.get(Uri.parse('http://localhost:$port/testSerializable2'));
    expect(
      response2.headers['content-type'],
      'application/json; charset=utf-8',
    );

    final response3 =
        await http.get(Uri.parse('http://localhost:$port/testNoSerialize'));
    expect(
      response3.headers['content-type'],
      isNot('application/json; charset=utf-8'),
    );
  });
}

class _SerializableObjType1 {
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'test': true};
  }
}

class _NonSerializableObj {}
