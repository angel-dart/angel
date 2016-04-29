part of angel_framework.http;

/// An in-memory [Service].
class MemoryService<T> extends Service {
  God god = new God();
  Map <int, T> items = {};

  Map makeJson(int index, T t) {
    return mergeMap([god.serializeToMap(t), {'id': index}]);
  }

  Future<List> index([Map params]) async {
    return items.keys
        .where((index) => items[index] != null)
        .map((index) => makeJson(index, items[index]))
        .toList();
  }

  Future<Object> read(id, [Map params]) async {
    int desiredId = int.parse(id.toString());
    if (items.containsKey(desiredId)) {
      T found = items[desiredId];
      if (found != null) {
        return makeJson(desiredId, found);
      } else throw new AngelHttpException.NotFound();
    } else throw new AngelHttpException.NotFound();
  }

  Future<Object> create(Map data, [Map params]) async {
    try {
      items[items.length] = god.deserializeFromMap(data, T);
      T created = items[items.length - 1];
      return makeJson(items.length - 1, created);
    } catch (e) {
      throw new AngelHttpException.BadRequest(message: 'Invalid data.');
    }
  }

  Future<Object> modify(id, Map data, [Map params]) async {
    int desiredId = int.parse(id.toString());
    if (items.containsKey(desiredId)) {
      try {
        Map existing = god.serializeToMap(items[desiredId]);
        data = mergeMap([existing, data]);
        items[desiredId] = god.deserializeFromMap(data, T);
        return makeJson(desiredId, items[desiredId]);
      } catch (e) {
        throw new AngelHttpException.BadRequest(message: 'Invalid data.');
      }
    } else throw new AngelHttpException.NotFound();
  }

  Future<Object> update(id, Map data, [Map params]) async {
    int desiredId = int.parse(id.toString());
    if (items.containsKey(desiredId)) {
      try {
        items[desiredId] = god.deserializeFromMap(data, T);
        return makeJson(desiredId, items[desiredId]);
      } catch (e) {
        throw new AngelHttpException.BadRequest(message: 'Invalid data.');
      }
    } else throw new AngelHttpException.NotFound();
  }

  Future<Object> remove(id, [Map params]) async {
    int desiredId = int.parse(id.toString());
    if (items.containsKey(desiredId)) {
      T item = items[desiredId];
      items[desiredId] = null;
      return makeJson(desiredId, item);
    } else throw new AngelHttpException.NotFound();
  }

  MemoryService() : super();
}