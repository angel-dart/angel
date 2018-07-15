import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:logging/logging.dart';
import 'package:io/ansi.dart';

/// Prints the contents of a [LogRecord] with pretty colors.
void prettyLog(LogRecord record) {
  var code = chooseLogColor(record.level);

  if (record.error == null) print(code.wrap(record.toString()));

  if (record.error != null) {
    var err = record.error;
    if (err is AngelHttpException && err.statusCode != 500) return;
    print(code.wrap(record.toString() + '\n'));
    print(code.wrap(err.toString()));

    if (record.stackTrace != null) {
      print(code.wrap(record.stackTrace.toString()));
    }
  }
}

/// Chooses a color based on the logger [level].
AnsiCode chooseLogColor(Level level) {
  if (level == Level.SHOUT)
    return backgroundRed;
  else if (level == Level.SEVERE)
    return red;
  else if (level == Level.WARNING)
    return yellow;
  else if (level == Level.INFO)
    return cyan;
  else if (level == Level.FINER || level == Level.FINEST) return lightGray;
  return resetAll;
}
