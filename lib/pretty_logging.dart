import 'package:logging/logging.dart';
import 'package:io/ansi.dart';

/// Prints the contents of a [LogRecord] with pretty colors.
///
/// By passing [omitError], you can omit printing the error of a given
/// [LogRecord].
///
/// You can also pass a custom [printFunction] or [logColorChooser].
void prettyLog(LogRecord record,
    {bool Function(LogRecord) omitError,
    void Function(String) printFunction,
    AnsiCode Function(Level) logColorChooser}) {
  logColorChooser ??= chooseLogColor;
  omitError ??= (_) => false;
  printFunction ??= print;

  var code = logColorChooser(record.level);
  if (record.error == null) printFunction(code.wrap(record.toString()));

  if (record.error != null) {
    var err = record.error;
    if (omitError(record)) return;
    printFunction(code.wrap(record.toString() + '\n'));
    printFunction(code.wrap(err.toString()));

    if (record.stackTrace != null) {
      printFunction(code.wrap(record.stackTrace.toString()));
    }
  }
}

/// Chooses a color based on the logger [level].
AnsiCode chooseLogColor(Level level) {
  if (level == Level.SHOUT) {
    return backgroundRed;
  } else if (level == Level.SEVERE) {
    return red;
  } else if (level == Level.WARNING) {
    return yellow;
  } else if (level == Level.INFO) {
    return cyan;
  } else if (level == Level.CONFIG ||
      level == Level.FINE ||
      level == Level.FINER ||
      level == Level.FINEST) {
    return lightGray;
  }
  return resetAll;
}
