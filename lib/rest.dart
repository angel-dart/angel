part of angel_client;

_buildQuery(Map params) {
  if (params == null || params == {})
    return "";

  String result = "";
  return result;
}

const Map _readHeaders = const {
  "Accept": "application/json"
};

const Map _writeHeaders = const {
  "Accept": "application/json",
  "Content-Type": "application/json"
};

class Rest extends Angel {
  BaseClient client;

  Rest(String path, BaseClient this.client) :super(path);

  @override
  RestService service(String path, {Type type}) {
    String uri = path.replaceAll(new RegExp(r"(^\/)|(\/+$)"), "");
    return new RestService._base("$basePath/$uri", client, type)
      ..app = this;
  }
}

/// Queries an Angel service via REST.
class RestService extends Service {
  String basePath;
  BaseClient client;
  Type outputType;

  RestService._base(Pattern path, BaseClient this.client,
      Type this.outputType) {
    this.basePath = (path is RegExp) ? path.pattern : path;
  }

  _makeBody(data) {
    if (outputType == null)
      return JSON.encode(data);
    else return god.serialize(data);
  }

  @override
  Future<List> index([Map params]) async {
    var response = await client.get(
        "$basePath/${_buildQuery(params)}", headers: _readHeaders);

    if (outputType == null)
      return god.deserialize(response.body);

    else {
      return JSON.decode(response.body).map((x) =>
          god.deserializeDatum(x, outputType: outputType)).toList();
    }
  }

  @override
  Future read(id, [Map params]) async {
    var response = await client.get(
        "$basePath/$id${_buildQuery(params)}", headers: _readHeaders);
    return god.deserialize(response.body, outputType: outputType);
  }

  @override
  Future create(data, [Map params]) async {
    var response = await client.post(
        "$basePath/${_buildQuery(params)}", body: _makeBody(data),
        headers: _writeHeaders);
    return god.deserialize(response.body, outputType: outputType);
  }

  @override
  Future modify(id, data, [Map params]) async {
    var response = await client.patch(
        "$basePath/$id${_buildQuery(params)}", body: _makeBody(data),
        headers: _writeHeaders);
    return god.deserialize(response.body, outputType: outputType);
  }

  @override
  Future update(id, data, [Map params]) async {
    var response = await client.patch(
        "$basePath/$id${_buildQuery(params)}", body: _makeBody(data),
        headers: _writeHeaders);
    return god.deserialize(response.body, outputType: outputType);
  }

  @override
  Future remove(id, [Map params]) async {
    var response = await client.delete(
        "$basePath/$id${_buildQuery(params)}", headers: _readHeaders);
    return god.deserialize(response.body, outputType: outputType);
  }
}
