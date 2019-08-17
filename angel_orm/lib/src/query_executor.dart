import 'dart:async';

/// An abstract interface that performs queries.
///
/// This class should be implemented.
abstract class QueryExecutor {
  const QueryExecutor();

  /// Executes a single query.
  Future<List<List>> query(
      String tableName, String query, Map<String, dynamic> substitutionValues,
      [List<String> returningFields]);

  /// Begins a database transaction.
  Future<T> transaction<T>(FutureOr<T> f());
}
