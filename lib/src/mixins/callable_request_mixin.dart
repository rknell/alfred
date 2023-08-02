import 'dart:async';
import 'package:alfred/alfred.dart';

/// A Mixin to Resquest Callback
/// 
/// Use this mixin to create a callable class 
/// that can be used like a 
/// callback enpoint or middlewares

mixin CallableRequestMixin {

   FutureOr<dynamic> call(HttpRequest req, HttpResponse res);

}

