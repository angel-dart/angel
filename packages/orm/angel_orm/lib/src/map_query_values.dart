import 'query_values.dart';

/// A [QueryValues] implementation that simply writes to a [Map].
class MapQueryValues extends QueryValues {
  final Map<String, dynamic> values = {};

  @override
  Map<String, dynamic> toMap() => values;
}
