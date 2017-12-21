import 'dart:async';
import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'package:file/file.dart';
import 'package:pool/pool.dart';

/// Persists in-memory changes to a file on disk.
class JsonFileService extends Service {
  FileStat _lastStat;
  final Pool _mutex = new Pool(1);
  MapService _store;
  final File file;

  JsonFileService(this.file,
      {bool allowRemoveAll: false, bool allowQuery: true, MapService store}) {
    _store = store ??
        new MapService(
            allowRemoveAll: allowRemoveAll == true,
            allowQuery: allowQuery != false);
  }

  _load() async {
    if (!await file.exists()) await file.writeAsString(JSON.encode([]));
    var stat = await file.stat();
    //

    if (_lastStat == null ||
        stat.modified.millisecondsSinceEpoch >
            _lastStat.modified.millisecondsSinceEpoch) {
      _lastStat = stat;

      var contents = await file.readAsString();

      try {
        var list = JSON.decode(contents) as List;
        _store.items.clear(); // Clear exist in-memory copy
        _store.items.addAll(list.map(_revive)); // Insert all new entries
      } catch (e) {
        print('WARNING: Failed to reload contents of ${file.path}.');
      }
    }
  }

  _save() async {
    var r = await _mutex.request();
    await file.writeAsString(JSON.encode(_store.items.map(_jsonify).toList()));
    r.release();
  }

  @override
  Future close() {
    return _store.close();
  }

  @override
  Future<List> index([Map params]) async =>
      _load().then((_) => _store.index(params));

  @override
  Future<Map> read(id, [Map params]) =>
      _load().then((_) => _store.read(id, params));

  @override
  Future<Map> create(data, [Map params]) async {
    await _load();
    _store.items.add(data);
    await _save();
    return data;
  }

  @override
  Future<Map> remove(id, [Map params]) async {
    await _load();
    var r = await _store.remove(id, params);
    await _save();
    return r;
  }

  @override
  Future<Map> update(id, data, [Map params]) async {
    await _load();
    var r = await _store.update(id, data, params);
    await _save();
    return r;
  }

  @override
  Future<Map> modify(id, data, [Map params]) async {
    await _load();
    var r = await _store.update(id, data, params);
    await _save();
    return r;
  }
}

_safeForJson(x) {
  if (x is DateTime)
    return x.toIso8601String();
  else if (x is Map)
    return _jsonify(x);
  else if (x is num || x is String || x is bool || x == null)
    return x;
  else if (x is Iterable)
    return x.map(_safeForJson).toList();
  else
    return x.toString();
}

Map _jsonify(Map map) {
  return map.keys.fold<Map>({}, (out, k) => out..[k] = _safeForJson(map[k]));
}

_revive(x) {
  if (x is Map) {
    return x.keys.fold<Map>({}, (out, k) => out..[k] = _revive(x[k]));
  } else if (x is Iterable)
    return x.map(_revive).toList();
  else if (x is String) {
    try {
      return DateTime.parse(x);
    } catch (e) {
      return x;
    }
  } else
    return x;
}
