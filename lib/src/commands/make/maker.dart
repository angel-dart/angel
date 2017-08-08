import 'dart:async';
import 'dart:io';
import 'package:pubspec/pubspec.dart';
import 'package:pub_semver/pub_semver.dart';
import '../pub.dart';

class MakerDependency {
  final String name, version;
  final bool dev;
  const MakerDependency(this.name, this.version, {this.dev: false});
}

Future depend(Iterable<MakerDependency> deps) async {
  var pubspec = await PubSpec.load(Directory.current);
  Map<String, DependencyReference> newDeps = {}, newDevDeps = {};

  for (var dep in deps) {
    var isPresent = false;
    if (dep.dev)
      isPresent = pubspec.devDependencies.containsKey(dep.name);
    else
      isPresent = pubspec.dependencies.containsKey(dep.name);

    if (!isPresent) {
      print('Installing ${dep.name}@${dep.version}...');

      if (dep.dev)
        newDevDeps[dep.name] =
            new HostedReference(new VersionConstraint.parse(dep.version));
      else
        newDeps[dep.name] =
            new HostedReference(new VersionConstraint.parse(dep.version));
    }

    if (newDeps.isNotEmpty || newDevDeps.isNotEmpty) {
      var newPubspec = pubspec.copy(
          dependencies:
              new Map<String, DependencyReference>.from(pubspec.dependencies)
                ..addAll(newDeps),
          devDependencies:
              new Map<String, DependencyReference>.from(pubspec.devDependencies)
                ..addAll(newDevDeps));

      await newPubspec.save(Directory.current);
      var pubPath = resolvePub();

      print('Now running `$pubPath get`...');

      var pubGet = await Process.start(pubPath, ['get']);
      pubGet.stdout.listen(stdout.add);
      pubGet.stderr.listen(stderr.add);

      var code = await pubGet.exitCode;

      if (code != 0) throw 'pub get terminated with exit code $code';
    }
  }
}
