import 'dart:async';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize_generator/context.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:inflection/inflection.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';
import 'build_context.dart';

class PostgresBuildContext extends BuildContext {
  LibraryElement _libraryCache;
  TypeProvider _typeProviderCache;
  TypeBuilder _modelClassBuilder,
      _queryClassBuilder,
      _whereClassBuilder,
      _postgresqlConnectionBuilder;
  String _prefix;
  final Map<String, Relationship> _populatedRelationships = {};
  final Map<String, Column> columnInfo = {};
  final Map<String, IndexType> indices = {};
  final Map<String, Relationship> relationships = {};
  final bool autoSnakeCaseNames, autoIdAndDateFields;
  final String tableName;
  final ORM ormAnnotation;
  final BuildContext raw;
  final Resolver resolver;
  final BuildStep buildStep;
  String primaryKeyName = 'id';

  PostgresBuildContext._(
      this.raw, this.ormAnnotation, this.resolver, this.buildStep,
      {this.tableName, this.autoSnakeCaseNames, this.autoIdAndDateFields})
      : super(raw.annotation,
            originalClassName: raw.originalClassName,
            sourceFilename: raw.sourceFilename);

  static Future<PostgresBuildContext> create(BuildContext raw,
      ORM ormAnnotation, Resolver resolver, BuildStep buildStep,
      {String tableName,
      bool autoSnakeCaseNames,
      bool autoIdAndDateFields}) async {
    var ctx = new PostgresBuildContext._(
      raw,
      ormAnnotation,
      resolver,
      buildStep,
      tableName: tableName,
      autoSnakeCaseNames: autoSnakeCaseNames,
      autoIdAndDateFields: autoIdAndDateFields,
    );

    // Library
    ctx._libraryCache = await resolver.libraryFor(buildStep.inputId);

    return ctx;
  }

  final List<FieldElement> fields = [], relationshipFields = [];

  TypeBuilder get modelClassBuilder =>
      _modelClassBuilder ??= new TypeBuilder(modelClassName);

  TypeBuilder get queryClassBuilder =>
      _queryClassBuilder ??= new TypeBuilder(queryClassName);

  TypeBuilder get whereClassBuilder =>
      _whereClassBuilder ??= new TypeBuilder(whereClassName);

  TypeBuilder get postgreSQLConnectionBuilder =>
      _postgresqlConnectionBuilder ??= new TypeBuilder('PostgreSQLConnection');

  String get prefix {
    if (_prefix != null) return _prefix;
    if (relationships.isEmpty)
      return _prefix = '';
    else
      return _prefix = tableName + '.';
  }

  Map<String, String> get aliases => raw.aliases;

  Map<String, bool> get shimmed => raw.shimmed;

  String get sourceFilename => raw.sourceFilename;

  String get modelClassName => raw.modelClassName;

  String get originalClassName => raw.originalClassName;

  String get queryClassName => modelClassName + 'Query';
  String get whereClassName => queryClassName + 'Where';

  LibraryElement get library => _libraryCache;

  TypeProvider get typeProvider =>
      _typeProviderCache ??= library.context.typeProvider;

  FieldElement resolveRelationshipField(String name) =>
      relationshipFields.firstWhere((f) => f.name == name, orElse: () => null);

