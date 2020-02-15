import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

abstract class Reflector {
  const Reflector();

  String getName(Symbol symbol);

  ReflectedClass reflectClass(Type clazz);

  ReflectedFunction reflectFunction(Function function);

  ReflectedType reflectType(Type type);

  ReflectedInstance reflectInstance(Object object);

  ReflectedType reflectFutureOf(Type type) {
    throw UnsupportedError('`reflectFutureOf` requires `dart:mirrors`.');
  }
}

abstract class ReflectedInstance {
  final ReflectedType type;
  final ReflectedClass clazz;
  final Object reflectee;

  const ReflectedInstance(this.type, this.clazz, this.reflectee);

  @override
  int get hashCode => hash2(type, clazz);

  @override
  bool operator ==(other) =>
      other is ReflectedInstance && other.type == type && other.clazz == clazz;

  ReflectedInstance getField(String name);
}

abstract class ReflectedType {
  final String name;
  final List<ReflectedTypeParameter> typeParameters;
  final Type reflectedType;

  const ReflectedType(this.name, this.typeParameters, this.reflectedType);

  @override
  int get hashCode => hash3(name, typeParameters, reflectedType);

  @override
  bool operator ==(other) =>
      other is ReflectedType &&
      other.name == name &&
      const ListEquality<ReflectedTypeParameter>()
          .equals(other.typeParameters, typeParameters) &&
      other.reflectedType == reflectedType;

  ReflectedInstance newInstance(
      String constructorName, List positionalArguments,
      [Map<String, dynamic> namedArguments, List<Type> typeArguments]);

  bool isAssignableTo(ReflectedType other);
}

abstract class ReflectedClass extends ReflectedType {
  final List<ReflectedInstance> annotations;
  final List<ReflectedFunction> constructors;
  final List<ReflectedDeclaration> declarations;

  const ReflectedClass(
      String name,
      List<ReflectedTypeParameter> typeParameters,
      this.annotations,
      this.constructors,
      this.declarations,
      Type reflectedType)
      : super(name, typeParameters, reflectedType);

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

abstract class ReflectedFunction {
  final String name;
  final List<ReflectedTypeParameter> typeParameters;
  final List<ReflectedInstance> annotations;
  final ReflectedType returnType;
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

  ReflectedInstance invoke(Invocation invocation);
}

class ReflectedParameter {
  final String name;
  final List<ReflectedInstance> annotations;
  final ReflectedType type;
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

  const ReflectedTypeParameter(this.name);

  @override
  int get hashCode => hashObjects([name]);

  @override
  bool operator ==(other) =>
      other is ReflectedTypeParameter && other.name == name;
}
