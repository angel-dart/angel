part of angel_framework.http;

/// An in-memory [Service].
class MemoryService<T> extends Service {
  Map <int, MemoryModel> items = {};

  MemoryService() :super() {
    if (!reflectType(T).isAssignableTo(reflectType(MemoryModel))) {
      throw new Exception(
          "MemoryServices only support classes that inherit from MemoryModel.");
    }
  }

  _makeJson(int index, MemoryModel t) {
    return t..id = index;
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
      MemoryModel found = items[desiredId];
      if (found != null) {
        return _makeJson(desiredId, found);
      } else throw new AngelHttpException.NotFound();
    } else throw new AngelHttpException.NotFound();
  }

  Future create(data, [Map params]) async {
    //try {
    MemoryModel created = (data is MemoryModel) ? data : god.deserializeDatum(
        data, outputType: T);

    created.id = items.length;
    items[created.id] = created;
    return created;
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
      MemoryModel item = items[desiredId];
      items[desiredId] = null;
      return _makeJson(desiredId, item);
    } else throw new AngelHttpException.NotFound();
  }
}