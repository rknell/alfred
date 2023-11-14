abstract class HttpRouteParamType {
  String get name;
  String get pattern;
  dynamic parse(String value);
}
