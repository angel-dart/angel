class ReflectionException implements Exception {
  final String message;

  ReflectionException(this.message);

  @override
  String toString() => message;
}
