import 'http_route_param_type.dart';

class IntParamType implements HttpRouteParamType {
  @override
  final String name = 'int';

  @override
  final String pattern = r'-?\d+';

  @override
  int parse(String value) => int.parse(value);
}
