import 'package:alfred/alfred.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('OpenAPI Generator', () {
    late Alfred app;

    setUp(() {
      app = Alfred();
    });

    test('converts route parameters to OpenAPI format', () {
      app.get('/users/:id', (req, res) => null,
          openAPIDoc: OpenAPIDoc(
            summary: 'Get User',
            description: 'Get a user by ID',
            responses: [
              OpenAPIResponse(
                statusCode: 200,
                description: 'Success',
                content: {
                  'application/json': OpenAPIMediaType(
                    schema: OpenAPISchema(
                      type: 'object',
                      properties: {
                        'id': OpenAPISchema(
                          type: 'string',
                          example: '123',
                          description: 'The user ID',
                        ),
                        'name': OpenAPISchema(
                          type: 'string',
                          example: 'John Doe',
                          description: 'The user\'s full name',
                        ),
                      },
                    ),
                  ),
                },
              ),
            ],
          ));

      final route = app.routes.first;
      final spec = route.getOpenAPISpec();
      final yaml = loadYaml(spec);

      print('\nDebug path access:');
      print('paths: ${yaml['paths']}');
      print('users/{id}: ${yaml['paths']['/users/{id}']}');
      print('get: ${yaml['paths']['/users/{id}']['get']}');
      print('responses: ${yaml['paths']['/users/{id}']['get']['responses']}');

      // Check path structure
      expect(yaml['paths'], isNotNull, reason: 'paths should exist');
      expect(yaml['paths']['/users/{id}'], isNotNull,
          reason: '/users/{id} path should exist');

      final path = yaml['paths']['/users/{id}']['get'];
      expect(path, isNotNull, reason: 'GET method should exist');
      expect(path['summary'], equals('Get User'));
      expect(path['description'], equals('Get a user by ID'));

      // Check parameters
      expect(path['parameters'], isNotNull, reason: 'parameters should exist');
      final parameters = path['parameters'] as List;
      expect(parameters, hasLength(1));

      final param = parameters.first;
      expect(param['name'], equals('id'));
      expect(param['in'], equals('path'));
      expect(param['required'], isTrue);
      expect(param['deprecated'], isFalse);
      expect(param['allowEmptyValue'], isFalse);
      expect(param['schema']['type'], equals('string'));

      // Check response structure
      expect(path['responses'], isNotNull, reason: 'responses should exist');
      final responses = path['responses'] as Map;
      print('Response keys: ${responses.keys}'); // Debug print
      print('Response type: ${responses.runtimeType}'); // Debug print

      // Convert YAML keys to strings for comparison
      final responseKeys = responses.keys.map((k) => k.toString()).toList();
      expect(responseKeys.contains('200'), isTrue,
          reason: '200 response should exist');

      final response = responses[responses.keys.first] as Map;
      expect(response['description'], equals('Success'));
      expect(response['content'], isNotNull);
      expect(response['content']['application/json'], isNotNull);

      final schema = response['content']['application/json']['schema'] as Map;
      expect(schema['type'], equals('object'));
      expect(schema['properties'], isNotNull);
      expect(schema['properties']['id']['type'], equals('string'));
      expect(schema['properties']['id']['example'], equals('123'));
      expect(schema['properties']['name']['type'], equals('string'));
      expect(schema['properties']['name']['example'], equals('John Doe'));
    });

    test('includes request body in OpenAPI spec', () {
      app.post(
        '/users',
        (req, res) => null,
        openAPIDoc: OpenAPIDoc(
          summary: 'Create User',
          description: 'Create a new user',
          responses: [
            OpenAPIResponse(
              statusCode: 201,
              description: 'User created',
              content: {
                'application/json': OpenAPIMediaType(
                  schema: OpenAPISchema(
                    type: 'object',
                    properties: {
                      'id': OpenAPISchema(
                        type: 'string',
                        description: 'The created user ID',
                      ),
                    },
                  ),
                ),
              },
            ),
          ],
          requestBody: OpenAPIRequestBody(
            description: 'User data',
            required: true,
            content: {
              'application/json': OpenAPIMediaType(
                schema: OpenAPISchema(
                  type: 'object',
                  properties: {
                    'name': OpenAPISchema(
                      type: 'string',
                      description: 'The user\'s full name',
                      example: 'John Doe',
                    ),
                    'email': OpenAPISchema(
                      type: 'string',
                      description: 'The user\'s email address',
                      format: 'email',
                      example: 'john@example.com',
                    ),
                  },
                ),
              ),
            },
          ),
        ),
      );

      final route = app.routes.first;
      final spec = route.getOpenAPISpec();
      final yaml = loadYaml(spec);

      expect(yaml['paths']['/users']['post']['requestBody'], isNotNull);
      expect(
          yaml['paths']['/users']['post']['requestBody']['required'], isTrue);
      expect(
          yaml['paths']['/users']['post']['requestBody']['content']
              ['application/json']['schema']['properties']['name'],
          isNotNull);
      expect(
          yaml['paths']['/users']['post']['requestBody']['content']
              ['application/json']['schema']['properties']['email'],
          isNotNull);
    });

    test('includes query parameters in OpenAPI spec', () {
      app.get(
        '/search',
        (req, res) => null,
        openAPIDoc: OpenAPIDoc(
          summary: 'Search',
          description: 'Search for items',
          responses: [
            OpenAPIResponse(
              statusCode: 200,
              description: 'Success',
              content: {
                'application/json': OpenAPIMediaType(
                  schema: OpenAPISchema(
                    type: 'array',
                    items: OpenAPISchema(
                      type: 'string',
                      example: 'item1',
                    ),
                  ),
                ),
              },
            ),
          ],
          parameters: [
            OpenAPIParameter(
              name: 'q',
              in_: OpenAPIParameterLocation.query,
              description: 'Search query',
              required: true,
              schema: OpenAPISchema(
                type: 'string',
                example: 'search term',
              ),
            ),
            OpenAPIParameter(
              name: 'limit',
              in_: OpenAPIParameterLocation.query,
              description: 'Maximum number of results',
              schema: OpenAPISchema(
                type: 'integer',
                example: 10,
              ),
            ),
          ],
        ),
      );

      final route = app.routes.first;
      final spec = route.getOpenAPISpec();
      final yaml = loadYaml(spec);

      expect(yaml['paths']['/search']['get']['parameters'], hasLength(2));
      expect(yaml['paths']['/search']['get']['parameters'][0]['name'],
          equals('q'));
      expect(yaml['paths']['/search']['get']['parameters'][0]['in'],
          equals('query'));
      expect(
          yaml['paths']['/search']['get']['parameters'][0]['required'], isTrue);
      expect(yaml['paths']['/search']['get']['parameters'][1]['name'],
          equals('limit'));
    });

    test('includes components in OpenAPI spec', () {
      final userSchema = OpenAPISchema(
        type: 'object',
        properties: {
          'id': OpenAPISchema(type: 'string'),
          'name': OpenAPISchema(type: 'string'),
        },
      );

      app.get(
        '/users',
        (req, res) => null,
        openAPIDoc: OpenAPIDoc(
          summary: 'List Users',
          description: 'List all users',
          responses: [
            OpenAPIResponse(
              statusCode: 200,
              description: 'Success',
              content: {
                'application/json': OpenAPIMediaType(
                  schema: OpenAPISchema(
                    type: 'array',
                    items: userSchema,
                  ),
                ),
              },
            ),
          ],
          components: {
            'User': userSchema,
          },
        ),
      );

      final route = app.routes.first;
      final spec = route.getOpenAPISpec();
      final yaml = loadYaml(spec);

      expect(yaml['components'], isNotNull);
      expect(yaml['components']['schemas']['User'], isNotNull);
      expect(yaml['components']['schemas']['User']['type'], equals('object'));
      expect(
          yaml['components']['schemas']['User']['properties']['id'], isNotNull);
      expect(yaml['components']['schemas']['User']['properties']['name'],
          isNotNull);
    });
  });
}
