import 'dart:io';
import 'package:angel_route/angel_route.dart';
import 'proxy_layer.dart';

class PubServeLayer extends ProxyLayer {
  PubServeLayer(
      {bool debug: false,
      String host: 'localhost',
      String mapTo: '/',
      int port: 8080,
      String publicPath: '/'})
      : super(host, port, debug: debug, mapTo: mapTo, publicPath: publicPath);

  @override
  void serve(Router router) {
    if (Platform.environment['ANGEL_ENV'] == 'production') {
      // Auto-deactivate in production ;)
      return;
    }
  }
}
