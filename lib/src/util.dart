import 'dart:async';
import 'dart:io';
import 'package:io/ansi.dart';
import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';
//import 'package:yamlicious/yamlicious.dart';

final String checkmark = ansiOutputEnabled ? '\u2714' : '[Success]';

final String ballot = ansiOutputEnabled ? '\u2717' : '[Failure]';

String get homeDirPath =>
    Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

Directory get homeDir => new Directory(homeDirPath);

Directory get angelDir => Directory(p.join(homeDir.path, '.angel'));

Future<Pubspec> loadPubspec([Directory directory]) {
  directory ??= Directory.current;
  var file = new File.fromUri(directory.uri.resolve('pubspec.yaml'));
  return file
      .readAsString()
      .then((yaml) => new Pubspec.parse(yaml, sourceUrl: file.uri));
}

// From: https://gist.github.com/tobischw/98dcd2563eec9a2a87bda8299055358a
Future<void> copyDirectory(Directory source, Directory destination) async {
  // if (!topLevel) stdout.write('\r');
  // print(darkGray
  //     .wrap('Copying dir "${source.path}" -> "${destination.path}..."'));

  await for (var entity in source.list(recursive: false)) {
    if (p.basename(entity.path) == '.git') continue;
    if (entity is Directory) {
      var newDirectory =
          Directory(p.join(destination.absolute.path, p.basename(entity.path)));
      await newDirectory.create(recursive: true);
      await copyDirectory(entity.absolute, newDirectory);
    } else if (entity is File) {
      var newPath = p.join(destination.path, p.basename(entity.path));
      // print(darkGray.wrap('\rCopying file "${entity.path}" -> "$newPath"'));
      await File(newPath).create(recursive: true);
      await entity.copy(newPath);
    }
  }

  // print('\rCopied "${source.path}" -> "${destination.path}.');
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
