part of angel_framework.http;

/// An in-memory [Service].
class MemoryService<T> extends Service {
  Map <int, T> items = {};

  _makeJson(int index, T t) {
    if (T == null || T == Map)
      return mergeMap([god.serializeObject(t), {'id': index}]);
    else
      return t;
  }

  Future<List> index([Map params]) async {
    return items.keys
        .where((index) => items[index] != null)
        .map((index) => _makeJson(index, items[index]))
        .toList();
  }

  Future read(id, [Map params]) async {
    int desiredId = int.parse(id.toString());
    if (items.containsKey(desiredId)) {
      T found = items[desiredId];
      if (found != null) {
        return _makeJson(desiredId, found);
      } else throw new AngelHttpException.NotFound();
    } else throw new AngelHttpException.NotFound();
  }

  Future create(data, [Map params]) async {
    //try {
      print("Data: $data");
      var created = (data is Map) ? god.deserializeDatum(data, outputType: T) : data;
      print("Created $created");
      items[items.length] = created;
      return _makeJson(items.length - 1, created);
    /*} catch (e) {
      throw new AngelHttpException.BadRequest(message: 'Invalid data.');
    }*/
  }

  Future modify(id, data, [Map params]) async {
    int desiredId = int.parse(id.toString());
    if (items.containsKey(desiredId)) {
      try {
        Map existing = god.serializeObject(items[desiredId]);
        data = mergeMap([existing, data]);
        items[desiredId] =
        (data is Map) ? god.deserializeDatum(data, outputType: T) : data;
        return _makeJson(desiredId, items[desiredId]);
      } catch (e) {
        throw new AngelHttpException.BadRequest(message: 'Invalid data.');
      }
    } else throw new AngelHttpException.NotFound();
  }

  Future update(id, data, [Map params]) async {
    int desiredId = int.parse(id.toString());
    if (items.containsKey(desiredId)) {
      try {
        items[desiredId] =
        (data is Map) ? god.deserializeDatum(data, outputType: T) : data;
        return _makeJson(desiredId, items[desiredId]);
      } catch (e) {
        throw new AngelHttpException.BadRequest(message: 'Invalid data.');
      }
    } else throw new AngelHttpException.NotFound();
  }

  Future remove(id, [Map params]) async {
    int desiredId = int.parse(id.toString());
    if (items.containsKey(desiredId)) {
      T item = items[desiredId];
      items[desiredId] = null;
      return _makeJson(desiredId, item);
    } else throw new AngelHttpException.NotFound();
  }

  MemoryService() : super();
}