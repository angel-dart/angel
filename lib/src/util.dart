import 'dart:async';
import 'dart:io';
import 'package:io/ansi.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
//import 'package:yamlicious/yamlicious.dart';

final String checkmark = ansiOutputEnabled ? '\u2713' : '[Success]';

final String ballot = ansiOutputEnabled ? '\u2717' : '[Failure]';

Future<Pubspec> loadPubspec([Directory directory]) {
  directory ??= Directory.current;
  var file = new File.fromUri(directory.uri.resolve('pubspec.yaml'));
  return file
      .readAsString()
      .then((yaml) => new Pubspec.parse(yaml, sourceUrl: file.uri));
}

Future savePubspec(Pubspec pubspec) async {
  // TODO: Save pubspec for real?
  //var text = toYamlString(pubspec);
}
