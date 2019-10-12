import 'package:angel_container/angel_container.dart';

/// A [Reflector] implementation that throws exceptions on all attempts
/// to perform reflection.
///
/// Use this in contexts where you know you won't need any reflective capabilities.
class ThrowingReflector extends Reflector {
  /// The error message to give the end user when an [UnsupportedError] is thrown.
  final String errorMessage;

  static const String defaultErrorMessage =
      'You attempted to perform a reflective action, but you are using `ThrowingReflector`, '
      'a class which disables reflection. Consider using the `MirrorsReflector` '
      'class if you need reflection.';

  const ThrowingReflector({this.errorMessage = defaultErrorMessage});

  @override
  String getName(Symbol symbol) => const EmptyReflector().getName(symbol);

  UnsupportedError _error() => UnsupportedError(errorMessage);

  @override
  ReflectedClass reflectClass(Type clazz) => throw _error();

  @override
  ReflectedInstance reflectInstance(Object object) => throw _error();

  @override
  ReflectedType reflectType(Type type) => throw _error();

  @override
  ReflectedFunction reflectFunction(Function function) => throw _error();
}
