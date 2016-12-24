#!/usr/bin/env dart
import 'dart:async';
import 'common.dart';

main(args) async {
  runZoned(startServer(args), onError: onError);
}
