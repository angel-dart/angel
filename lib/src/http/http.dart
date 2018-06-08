/// Various libraries useful for creating highly-extensible servers.
library angel_framework.http;

import 'dart:async';
import 'dart:io';
export 'package:angel_http_exception/angel_http_exception.dart';
export 'package:angel_model/angel_model.dart';
export 'package:angel_route/angel_route.dart';
export 'package:body_parser/body_parser.dart' show FileUploadInfo;
export 'angel_http.dart';
export 'controller.dart';
export 'http_request_context.dart';
export 'http_response_context.dart';

/// Boots a shared server instance. Use this if launching multiple isolates
Future<HttpServer> startShared(address, int port) => HttpServer
    .bind(address ?? '127.0.0.1', port ?? 0, shared: true);

Future<HttpServer> Function(dynamic, int) startSharedSecure(SecurityContext securityContext) {
  return (address, int port) => HttpServer.bindSecure(
      address ?? '127.0.0.1', port ?? 0, securityContext,
      shared: true);
}
