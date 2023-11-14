import 'http_route_param_type.dart';

class TimestampParamType implements HttpRouteParamType {
  @override
  final String name = 'timestamp';

  @override
  final String pattern = r'-?\d+';

  @override
  DateTime parse(String value) =>
      DateTime.fromMillisecondsSinceEpoch(int.parse(value));
}
