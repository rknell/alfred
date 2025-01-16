import 'types.dart';

/// Class to define the OpenAPI schema
class OpenAPISchema {
  final String type;
  final Map<String, OpenAPISchema>? properties;
  final OpenAPISchema? items;
  final dynamic example;
  final String? description;
  final bool? required;
  final String? format;

  const OpenAPISchema({
    required this.type,
    this.properties,
    this.items,
    this.example,
    this.description,
    this.required,
    this.format,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        if (properties != null)
          'properties': {
            for (var entry in properties!.entries)
              entry.key: entry.value.toJson(),
          },
        if (items != null) 'items': items!.toJson(),
        if (example != null) 'example': example,
        if (description != null) 'description': description,
        if (required != null) 'required': required,
        if (format != null) 'format': format,
      };
}

/// Class to define the OpenAPI documentation for a route
class OpenAPIDoc {
  final String summary;
  final String? description;
  final List<OpenAPIResponse> responses;
  final OpenAPIRequestBody? requestBody;
  final List<OpenAPIParameter>? parameters;
  final Map<String, OpenAPISchema>? components;
  final List<String>? tags;

  const OpenAPIDoc({
    required this.summary,
    this.description,
    required this.responses,
    this.requestBody,
    this.parameters,
    this.components,
    this.tags,
  });

  Map<String, dynamic> toJson() => {
        'summary': summary,
        if (description != null) 'description': description,
        'responses': {
          for (var response in responses) ...response.toJson(),
        },
        if (requestBody != null) 'requestBody': requestBody!.toJson(),
        if (parameters != null)
          'parameters': parameters!.map((p) => p.toJson()).toList(),
        if (tags != null) 'tags': tags,
      };
}

/// Class to define the OpenAPI request body
class OpenAPIRequestBody {
  final String? description;
  final Map<String, OpenAPIMediaType> content;
  final bool required;

  const OpenAPIRequestBody({
    this.description,
    required this.content,
    this.required = false,
  });

  Map<String, dynamic> toJson() => {
        if (description != null) 'description': description,
        'content': {
          for (var entry in content.entries) entry.key: entry.value.toJson(),
        },
        'required': required,
      };
}

/// Class to define the OpenAPI media type
class OpenAPIMediaType {
  final OpenAPISchema schema;
  final dynamic example;
  final Map<String, dynamic>? examples;
  final Map<String, dynamic>? encoding;

  const OpenAPIMediaType({
    required this.schema,
    this.example,
    this.examples,
    this.encoding,
  });

  Map<String, dynamic> toJson() => {
        'schema': schema.toJson(),
        if (example != null) 'example': example,
        if (examples != null) 'examples': examples,
        if (encoding != null) 'encoding': encoding,
      };
}

/// Class to define the OpenAPI response
class OpenAPIResponse {
  final int statusCode;
  final String description;
  final Map<String, OpenAPIMediaType>? content;
  final Map<String, OpenAPIHeader>? headers;

  const OpenAPIResponse({
    required this.statusCode,
    required this.description,
    this.content,
    this.headers,
  });

  Map<String, dynamic> toJson() => {
        '$statusCode': {
          'description': description,
          if (content != null)
            'content': {
              for (var entry in content!.entries)
                entry.key: entry.value.toJson(),
            },
          if (headers != null)
            'headers': {
              for (var entry in headers!.entries)
                entry.key: entry.value.toJson(),
            },
        },
      };
}

/// Class to define the OpenAPI header
class OpenAPIHeader {
  final String? description;
  final bool required;
  final bool deprecated;
  final bool allowEmptyValue;
  final OpenAPISchema schema;

  const OpenAPIHeader({
    this.description,
    this.required = false,
    this.deprecated = false,
    this.allowEmptyValue = false,
    required this.schema,
  });

  Map<String, dynamic> toJson() => {
        if (description != null) 'description': description,
        'required': required,
        'deprecated': deprecated,
        'allowEmptyValue': allowEmptyValue,
        'schema': schema.toJson(),
      };
}
