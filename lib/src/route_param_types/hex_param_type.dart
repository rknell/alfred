import 'http_route_param_type.dart';

class HexParamType implements HttpRouteParamType {
  @override
  final String name = 'hex';

  @override
  final String pattern = r'[0-9a-f]+';

  @override
  String parse(String value) => value;
}
