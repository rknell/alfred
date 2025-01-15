import 'package:alfred/alfred.dart';
import 'package:yaml_writer/yaml_writer.dart';

enum OpenAPIType {
  string,
  number,
  integer,
  boolean,
  array,
  object;

  String toJson() {
    return toString().split('.').last;
  }
}

enum OpenAPIContentType {
  object,
  array;

  String toJson() {
    return toString().split('.').last;
  }
}

/// Extension to generate OpenAPI specifications for the routes in the Alfred app
extension AlfredOpenAPI on Alfred {
  /// Returns the OpenAPI specifications for the routes in the Alfred app
  /// - [title] is the title of the API
  /// - [description] is the description of the API
  /// - [version] is the version of the API
  String getRoutesSpecifications(
      {String? title, String? description, String? version}) {
    var specsYaml = YamlWriter();
    Map<String, dynamic> specs = {
      'openapi': '3.0.0',
      'info': {
        'title': title ?? 'API',
        'description': description ?? 'API Description',
        'version': version ?? '1.0.0'
      },
      'paths': [],
    };
    for (var route in routes) {
      String methodString = route.method.name;
      var routeParameters = <Map<String, dynamic>>[];

      for (var parameter in route.params) {
        routeParameters.add({
          'name': parameter.name,
          'in': 'query',
          'required': true,
          'schema': {'type': parameter.type?.name ?? 'string'}
        });
      }

      (specs['paths'] as List).add({
        route.route: {
          methodString: {
            'summary': route.openAPIDoc?.title ?? 'Summary',
            if (route.openAPIDoc?.description != null)
              'description': route.openAPIDoc!.description,
            'parameters': routeParameters,
            'responses': {
              if (route.openAPIDoc?.responses != null)
                for (var response in route.openAPIDoc!.responses)
                  ...response.toJson(),
              if (route.openAPIDoc?.responses == null ||
                  route.openAPIDoc!.responses.isEmpty)
                '200': {
                  'description': 'Success',
                }
            }
          }
        }
      });
    }

    return specsYaml.write(specs).replaceAll('- /', '/');
  }
}

/// Class to define the OpenAPI documentation
class OpenAPIDoc {
  final String title;
  final String? description;
  final List<OpenAPIResponse> responses;

  OpenAPIDoc({
    required this.title,
    this.description,
    required this.responses,
  });
}

/// Class to define the OpenAPI response
class OpenAPIResponse {
  final int statusCode;
  final String? description;
  final String contentType;
  final OpenAPIContentType content;
  final List<OpenAPIResponseContent> schema;

  OpenAPIResponse({
    required this.statusCode,
    this.description,
    this.contentType = 'application/json',
    this.content = OpenAPIContentType.object,
    required this.schema,
  });

  Map<String, dynamic> toJson() {
    return {
      '$statusCode': {
        'description': description,
        'content': {
          contentType: {
            'schema': {
              'type': content.toJson(),
              if (content == OpenAPIContentType.object)
                'properties': {
                  for (var item in schema) ...item.toJson(),
                },
              if (content == OpenAPIContentType.array)
                'items': {
                  'type': schema.first.type.toJson(),
                  if (schema.first.example != null)
                    'example': schema.first.example,
                },
            },
          },
        },
      }
    };
  }
}

/// Class to define the OpenAPI response content
class OpenAPIResponseContent {
  final String key;
  final OpenAPIType type;
  final dynamic example;

  OpenAPIResponseContent({
    required this.key,
    required this.type,
    this.example,
  });

  Map<String, dynamic> toJson() {
    return {
      key: {
        'type': type.toJson(),
        if (example != null) 'example': example,
      }
    };
  }
}
