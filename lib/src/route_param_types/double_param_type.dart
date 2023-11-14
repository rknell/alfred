import 'http_route_param_type.dart';

class DoubleParamType implements HttpRouteParamType {
  @override
  final String name = 'double';

  @override
  final String pattern = r'-?\d+(?:\.\d+)?';

  @override
  double parse(String value) => double.parse(value);
}
