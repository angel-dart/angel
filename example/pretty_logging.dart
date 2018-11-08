import 'package:console/console.dart';
import 'package:logging/logging.dart';

/// Prints the contents of a [LogRecord] with pretty colors.
prettyLog(LogRecord record) async {
  var pen = new TextPen();
  chooseLogColor(pen.reset(), record.level);
  pen(record.toString());

  if (record.error != null) pen(record.error.toString());
  if (record.stackTrace != null) pen(record.stackTrace.toString());

  pen();
}

/// Chooses a color based on the logger [level].
void chooseLogColor(TextPen pen, Level level) {
  if (level == Level.SHOUT)
    pen.darkRed();
  else if (level == Level.SEVERE)
    pen.red();
  else if (level == Level.WARNING)
    pen.yellow();
  else if (level == Level.INFO)
    pen.magenta();
  else if (level == Level.FINER)
    pen.blue();
  else if (level == Level.FINEST) pen.darkBlue();
}
