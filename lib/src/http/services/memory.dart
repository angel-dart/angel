part of angel_framework.http;

/// An in-memory [Service].
class MemoryService<T> extends Service {
  God god = new God();
  Map <int, T> items = {};

  makeJson(int index, T t) {
    if (T == null || T == Map)
      return mergeMap([god.serializeToMap(t), {'id': index}]);
    else
      return t;
  }

  Future<List> index([Map params]) async {
    return items.keys
        .where((index) => items[index] != null)
        .map((index) => makeJson(index, items[index]))
        .toList();
  }

  Future read(id, [Map params]) async {
    int desiredId = int.parse(id.toString());
    if (items.containsKey(desiredId)) {
      T found = items[desiredId];
      if (found != null) {
        return makeJson(desiredId, found);
      } else throw new AngelHttpException.NotFound();
    } else throw new AngelHttpException.NotFound();
  }

  Future create(data, [Map params]) async {
    try {
      items[items.length] =
      (data is Map) ? god.deserializeFromMap(data, T) : data;
      T created = items[items.length - 1];
      return makeJson(items.length - 1, created);
    } catch (e) {
      throw new AngelHttpException.BadRequest(message: 'Invalid data.');
    }
  }

  Future modify(id, data, [Map params]) async {
    int desiredId = int.parse(id.toString());
    if (items.containsKey(desiredId)) {
      try {
        Map existing = god.serializeToMap(items[desiredId]);
        data = mergeMap([existing, data]);
        items[desiredId] =
        (data is Map) ? god.deserializeFromMap(data, T) : data;
        return makeJson(desiredId, items[desiredId]);
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
        (data is Map) ? god.deserializeFromMap(data, T) : data;
        return makeJson(desiredId, items[desiredId]);
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
      return makeJson(desiredId, item);
    } else throw new AngelHttpException.NotFound();
  }

  MemoryService() : super();
}