import 'alfred.dart';
import 'router.dart';

class RouteGroup with Router {
  @override
  final Alfred app;

  @override
  final String pathPrefix;

  RouteGroup(this.app, this.pathPrefix);
}
