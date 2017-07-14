import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize_generator/context.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';

class PostgresBuildContext extends BuildContext {
  DartType _dateTimeTypeCache;
  LibraryElement _libraryCache;
  TypeProvider _typeProviderCache;
  TypeBuilder _modelClassBuilder,
      _queryClassBuilder,
      _whereClassBuilder,
      _postgresqlConnectionBuilder;
  final Map<String, Column> columnInfo = {};
  final Map<String, IndexType> indices = {};
  final Map<String, Relationship> relationships = {};
  final String tableName;
  final ORM ormAnnotation;
  final BuildContext raw;
  final Resolver resolver;
  final BuildStep buildStep;
  String primaryKeyName = 'id';

  PostgresBuildContext(
      this.raw, this.ormAnnotation, this.resolver, this.buildStep,
      {this.tableName})
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
}
