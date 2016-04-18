part of angel_framework.http;

/// An in-memory [Service].
class MemoryService<T> extends Service {
  God god = new God();
  Map <int, T> items = {};

  Future<List> index([Map params]) async => items.values.toList();

  Future<Object> read(id, [Map params]) async => items[int.parse(id)];

  Future<Object> create(Map data, [Map params]) async {
    data['id'] = items.length;
    items[items.length] = god.deserializeFromMap(data, T);
    return items[items.length - 1];
  }

  Future<Object> update(id, Map data, [Map params]) async {
    data['id'] = int.parse(id);
    items[int.parse(id)] = god.deserializeFromMap(data, T);
    return data;
  }

  Future<Object> remove(id, [Map params]) async {
    var item = items[int.parse(id)];
    items.remove(int.parse(id));
    return item;
  }

  MemoryService() : super();
}