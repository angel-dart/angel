import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:build/build.dart';
import 'package:angel_serialize/context.dart';
import '../../annotations.dart';
import '../../migration.dart';
import '../../relations.dart';

class PostgresBuildContext extends BuildContext {
  DartType _dateTimeTypeCache;
  LibraryElement _libraryCache;
  TypeProvider _typeProviderCache;
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
