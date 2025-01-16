import 'package:alfred/src/http_route.dart';
import 'package:yaml_writer/yaml_writer.dart';

import 'schema.dart';
import 'types.dart';

/// Extension to generate OpenAPI specifications for the routes in the Alfred app
extension OpenAPIGenerator on HttpRoute {
  /// Converts an Alfred route path to an OpenAPI path
  /// Example: '/users/:id' -> '/users/{id}'
  String _convertRouteToOpenAPIPath(String route) {
    final regex = RegExp(r':(\w+)');
    return route.replaceAllMapped(regex, (match) => '{${match.group(1)}}');
  }

  /// Returns the OpenAPI specification for this route
  String getOpenAPISpec() {
    var specsYaml = YamlWriter();
    Map<String, dynamic> specs = {
      'openapi': '3.0.0',
      'info': {
        'title': openAPIDoc?.summary ?? 'API',
        'description': openAPIDoc?.description ?? 'API Description',
        'version': '1.0.0'
      },
      'paths': {},
    };

    String methodString = method.name.toLowerCase();
    String openAPIPath = _convertRouteToOpenAPIPath(route);

    // Extract path parameters from route
    var pathParameters = params.map((param) => OpenAPIParameter(
          name: param.name,
          in_: OpenAPIParameterLocation.path,
          required: true,
          schema: OpenAPISchema(
            type: 'string',
            description: 'Path parameter: ${param.name}',
          ),
        ));

    // Combine path parameters with any additional parameters from OpenAPIDoc
    var allParameters = [
      ...pathParameters,
      ...(openAPIDoc?.parameters ?? []),
    ];

    var pathSpec = {
      methodString: {
        'summary': openAPIDoc?.summary ?? 'Summary',
        if (openAPIDoc?.description != null)
          'description': openAPIDoc!.description,
        if (openAPIDoc?.tags != null) 'tags': openAPIDoc!.tags,
        if (allParameters.isNotEmpty)
          'parameters': allParameters.map((p) => p.toJson()).toList(),
        'responses': {
          if (openAPIDoc?.responses != null)
            for (var response in openAPIDoc!.responses) ...response.toJson(),
          if (openAPIDoc?.responses == null || openAPIDoc!.responses.isEmpty)
            '200': {
              'description': 'Success',
            }
        },
        if (openAPIDoc?.requestBody != null)
          'requestBody': openAPIDoc!.requestBody!.toJson(),
      }
    };

    specs['paths'][openAPIPath] = pathSpec;

    // Add components if they exist
    if (openAPIDoc?.components != null) {
      specs['components'] = {
        'schemas': {
          for (var entry in openAPIDoc!.components!.entries)
            entry.key: entry.value.toJson(),
        }
      };
    }

    return specsYaml.write(specs);
  }
}
