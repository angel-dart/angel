import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:angel_container/angel_container.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker generateReflectorTypeChecker =
    const TypeChecker.fromRuntime(GenerateReflector);

/// Reads data from a [GenerateReflector] annotation.
class GenerateReflectorReader {
  final ConstantReader annotation;

  GenerateReflectorReader(this.annotation);

  String get name => annotation.peek('name')?.stringValue;

  List<DartType> get types =>
      annotation
          .peek('types')
          ?.listValue
          ?.map((o) => ConstantReader(o).typeValue)
          ?.toList() ??
      <DartType>[];

  List<Symbol> get symbols =>
      annotation
          .peek('symbols')
          ?.listValue
          ?.map((o) => ConstantReader(o).symbolValue)
          ?.toList() ??
      <Symbol>[];

  List<DartObject> get functions =>
      annotation.peek('functions')?.listValue ?? <DartObject>[];
}
