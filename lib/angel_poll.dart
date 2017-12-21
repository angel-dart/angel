import 'dart:async';
import 'package:angel_client/angel_client.dart';

class Poll extends Service {
  final Service inner;

  final String idField;
  final bool asPaginated;

  final List _items = [];
  final StreamController _onIndexed = new StreamController(),
      _onRead = new StreamController(),
      _onCreated = new StreamController(),
      _onModified = new StreamController(),
      _onUpdated = new StreamController(),
      _onRemoved = new StreamController();

  bool Function(dynamic, dynamic) _compare;
  Timer _timer;

  @override
  Angel get app => inner.app;

  @override
  Stream get onIndexed => _onIndexed.stream;

  @override
  Stream get onRead => _onRead.stream;

  @override
  Stream get onCreated => _onCreated.stream;

  @override
  Stream get onModified => _onModified.stream;

  @override
  Stream get onUpdated => _onUpdated.stream;

  @override
  Stream get onRemoved => _onRemoved.stream;

  Poll(this.inner, Duration interval,
      {this.idField: 'id', this.asPaginated: false, bool compare(a, b)}) {
    _timer = new Timer.periodic(interval, _timerCallback);
    _compare = compare ?? (a, b) => a[idField ?? 'id'] == b[idField ?? 'id'];
  }

  @override
  Future close() async {
    _timer.cancel();
    _onIndexed.close();
    _onRead.close();
    _onCreated.close();
    _onModified.close();
    _onUpdated.close();
    _onRemoved.close();
  }

  @override
  Future index([Map params]) {
    return inner.index().then((data) {
      var items = asPaginated == true ? data['data'] : data;
      _items
        ..clear()
        ..addAll(items);
      _onIndexed.add(items);
    });
  }

  @override
  Future remove(id, [Map params]) {}

  @override
  Future update(id, data, [Map params]) {}

  @override
  Future modify(id, data, [Map params]) {}

  @override
  Future create(data, [Map params]) {}

  @override
  Future read(id, [Map params]) {}

  void _timerCallback(Timer timer) {
    index().then((data) {
      var items = asPaginated == true ? data['data'] : data;

      // TODO: Check create, modify, remove

    }).catchError(_onIndexed.addError);
  }
}
