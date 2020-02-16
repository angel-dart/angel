import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'util.dart';

const AngelBenchmark emptyBenchmark = _EmptyBenchmark();

main() => runBenchmarks([emptyBenchmark]);

class _EmptyBenchmark implements AngelBenchmark {
  const _EmptyBenchmark();

  @override
  String get name => 'empty';

  @override
  FutureOr<void> rawHandler(HttpRequest req, HttpResponse res) {
    return res.close();
  }

  @override
  void setupAngel(Angel app) {}
}
