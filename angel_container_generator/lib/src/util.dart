import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:angel_container/angel_container.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker generateReflectorTypeChecker =
    const TypeChecker.fromRuntime(GenerateReflector);

/// Reads data from a [GenerateReflector] annotation.
class GenerateReflectorReader {
  final ConstantReader constantReader;

  GenerateReflectorReader(this.constantReader);

  String get name => constantReader.peek('name')?.stringValue;

  List<DartType> get types =>
      constantReader
          .peek('types')
          ?.listValue
          ?.map((o) => ConstantReader(o).typeValue)
          ?.toList() ??
      <DartType>[];

  List<Symbol> get symbols =>
      constantReader
          .peek('symbols')
          ?.listValue
          ?.map((o) => ConstantReader(o).symbolValue)
          ?.toList() ??
      <Symbol>[];

  List<DartObject> get functions =>
      constantReader.peek('functions')?.listValue ?? <DartObject>[];
}
