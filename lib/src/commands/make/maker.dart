import 'dart:async';
import 'package:io/ansi.dart';
import '../../util.dart';

class MakerDependency {
  final String name, version;
  final bool dev;

  const MakerDependency(this.name, this.version, {this.dev: false});
}

Future depend(Iterable<MakerDependency> deps) async {
  var pubspec = await loadPubspec();
  var missing = <MakerDependency>[];

  for (var dep in deps) {
    var isPresent = false;
    if (dep.dev)
      isPresent = pubspec.devDependencies.containsKey(dep.name);
    else
      isPresent = pubspec.dependencies.containsKey(dep.name);

    if (!isPresent) {
//      TODO: https://github.com/dart-lang/pubspec_parse/issues/17:
//      print('Installing ${dep.name}@${dep.version}...');
//
//      if (dep.dev) {
//        pubspec.devDependencies[dep.name] = new HostedDependency(
//          version: new VersionConstraint.parse(dep.version),
//        );
//      } else {
//        pubspec.dependencies[dep.name] = new HostedDependency(
//          version: new VersionConstraint.parse(dep.version),
//        );
//      }
    }
  }

  missing.sort((a, b) {
    if (!a.dev) {
      if (b.dev) {
        return -1;
      } else {
        return 0;
      }
    } else {
      if (b.dev) {
        return 0;
      } else {
        return 1;
      }
    }
  });

  if (missing.isNotEmpty) {
    print(yellow.wrap(missing.length == 1
        ? 'You are missing one dependency:'
        : 'You are missing ${missing.length} dependencies:'));
    print('\n');

    for (var dep in missing) {
      var m = '  * ${dep.name}@${dep.version}';
      if (dep.dev) m += ' (dev dependency)';
      print(yellow.wrap(m));
    }
  }

//  if (isPresent) {
//      TODO: https://github.com/dart-lang/pubspec_parse/issues/17
//      await savePubspec(pubspec);
//      var pubPath = resolvePub();
//
//      print('Now running `$pubPath get`...');
//
//      var pubGet = await Process.start(pubPath, ['get']);
//      pubGet.stdout.listen(stdout.add);
//      pubGet.stderr.listen(stderr.add);
//
//      var code = await pubGet.exitCode;
//
//      if (code != 0) throw 'pub get terminated with exit code $code';
}
