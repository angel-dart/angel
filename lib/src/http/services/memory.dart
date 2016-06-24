part of angel_framework.http;

/// Represents data that can be serialized into a MemoryService;
class MemoryModel {
  int id;
}

/// An in-memory [Service].
class MemoryService<T> extends Service {
  List<MemoryModel> items = [];

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
    List result = [];

    for (int i = 0; i < items.length; i++) {
      result.add(_makeJson(i, items[i]));
    }

    return result;
  }

  Future read(id, [Map params]) async {
    int desiredId = int.parse(id.toString());
    if (items.length > desiredId) {
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
    items.add(created);
    return created;
    /*} catch (e) {
      throw new AngelHttpException.BadRequest(message: 'Invalid data.');
    }*/
  }

  Future modify(id, data, [Map params]) async {
    int desiredId = int.parse(id.toString());
    if (items.length > desiredId) {
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
    if (items.length > desiredId) {
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
    if (items.length > desiredId) {
      MemoryModel item = items[desiredId];
      items.removeAt(desiredId);
      return _makeJson(desiredId, item);
    } else throw new AngelHttpException.NotFound();
  }
}