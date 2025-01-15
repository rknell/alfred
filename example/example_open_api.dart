import 'package:alfred/alfred.dart';
import 'package:alfred/src/alfred_openapi.dart';

void main() async {
  final app = Alfred();

  app.get(
    '/path/:param1',
    (req, res) {
      res.json({'key': 'value'});
    },
    middleware: [],
    openAPIDoc: OpenAPIDoc(
      title: 'Title of the endpoint',
      description: 'Description for the endpoint',
      responses: [
        OpenAPIResponse(
          statusCode: 200,
          description: 'Success',
          schema: [
            OpenAPIResponseContent(
              key: 'key',
              type: OpenAPIType.string,
              example: 'value ABC',
            ),
          ],
        ),
      ],
    ),
  );

  app.get('/openapi', (req, res) {
    res.setContentTypeFromExtension('yaml');
    return app.getRoutesSpecifications(
      title: "Test API",
      description: "Test API Description",
      version: "1.2.3",
    );
  });

  await app.listen();
}
