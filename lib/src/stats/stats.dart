/// Computes averages progressively.

import 'dart:async';

class Stats {
  final String name;

  int _total = 0, _count = 0;
  double _average = 0.0;

  Stats(this.name);

  double get average => _average ?? (_total / _count);

  void log() {
    print('$name: $average avg.');
  }

  void add(int value) {
    _average = null;
    _total += value;
    _count++;
  }

  FutureOr<T> run<T>(FutureOr<T> f()) {
    var sw = new Stopwatch();
    //print('--- $name START');
    sw.start();

    void whenDone() {
      sw.stop();
      var ms = sw.elapsedMilliseconds;
      add(ms);
      print('--- $name DONE after ${ms}ms');
    }

    var r = f();

    if (r is Future) {
      return (r as Future).then((x) {
        whenDone();
        return x;
      });
    }

    whenDone();
    return r;
  }
}