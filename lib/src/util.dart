import 'dart:async';
import 'dart:io';
import 'package:io/ansi.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yamlicious/yamlicious.dart';

final String checkmark = ansiOutputEnabled ? '\u2713' : '[Success]';

Future<Pubspec> loadPubspec() {
  var file = new File('pubspec.yaml');
  return file
      .readAsString()
      .then((yaml) => new Pubspec.parse(yaml, sourceUrl: file.uri));
}

Future savePubspec(Pubspec pubspec) async {
  var text = toYamlString(pubspec);
}