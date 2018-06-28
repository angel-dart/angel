/// Cross-platform validation library based on `matcher`.
library angel_validate;

export 'package:matcher/matcher.dart';
export 'src/context_aware.dart';
export 'src/matchers.dart';
export 'src/validator.dart';

/// Marks a field name as required.
String requireField(String field) => '$field*';

/// Marks multiple fields as required.
String requireFields(Iterable<String> fields) =>
    fields.map(requireField).join(', ');
