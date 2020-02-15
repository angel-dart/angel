import 'package:logging/logging.dart';

void dumpError(LogRecord rec) {
  print(rec);
  if (rec.error != null) print(rec.error);
  if (rec.stackTrace != null) print(rec.stackTrace);
}