  PopulatedRelationship populateRelationship(String name) {
    return _populatedRelationships.putIfAbsent(name, () {
      var f = raw.fields.firstWhere((f) => f.name == name);
      var relationship = relationships[name];
      DartType refType = f.type;

      if (refType.isAssignableTo(typeProvider.listType) ||
          refType.name == 'List') {
        var iType = refType as InterfaceType;

        if (iType.typeArguments.isEmpty)
          throw 'Relationship "${f.name}" cannot be modeled as a generic List.';

        refType = iType.typeArguments.first;
      }

      var typeName = refType.name.startsWith('_')
          ? refType.name.substring(1)
          : refType.name;
      var rc = new ReCase(typeName);

      if (relationship.type == RelationshipType.HAS_ONE ||
          relationship.type == RelationshipType.HAS_MANY) {
        //print('Has many $tableName');
        var single = singularize(tableName);
        var foreignKey = relationship.foreignTable ??
            (autoSnakeCaseNames != false ? '${single}_id' : '${single}Id');
        var localKey = relationship.localKey ?? 'id';
        var foreignTable = relationship.foreignTable ??
            (autoSnakeCaseNames != false
                ? pluralize(rc.snakeCase)
                : pluralize(typeName));
        return new PopulatedRelationship(
            relationship.type,
            f.name,
            f.type,
            buildStep,
            resolver,
            autoSnakeCaseNames,
            autoIdAndDateFields,
            relationship.type == RelationshipType.HAS_ONE,
            typeProvider,
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable,
            cascadeOnDelete: relationship.cascadeOnDelete);
      } else if (relationship.type == RelationshipType.BELONGS_TO ||
          relationship.type == RelationshipType.BELONGS_TO_MANY) {
        var localKey = relationship.localKey ??
            (autoSnakeCaseNames != false
                ? '${rc.snakeCase}_id'
                : '${typeName}Id');
        var foreignKey = relationship.foreignKey ?? 'id';
        var foreignTable = relationship.foreignTable ??
            (autoSnakeCaseNames != false
                ? pluralize(rc.snakeCase)
                : pluralize(typeName));
        return new PopulatedRelationship(
            relationship.type,
            f.name,
            f.type,
            buildStep,
            resolver,
            autoSnakeCaseNames,
            autoIdAndDateFields,
            relationship.type == RelationshipType.BELONGS_TO,
            typeProvider,
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable,
            cascadeOnDelete: relationship.cascadeOnDelete);
      } else
        throw new UnsupportedError(
            'Invalid relationship type: ${relationship.type}');
    });
  }
}

class PopulatedRelationship extends Relationship {
  bool _isList;
  DartType _modelType;
  PostgresBuildContext _modelTypeContext;
  DartObject _modelTypeORM;
  final String originalName;
  final DartType dartType;
  final BuildStep buildStep;
  final Resolver resolver;
  final bool autoSnakeCaseNames, autoIdAndDateFields;
  final bool isSingular;
  final TypeProvider typeProvider;

  PopulatedRelationship(
      int type,
      this.originalName,
      this.dartType,
      this.buildStep,
      this.resolver,
      this.autoSnakeCaseNames,
      this.autoIdAndDateFields,
      this.isSingular,
      this.typeProvider,
      {String localKey,
      String foreignKey,
      String foreignTable,
      bool cascadeOnDelete})
      : super(type,
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable,
            cascadeOnDelete: cascadeOnDelete);

  bool get isBelongsTo =>
      type == RelationshipType.BELONGS_TO ||
      type == RelationshipType.BELONGS_TO_MANY;

  bool get isHas =>
      type == RelationshipType.HAS_ONE || type == RelationshipType.HAS_MANY;

  bool get isList => _isList ??=
      dartType.isAssignableTo(typeProvider.listType) || dartType.name == 'List';

  DartType get modelType {
    if (_modelType != null) return _modelType;
    DartType searchType = dartType;
    var ormChecker = new TypeChecker.fromRuntime(ORM);

    // Get inner type from List if any...
    if (!isSingular) {
      if (!isList)
        throw '"$originalName" is a many-to-one relationship, and thus it should be represented as a List within your Dart class. You have it represented as ${dartType.name}.';
      else {
        var iType = dartType as InterfaceType;
        if (iType.typeArguments.isEmpty)
          throw '"$originalName" is a many-to-one relationship, and should be modeled as a List that references another model type. Example: `List<T>`, where T is a model type.';
        else
          searchType = iType.typeArguments.first;
      }
    }

    while (searchType != null) {
      var classElement = searchType.element as ClassElement;
      var ormAnnotation = ormChecker.firstAnnotationOf(classElement);

      if (ormAnnotation != null) {
        _modelTypeORM = ormAnnotation;
        return _modelType = searchType;
      } else {
        // If we didn't find an @ORM(), then refer to the parent type.
        searchType = classElement.supertype;
      }
    }

    throw new StateError(
        'Neither ${dartType.name} nor its parent types are annotated with an @ORM() annotation. It is impossible to compute this relationship.');
  }

  Future<PostgresBuildContext> get modelTypeContext async {
    if (_modelTypeContext != null) return _modelTypeContext;
    var reader = new ConstantReader(_modelTypeORM);
    if (reader.isNull)
      reader = null;
    else
      reader = reader.read('tableName');
    var orm = reader == null
        ? new ORM()
        : new ORM(reader.isString ? reader.stringValue : null);
    return _modelTypeContext = await buildContext(modelType.element, orm,
        buildStep, resolver, autoSnakeCaseNames, autoIdAndDateFields);
  }
}
