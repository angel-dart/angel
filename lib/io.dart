/// Command-line client library for the Angel framework.
library angel_client.cli;

import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:json_god/json_god.dart' as god;
import 'angel_client.dart';
import 'base_angel_client.dart';
export 'angel_client.dart';

/// Queries an Angel server via REST.
class Rest extends BaseAngelClient {
  final List<Service> _services = [];

  Rest(String path) : super(new http.Client(), path);

  @override
  Service service(String path, {Type type, AngelDeserializer deserializer}) {
    String uri = path.replaceAll(straySlashes, "");
    var s = new RestService(
        client, this, "$basePath/$uri", type);
    _services.add(s);
    return s;
  }

  @override
  Stream<String> authenticateViaPopup(String url, {String eventName: 'token'}) {
    throw new UnimplementedError('Opening popup windows is not supported in the `dart:io` client.');
  }

  Future close() async {
    super.close();
    Future.wait(_services.map((s) => s.close())).then((_) {
      _services.clear();
    });
  }
}

/// Queries an Angel service via REST.
class RestService extends BaseAngelService {
  final Type type;

  RestService(http.BaseClient client, Angel app, String url, this.type)
      : super(client, app, url);

  @override
  deserialize(x) {
    if (type != null) {
      return x.runtimeType == type
          ? x
          : god.deserializeDatum(x, outputType: type);
    }

    return x;
  }

  @override
  makeBody(x) {
    if (type != null) {
      return super.makeBody(god.serializeObject(x));
    }

    return super.makeBody(x);
  }
}
