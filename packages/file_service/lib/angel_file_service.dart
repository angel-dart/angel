import 'dart:async';
import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'package:file/file.dart';
import 'package:pool/pool.dart';

/// Persists in-memory changes to a file on disk.
class JsonFileService extends Service<String, Map<String, dynamic>> {
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

  Map<String, dynamic> _coerceStringDynamic(Map m) {
    return m.keys.fold<Map<String, dynamic>>(
        <String, dynamic>{}, (out, k) => out..[k.toString()] = m[k]);
  }

  Future _load() {
    return _mutex.withResource(() async {
      if (!await file.exists()) await file.writeAsString(json.encode([]));
      var stat = await file.stat();
      //

      if (_lastStat == null ||
          stat.modified.millisecondsSinceEpoch >
              _lastStat.modified.millisecondsSinceEpoch) {
        _lastStat = stat;

        var contents = await file.readAsString();

        var list = json.decode(contents) as Iterable;
        _store.items.clear(); // Clear exist in-memory copy
        _store.items.addAll(list.map((x) =>
            _coerceStringDynamic(_revive(x) as Map))); // Insert all new entries
      }
    });
  }

  _save() {
    return _mutex.withResource(() {
      return file
          .writeAsString(json.encode(_store.items.map(_jsonify).toList()));
    });
  }

  @override
  Future close() async {
    _store.close();
  }

  @override
  Future<List<Map<String, dynamic>>> index(
          [Map<String, dynamic> params]) async =>
      _load()
          .then((_) => _store.index(params))
          .then((it) => it.map(_jsonifyToSD).toList());

  @override
  Future<Map<String, dynamic>> read(id, [Map<String, dynamic> params]) =>
      _load().then((_) => _store.read(id, params)).then(_jsonifyToSD);

  @override
  Future<Map<String, dynamic>> create(data,
      [Map<String, dynamic> params]) async {
    await _load();
    var created = await _store.create(data, params).then(_jsonifyToSD);
    await _save();
    return created;
  }

  @override
  Future<Map<String, dynamic>> remove(id, [Map<String, dynamic> params]) async {
    await _load();
    var r = await _store.remove(id, params).then(_jsonifyToSD);
    await _save();
    return r;
  }

  @override
  Future<Map<String, dynamic>> update(id, data,
      [Map<String, dynamic> params]) async {
    await _load();
    var r = await _store.update(id, data, params).then(_jsonifyToSD);
    await _save();
    return r;
  }

  @override
  Future<Map<String, dynamic>> modify(id, data,
      [Map<String, dynamic> params]) async {
    await _load();
    var r = await _store.update(id, data, params).then(_jsonifyToSD);
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

Map<String, dynamic> _jsonifyToSD(Map<String, dynamic> map) =>
    _jsonify(map).cast<String, dynamic>();

dynamic _revive(x) {
  if (x is Map) {
    return x.keys.fold<Map<String, dynamic>>(
        {}, (out, k) => out..[k.toString()] = _revive(x[k]));
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
