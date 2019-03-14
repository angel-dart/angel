import 'dart:io';
import 'package:angel_container/src/container.dart';
import 'package:angel_framework/angel_framework.dart';

class WingsRequestContext extends RequestContext<int> {
  @override
  // TODO: implement body
  Stream<List<int>> get body => null;

  @override
  // TODO: implement container
  Container get container => null;

  @override
  // TODO: implement cookies
  List<Cookie> get cookies => null;

  @override
  // TODO: implement headers
  HttpHeaders get headers => null;

  @override
  // TODO: implement hostname
  String get hostname => null;

  @override
  // TODO: implement method
  String get method => null;

  @override
  // TODO: implement originalMethod
  String get originalMethod => null;

  @override
  // TODO: implement path
  String get path => null;

  @override
  // TODO: implement rawRequest
  int get rawRequest => null;

  @override
  // TODO: implement remoteAddress
  InternetAddress get remoteAddress => null;

  @override
  // TODO: implement session
  HttpSession get session => null;

  @override
  // TODO: implement uri
  Uri get uri => null;
}
