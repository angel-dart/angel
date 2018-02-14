import 'package:angel_serialize_generator/angel_serialize_generator.dart';
import 'package:build_runner/build_runner.dart';
import 'package:source_gen/source_gen.dart';

final List<BuildAction> buildActions = [
  new BuildAction(
    new PartBuilder([
      const JsonModelGenerator(autoIdAndDateFields: false),
    ]),
    'angel_eventsource',
    inputs: const [
      'lib/angel_eventsource.dart',
    ],
  ),
];
