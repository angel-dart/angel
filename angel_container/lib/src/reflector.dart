import 'package:collection/collection.dart';
import 'package:quiver_hashcode/hashcode.dart';

abstract class Reflector {
  String getName(Symbol symbol);

  ReflectedClass reflectClass(Type clazz);

  ReflectedFunction reflectFunction(Function function);

  ReflectedType reflectType(Type type);
}

abstract class ReflectedInstance {
  final ReflectedType type;
  final ReflectedClass clazz;

  const ReflectedInstance(this.type, this.clazz);

  @override
  int get hashCode => hash2(type, clazz);

  @override
  bool operator ==(other) =>
      other is ReflectedInstance && other.type == type && other.clazz == clazz;

  T invoke<T>(Invocation invocation);
}

abstract class ReflectedType {
  final String name;
  final List<ReflectedTypeParameter> typeParameters;

  const ReflectedType(this.name, this.typeParameters);

  @override
  int get hashCode => hash2(name, typeParameters);

  @override
  bool operator ==(other) =>
      other is ReflectedType &&
      other.name == name &&
      const ListEquality<ReflectedTypeParameter>()
          .equals(other.typeParameters, typeParameters);

  T newInstance<T>(String constructorName, List positionalArguments,
      Map<String, dynamic> namedArguments, List<Type> typeArguments);

  bool isAssignableTo(ReflectedType other);
}

abstract class ReflectedClass extends ReflectedType {
  final List<ReflectedInstance> annotations;
  final List<ReflectedFunction> constructors;
  final List<ReflectedDeclaration> declarations;

  const ReflectedClass(String name, List<ReflectedTypeParameter> typeParameters,
      this.annotations, this.constructors, this.declarations)
      : super(name, typeParameters);

  @override
  int get hashCode =>
      hash4(super.hashCode, annotations, constructors, declarations);

  @override
  bool operator ==(other) =>
      other is ReflectedClass &&
      super == other &&
      const ListEquality<ReflectedInstance>()
          .equals(other.annotations, annotations) &&
      const ListEquality<ReflectedFunction>()
          .equals(other.constructors, constructors) &&
      const ListEquality<ReflectedDeclaration>()
          .equals(other.declarations, declarations);
}

class ReflectedDeclaration {
  final String name;
  final bool isStatic;
  final ReflectedFunction function;

  const ReflectedDeclaration(this.name, this.isStatic, this.function);

  @override
  int get hashCode => hash3(name, isStatic, function);

  @override
  bool operator ==(other) =>
      other is ReflectedDeclaration &&
      other.name == name &&
      other.isStatic == isStatic &&
      other.function == function;
}

class ReflectedFunction {
  final String name;
  final List<ReflectedTypeParameter> typeParameters;
  final List<ReflectedInstance> annotations;
  final Type returnType;
  final List<ReflectedParameter> parameters;
  final bool isGetter, isSetter;

  const ReflectedFunction(this.name, this.typeParameters, this.annotations,
      this.returnType, this.parameters, this.isGetter, this.isSetter);

  @override
  int get hashCode => hashObjects([
        name,
        typeParameters,
        annotations,
        returnType,
        parameters,
        isGetter,
        isSetter
      ]);

  @override
  bool operator ==(other) =>
      other is ReflectedFunction &&
      other.name == name &&
      const ListEquality<ReflectedTypeParameter>()
          .equals(other.typeParameters, typeParameters) &&
      const ListEquality<ReflectedInstance>()
          .equals(other.annotations, annotations) &&
      other.returnType == returnType &&
      const ListEquality<ReflectedParameter>()
          .equals(other.parameters, other.parameters) &&
      other.isGetter == isGetter &&
      other.isSetter == isSetter;
}

class ReflectedParameter {
  final String name;
  final List<ReflectedInstance> annotations;
  final Type type;
  final bool isRequired;
  final bool isNamed;

  const ReflectedParameter(
      this.name, this.annotations, this.type, this.isRequired, this.isNamed);

  @override
  int get hashCode =>
      hashObjects([name, annotations, type, isRequired, isNamed]);

  @override
  bool operator ==(other) =>
      other is ReflectedParameter &&
      other.name == name &&
      const ListEquality<ReflectedInstance>()
          .equals(other.annotations, annotations) &&
      other.type == type &&
      other.isRequired == isRequired &&
      other.isNamed == isNamed;
}

class ReflectedTypeParameter {
  final String name;
  final Type type;

  const ReflectedTypeParameter(this.name, this.type);

  @override
  int get hashCode => hash2(name, type);

  @override
  bool operator ==(other) =>
      other is ReflectedTypeParameter &&
      other.name == name &&
      other.type == type;
}
