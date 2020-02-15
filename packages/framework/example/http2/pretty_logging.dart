import 'package:logging/logging.dart';

/// Prints the contents of a [LogRecord] with pretty colors.
void prettyLog(LogRecord record) {
  print(record.toString());

  if (record.error != null) print(record.error.toString());
  if (record.stackTrace != null) print(record.stackTrace.toString());
}
