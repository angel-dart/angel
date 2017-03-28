import 'dart:async';
import 'dart:io';

Future<HttpServer> startShared(InternetAddress address, int port) => HttpServer
    .bind(address ?? InternetAddress.LOOPBACK_IP_V4, port ?? 0, shared: true);
