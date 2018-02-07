import 'dart:async';
import 'service.dart';

/// An easy helper class to create one-off services without having to create an entire class.
///
/// Well-suited for testing.
class AnonymousService extends Service {
  Function _index, _read, _create, _modify, _update, _remove;

  AnonymousService(
      {FutureOr index([Map params]),
      FutureOr read(id, [Map params]),
      FutureOr create(data, [Map params]),
      FutureOr modify(id, data, [Map params]),
      FutureOr update(id, data, [Map params]),
      FutureOr remove(id, [Map params])})
      : super() {
    _index = index;
    _read = read;
    _create = create;
    _modify = modify;
    _update = update;
    _remove = remove;
  }

  @override
  index([Map params]) => _index != null ? _index(params) : super.index(params);

  @override
  read(id, [Map params]) =>
      _read != null ? _read(id, params) : super.read(id, params);

  @override
  create(data, [Map params]) =>
      _create != null ? _create(data, params) : super.create(data, params);

  @override
  modify(id, data, [Map params]) => _modify != null
      ? _modify(id, data, params)
      : super.modify(id, data, params);

  @override
  update(id, data, [Map params]) => _update != null
      ? _update(id, data, params)
      : super.update(id, data, params);

  @override
  remove(id, [Map params]) =>
      _remove != null ? _remove(id, params) : super.remove(id, params);
}
