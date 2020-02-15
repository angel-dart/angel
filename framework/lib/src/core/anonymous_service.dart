import 'dart:async';
import 'request_context.dart';
import 'response_context.dart';
import 'service.dart';

/// An easy helper class to create one-off services without having to create an entire class.
///
/// Well-suited for testing.
class AnonymousService<Id, Data> extends Service<Id, Data> {
  FutureOr<List<Data>> Function([Map<String, dynamic>]) _index;
  FutureOr<Data> Function(Id, [Map<String, dynamic>]) _read, _remove;
  FutureOr<Data> Function(Data, [Map<String, dynamic>]) _create;
  FutureOr<Data> Function(Id, Data, [Map<String, dynamic>]) _modify, _update;

  AnonymousService(
      {FutureOr<List<Data>> index([Map<String, dynamic> params]),
      FutureOr<Data> read(Id id, [Map<String, dynamic> params]),
      FutureOr<Data> create(Data data, [Map<String, dynamic> params]),
      FutureOr<Data> modify(Id id, Data data, [Map<String, dynamic> params]),
      FutureOr<Data> update(Id id, Data data, [Map<String, dynamic> params]),
      FutureOr<Data> remove(Id id, [Map<String, dynamic> params]),
      FutureOr<Data> Function(RequestContext, ResponseContext) readData})
      : super(readData: readData) {
    _index = index;
    _read = read;
    _create = create;
    _modify = modify;
    _update = update;
    _remove = remove;
  }

  @override
  index([Map<String, dynamic> params]) =>
      Future.sync(() => _index != null ? _index(params) : super.index(params));

  @override
  read(Id id, [Map<String, dynamic> params]) => Future.sync(
      () => _read != null ? _read(id, params) : super.read(id, params));

  @override
  create(Data data, [Map<String, dynamic> params]) => Future.sync(() =>
      _create != null ? _create(data, params) : super.create(data, params));

  @override
  modify(Id id, Data data, [Map<String, dynamic> params]) =>
      Future.sync(() => _modify != null
          ? _modify(id, data, params)
          : super.modify(id, data, params));

  @override
  update(Id id, Data data, [Map<String, dynamic> params]) =>
      Future.sync(() => _update != null
          ? _update(id, data, params)
          : super.update(id, data, params));

  @override
  remove(Id id, [Map<String, dynamic> params]) => Future.sync(
      () => _remove != null ? _remove(id, params) : super.remove(id, params));
}
