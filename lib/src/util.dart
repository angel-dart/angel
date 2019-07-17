import 'dart:async';
import 'dart:io';
import 'package:io/ansi.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
//import 'package:yamlicious/yamlicious.dart';

final String checkmark = ansiOutputEnabled ? '\u2714' : '[Success]';

final String ballot = ansiOutputEnabled ? '\u2717' : '[Failure]';

String get homeDirPath =>
    Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

Directory get homeDir => new Directory(homeDirPath);

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

Future<bool> runCommand(String exec, List<String> args) async {
  var s = '$exec ${args.join(' ')}'.trim();
  stdout.write(darkGray.wrap('Running `$s`... '));

  try {
    var p = await Process.start(exec, args);
    var code = await p.exitCode;

    if (code == 0) {
      print(green.wrap(checkmark));
      return true;
    } else {
      print(red.wrap(ballot));
      await stdout.addStream(p.stdout);
      await stderr.addStream(p.stderr);
      return false;
    }
  } catch (e) {
    print(red.wrap('$ballot Failed to run process.'));
    return false;
  }
}
