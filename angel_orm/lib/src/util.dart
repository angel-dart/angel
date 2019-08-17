import 'package:charcode/ascii.dart';
import 'builder.dart';

bool isAscii(int ch) => ch >= $nul && ch <= $del;

/// The ORM prefers using substitution values, which allow for prepared queries,
/// and prevent SQL injection attacks.
@deprecated
String toSql(Object obj, {bool withQuotes = true}) {
  if (obj is DateTime) {
    return withQuotes ? "'${dateYmdHms.format(obj)}'" : dateYmdHms.format(obj);
  } else if (obj is bool) {
    return obj ? 'TRUE' : 'FALSE';
  } else if (obj == null) {
    return 'NULL';
  } else if (obj is String) {
    var b = StringBuffer();
    var escaped = false;
    var it = obj.runes.iterator;

    while (it.moveNext()) {
      if (it.current == $nul) {
        continue; // Skip null byte
      } else if (it.current == $single_quote) {
        escaped = true;
        b.write('\\x');
        b.write(it.current.toRadixString(16).padLeft(2, '0'));
      } else if (isAscii(it.current)) {
        b.writeCharCode(it.current);
      } else if (it.currentSize == 1) {
        escaped = true;
        b.write('\\u');
        b.write(it.current.toRadixString(16).padLeft(4, '0'));
      } else if (it.currentSize == 2) {
        escaped = true;
        b.write('\\U');
        b.write(it.current.toRadixString(16).padLeft(8, '0'));
      } else {
        throw UnsupportedError(
            'toSql() cannot encode a rune of size (${it.currentSize})');
      }
    }

    if (!withQuotes) {
      return b.toString();
    } else if (escaped) {
      return "E'$b'";
    } else {
      return "'$b'";
    }
  } else {
    return obj.toString();
  }
}
