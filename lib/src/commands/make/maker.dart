import 'dart:async';
import 'package:io/ansi.dart';
import '../../util.dart';

class MakerDependency implements Comparable<MakerDependency> {
  final String name, version;
  final bool dev;

  const MakerDependency(this.name, this.version, {this.dev: false});

  @override
  int compareTo(MakerDependency other) => name.compareTo(other.name);
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
      missing.add(dep);
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

  var missingDeps = missing.where((d) => !d.dev).toList()..sort();
  var missingDevDeps = missing.where((d) => d.dev).toList()..sort();
  var totalCount = missingDeps.length + missingDevDeps.length;

  if (totalCount > 0) {
    print(yellow.wrap(totalCount == 1
        ? 'You are missing one dependency.'
        : 'You are missing $totalCount dependencies.'));
    print(yellow.wrap(
        'Update your `pubspec.yaml` to add the following dependencies:\n'));

    void printMissing(String type, Iterable<MakerDependency> deps) {
      if (deps.isNotEmpty) {
        print(yellow.wrap('  $type:'));
        for (var dep in deps) {
          print(yellow.wrap('    ${dep.name}: ${dep.version}'));
        }
      }
    }

    printMissing('dependencies', missingDeps);
    printMissing('dev_dependencies', missingDevDeps);
    print('\n');
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
