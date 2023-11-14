import 'http_route_param_type.dart';

class UuidParamType implements HttpRouteParamType {
  @override
  final String name = 'uuid';

  @override
  final String pattern =
      r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}';

  @override
  String parse(String value) {
    // Dart does not have a builtin Uuid or Guid type
    // no effort is made to ensure UUID conforms to RFC4122
    return value;
  }
}
