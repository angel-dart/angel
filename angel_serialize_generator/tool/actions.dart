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