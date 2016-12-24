#!/usr/bin/env dart
import 'dart:async';
import 'common.dart';

main() async {
  runZoned(startServer(), onError: onError);
}
