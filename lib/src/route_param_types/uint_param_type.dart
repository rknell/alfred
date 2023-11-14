import 'http_route_param_type.dart';

class UintParamType implements HttpRouteParamType {
  @override
  final String name = 'uint';

  @override
  final String pattern = r'\d+';

  @override
  int parse(String value) => int.parse(value);
}
