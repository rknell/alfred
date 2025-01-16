import 'schema.dart';

/// OpenAPI schema types
enum OpenAPIType {
  string('string'),
  number('number'),
  integer('integer'),
  boolean('boolean'),
  array('array'),
  object('object');

  final String value;
  const OpenAPIType(this.value);

  @override
  String toString() => value;
}

/// OpenAPI parameter locations
enum OpenAPIParameterLocation {
  query('query'),
  header('header'),
  path('path'),
  cookie('cookie');

  final String value;
  const OpenAPIParameterLocation(this.value);

  @override
  String toString() => value;
}

/// OpenAPI parameter styles
enum OpenAPIParameterStyle {
  form('form'),
  simple('simple'),
  label('label'),
  matrix('matrix'),
  spaceDelimited('spaceDelimited'),
  pipeDelimited('pipeDelimited'),
  deepObject('deepObject');

  final String value;
  const OpenAPIParameterStyle(this.value);

  @override
  String toString() => value;
}

/// Class to define parameter metadata for OpenAPI
class OpenAPIParameter {
  final String name;
  final OpenAPIParameterLocation in_;
  final String? description;
  final bool required;
  final bool deprecated;
  final bool allowEmptyValue;
  final OpenAPIParameterStyle? style;
  final bool? explode;
  final bool? allowReserved;
  final OpenAPISchema schema;
  final dynamic example;
  final Map<String, dynamic>? examples;

  const OpenAPIParameter({
    required this.name,
    required this.in_,
    this.description,
    this.required = false,
    this.deprecated = false,
    this.allowEmptyValue = false,
    this.style,
    this.explode,
    this.allowReserved,
    required this.schema,
    this.example,
    this.examples,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'in': in_.toString(),
        if (description != null) 'description': description,
        'required': required,
        'deprecated': deprecated,
        'allowEmptyValue': allowEmptyValue,
        if (style != null) 'style': style.toString(),
        if (explode != null) 'explode': explode,
        if (allowReserved != null) 'allowReserved': allowReserved,
        'schema': schema.toJson(),
        if (example != null) 'example': example,
        if (examples != null) 'examples': examples,
      };
}
