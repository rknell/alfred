import 'dart:io';
import 'package:alfred/alfred.dart';

void main() async {
  final app = Alfred();

  // Define reusable components
  final userSchema = OpenAPISchema(
    type: 'object',
    properties: {
      'id': OpenAPISchema(type: 'string', description: 'The user ID'),
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
      'age': OpenAPISchema(
        type: 'integer',
        description: 'The user\'s age',
        example: 30,
      ),
    },
  );

  final errorSchema = OpenAPISchema(
    type: 'object',
    properties: {
      'error': OpenAPISchema(
        type: 'string',
        description: 'Error message',
      ),
      'code': OpenAPISchema(
        type: 'integer',
        description: 'Error code',
      ),
    },
  );

  // Example route with path parameter
  app.get(
    '/users/:id',
    (req, res) async {
      final id = req.params['id'];
      res.json({'id': id, 'name': 'John Doe'});
    },
    openAPIDoc: OpenAPIDoc(
      summary: 'Get User',
      description: 'Get a user by their ID',
      tags: ['Users'],
      responses: [
        OpenAPIResponse(
          statusCode: 200,
          description: 'Success',
          content: {
            'application/json': OpenAPIMediaType(
              schema: userSchema,
            ),
          },
        ),
        OpenAPIResponse(
          statusCode: 404,
          description: 'User not found',
          content: {
            'application/json': OpenAPIMediaType(
              schema: errorSchema,
              example: {
                'error': 'User not found',
                'code': 404,
              },
            ),
          },
        ),
      ],
      components: {
        'User': userSchema,
        'Error': errorSchema,
      },
    ),
  );

  // Example route with request body and query parameters
  app.post(
    '/users',
    (req, res) async {
      final body = await req.body as Map<String, dynamic>;
      final role = req.uri.queryParameters['role'];
      res.json({'id': '123', ...?body});
    },
    openAPIDoc: OpenAPIDoc(
      summary: 'Create User',
      description: 'Create a new user',
      tags: ['Users'],
      parameters: [
        OpenAPIParameter(
          name: 'role',
          in_: OpenAPIParameterLocation.query,
          description: 'The user\'s role',
          schema: OpenAPISchema(
            type: 'string',
            example: 'admin',
          ),
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
                'age': OpenAPISchema(
                  type: 'integer',
                  description: 'The user\'s age',
                  example: 30,
                ),
              },
            ),
          ),
        },
      ),
      responses: [
        OpenAPIResponse(
          statusCode: 201,
          description: 'User created successfully',
          content: {
            'application/json': OpenAPIMediaType(
              schema: userSchema,
            ),
          },
          headers: {
            'Location': OpenAPIHeader(
              description: 'URL of the created user',
              schema: OpenAPISchema(
                type: 'string',
                format: 'uri',
              ),
            ),
          },
        ),
        OpenAPIResponse(
          statusCode: 400,
          description: 'Invalid request data',
          content: {
            'application/json': OpenAPIMediaType(
              schema: errorSchema,
            ),
          },
        ),
      ],
    ),
  );

  // Serve OpenAPI documentation
  app.get('/openapi', (req, res) {
    res.headers.contentType = ContentType.json;
    final specs = app.routes.map((route) => route.getOpenAPISpec()).join('\n');
    return specs;
  });

  print('Server running on http://localhost:3000');
  await app.listen(3000);
}
