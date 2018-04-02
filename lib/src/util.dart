import 'package:intl/intl.dart';

final DateFormat fmt = new DateFormat('EEE, d MMM yyyy HH:mm:ss');

/// Formats a date (converted to UTC), ex: `Sun, 03 May 2015 23:02:37 GMT`.
String formatDateForHttp(DateTime dt) => fmt.format(dt.toUtc()) + ' GMT';