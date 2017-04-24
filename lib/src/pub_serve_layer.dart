import 'package:angel_route/angel_route.dart';
import 'proxy_layer.dart';

class PubServeLayer extends ProxyLayer {
  PubServeLayer(
      {bool debug: false,
      bool recoverFrom404: true,
      bool streamToIO: true,
      String host: 'localhost',
      String mapTo: '/',
      int port: 8080,
      String protocol: 'http',
      String publicPath: '/'})
      : super(host, port,
            debug: debug,
            mapTo: mapTo,
            protocol: protocol,
            publicPath: publicPath,
            recoverFrom404: recoverFrom404 != false,
            streamToIO: streamToIO != false);

  @override
  void serve(Router router) {
    if (app?.isProduction == true) {
      // Auto-deactivate in production ;)
      return;
    }

    super.serve(router);
  }
}
