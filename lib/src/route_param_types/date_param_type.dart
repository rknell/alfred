import 'http_route_param_type.dart';

class DateParamType implements HttpRouteParamType {
  @override
  final String name = 'date';

  @override
  final String pattern =
      r'-?\d{1,6}/(?:0[1-9]|1[012])/(?:0[1-9]|[12][0-9]|3[01])';

  @override
  DateTime parse(String value) {
    // note: the RegExp enforces month between 1 and 12 and day between 1 and 31
    // but it does not care about leap years and actual number of days in month
    // DateTime will accept "invalid" dates and adjust the result accordingly
    // eg. 2021-02-31 --> 2021-03-03
    final components = value.split('/').map(int.parse).toList();
    return DateTime.utc(components[0], components[1], components[2]);
  }
}
