library angel_container;

export 'src/container.dart';
export 'src/empty/empty.dart';
export 'src/static/static.dart';
export 'src/exception.dart';
export 'src/reflector.dart';

/// An annotation used by `package:angel_container_generator` to generate reflection metadata for types chosen by the user.
///
/// When attached to a library, it generates a class that implements the `Reflector` interface.
///
/// When attached to a class, it can be used to customize the output of the generator.
class GenerateReflector {
  /// The list of types that should have reflection metadata generated for them.
  final List<Type> types;

  /// The list of top-level functions that should have reflection metadata generated for them.
  final List<Function> functions;

  /// The list of symbols within this class that should have reflection metadata generated for them.
  ///
  /// If omitted, then all symbols will be included.
  final List<Symbol> symbols;

  /// An explicit name for the generated reflector.
  ///
  /// By default, a class with the library's name in PascalCase is created,
  /// with the text "Reflector" appended.
  ///
  /// Ex. `my_cool_library` becomes `const MyCoolLibraryReflector()`.
  final String name;

  const GenerateReflector(
      {this.types: const <Type>[],
      this.functions: const <Function>[],
      this.symbols: const <Symbol>[],
      this.name});
}
