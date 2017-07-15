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
  DartType _dateTimeTypeCache;
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

  PostgresBuildContext(
      this.raw, this.ormAnnotation, this.resolver, this.buildStep,
      {this.tableName, this.autoSnakeCaseNames, this.autoIdAndDateFields})
      : super(raw.annotation,
            originalClassName: raw.originalClassName,
            sourceFilename: raw.sourceFilename);

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

  LibraryElement get library =>
      _libraryCache ??= resolver.getLibrary(buildStep.inputId);

  DartType get dateTimeType => _dateTimeTypeCache ??= (resolver.libraries
      .firstWhere((lib) => lib.isDartCore)
      .getType('DateTime')
      .type);

  TypeProvider get typeProvider =>
      _typeProviderCache ??= library.context.typeProvider;

  FieldElement resolveRelationshipField(String name) =>
      relationshipFields.firstWhere((f) => f.name == name, orElse: () => null);

  PopulatedRelationship populateRelationship(String name) {
    return _populatedRelationships.putIfAbsent(name, () {
      // TODO: Belongs to many
      var f = raw.fields.firstWhere((f) => f.name == name);
      var relationship = relationships[name];
      var typeName =
          f.type.name.startsWith('_') ? f.type.name.substring(1) : f.type.name;
      var rc = new ReCase(typeName);

      if (relationship.type == RelationshipType.HAS_ONE ||
          relationship.type == RelationshipType.HAS_MANY) {
        var foreignKey = relationship.localKey ??
            (autoSnakeCaseNames != false
                ? '${rc.snakeCase}_id'
                : '${typeName}Id');
        var localKey = relationship.foreignKey ?? 'id';
        var foreignTable = relationship.foreignTable ??
            (autoSnakeCaseNames != false
                ? pluralize(rc.snakeCase)
                : pluralize(typeName));
        return new PopulatedRelationship(relationship.type, f.type, buildStep,
            resolver, autoSnakeCaseNames, autoIdAndDateFields,
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable,
            cascadeOnDelete: relationship.cascadeOnDelete);
      } else if (relationship.type == RelationshipType.BELONGS_TO) {
        var localKey = relationship.localKey ??
            (autoSnakeCaseNames != false
                ? '${rc.snakeCase}_id'
                : '${typeName}Id');
        var foreignKey = relationship.foreignKey ?? 'id';
        var foreignTable = relationship.foreignTable ??
            (autoSnakeCaseNames != false
                ? pluralize(rc.snakeCase)
                : pluralize(typeName));
        return new PopulatedRelationship(relationship.type, f.type, buildStep,
            resolver, autoSnakeCaseNames, autoIdAndDateFields,
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
  DartType _modelType;
  PostgresBuildContext _modelTypeContext;
  DartObject _modelTypeORM;
  final DartType dartType;
  final BuildStep buildStep;
  final Resolver resolver;
  final bool autoSnakeCaseNames, autoIdAndDateFields;

  PopulatedRelationship(int type, this.dartType, this.buildStep, this.resolver,
      this.autoSnakeCaseNames, this.autoIdAndDateFields,
      {String localKey,
      String foreignKey,
      String foreignTable,
      bool cascadeOnDelete})
      : super(type,
            localKey: localKey,
            foreignKey: foreignKey,
            foreignTable: foreignTable,
            cascadeOnDelete: cascadeOnDelete);

  DartType get modelType {
    if (_modelType != null) return _modelType;
    DartType searchType = dartType;
    var ormChecker = new TypeChecker.fromRuntime(ORM);

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

  PostgresBuildContext get modelTypeContext {
    if (_modelTypeContext != null) return _modelTypeContext;
    var reader = new ConstantReader(_modelTypeORM);
    if (reader.isNull)
      reader = null;
    else
      reader = reader.read('tableName');
    var orm = reader == null
        ? new ORM()
        : new ORM(reader.isString ? reader.stringValue : null);
    return _modelTypeContext = buildContext(modelType.element, orm, buildStep,
        resolver, autoSnakeCaseNames, autoIdAndDateFields);
  }
}
