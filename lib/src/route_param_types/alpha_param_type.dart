import 'http_route_param_type.dart';

class AlphaParamType implements HttpRouteParamType {
  @override
  final String name = 'alpha';

  @override
  final String pattern = r'[0-9a-z_]+';

  @override
  String parse(String value) => value;
}
