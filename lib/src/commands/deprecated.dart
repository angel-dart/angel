import 'package:console/console.dart';

void warnDeprecated(String command, [TextPen pen]) {
  pen ??= new TextPen();
  pen
    ..yellow()
    ..call('The `$command` command is deprecated, and will be removed by v1.2.0.')
    ..call()
    ..reset();
}
