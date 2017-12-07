import 'package:build_runner/build_runner.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angel_serialize_generator/angel_serialize_generator.dart';

final List<BuildAction> actions = [
  new BuildAction(
    new PartBuilder([const JsonModelGenerator()]),
    'angel_serialize_generator',
    inputs: const [
      'test/models/book.dart',
    ],
  ),
  new BuildAction(
    new PartBuilder([const JsonModelGenerator()]),
    'angel_serialize_generator',
    inputs: const [
      'test/models/author.dart',
    ],
  ),
];
