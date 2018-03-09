import 'package:angel_serialize_generator/angel_serialize_generator.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/build_runner.dart';
import 'package:source_gen/source_gen.dart';

const InputSet standalone =
    const InputSet(include: const ['test/models/book.dart']);
const InputSet dependent =
    const InputSet(include: const ['test/models/author.dart']);
const InputSet all = const InputSet(include: const ['test/models/*.dart']);

final List<BuilderApplication> applications = [
  applyToRoot(
    new PartBuilder([
      const JsonModelGenerator(),
    ]),
    generateFor: standalone,
  ),
  applyToRoot(
    new PartBuilder([
      const JsonModelGenerator(),
    ]),
    generateFor: dependent,
  ),
  applyToRoot(
    new PartBuilder(
      [const SerializerGenerator()],
      generatedExtension: '.serializer.g.dart',
    ),
    generateFor: all,
  ),
];

/*
import 'package:build_runner/build_runner.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angel_serialize_generator/angel_serialize_generator.dart';

final List<BuildAction> actions = [
  jsonModel(const ['test/models/book.dart']),
  jsonModel(const ['test/models/author.dart']),
  angelSerialize(const ['test/models/book.dart']),
  angelSerialize(const ['test/models/author.dart']),
];

BuildAction jsonModel(List<String> inputs) {
  return new BuildAction(
    new PartBuilder([const JsonModelGenerator()]),
    'angel_serialize_generator',
    inputs: inputs,
  );
}

BuildAction angelSerialize(List<String> inputs) {
  return new BuildAction(
    new PartBuilder(
      [const SerializerGenerator()],
      generatedExtension: '.serializer.g.dart',
    ),
    'angel_serialize_generator',
    inputs: inputs,
  );
}

*/
