/// Various libraries useful for creating highly-extensible servers.
library angel_framework.http;

import 'dart:async';
import 'dart:io';
export 'package:angel_http_exception/angel_http_exception.dart';
export 'package:angel_model/angel_model.dart';
export 'package:angel_route/angel_route.dart';
export 'package:body_parser/body_parser.dart' show FileUploadInfo;
export 'angel_base.dart';
export 'anonymous_service.dart';
export 'controller.dart';
export 'hooked_service.dart';
export 'map_service.dart';
export 'metadata.dart';
export 'request_context.dart';
export 'response_context.dart';
export 'routable.dart';
export 'server.dart';
export 'service.dart';
export 'typed_service.dart';

/// Boots a shared server instance. Use this if launching multiple isolates
Future<HttpServer> startShared(address, int port) => HttpServer
    .bind(address ?? InternetAddress.LOOPBACK_IP_V4, port ?? 0, shared: true);

Future<HttpServer> Function(dynamic, int) startSharedSecure(SecurityContext securityContext) {
  return (address, int port) => HttpServer.bindSecure(
      address ?? InternetAddress.LOOPBACK_IP_V4, port ?? 0, securityContext,
      shared: true);
}
