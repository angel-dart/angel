import 'dart:async';

import 'package:graphql_parser/graphql_parser.dart';
import 'package:graphql_schema/graphql_schema.dart';

import 'introspection.dart';

class GraphQL {
  final List<GraphQLType> customTypes = [];
  GraphQLSchema _schema;

  GraphQL(GraphQLSchema schema,
      {bool introspect: true,
      List<GraphQLType> customTypes = const <GraphQLType>[]})
      : _schema = schema {
    if (customTypes?.isNotEmpty == true) {
      this.customTypes.addAll(customTypes);
    }

    if (introspect) {
      var allTypes = <GraphQLType>[];
      allTypes.addAll(this.customTypes);
      _schema = reflectSchema(_schema, allTypes);

      for (var type in allTypes) {
        if (!this.customTypes.contains(type)) {
          this.customTypes.add(type);
        }
      }
    }

    if (_schema.query != null) this.customTypes.add(_schema.query);
    if (_schema.mutation != null) this.customTypes.add(_schema.mutation);
  }

  GraphQLType convertType(TypeContext ctx) {
    if (ctx.listType != null) {
      return new GraphQLListType(convertType(ctx.listType.type));
    } else if (ctx.typeName != null) {
      switch (ctx.typeName.name) {
        case 'Int':
          return graphQLString;
        case 'Float':
          return graphQLFloat;
        case 'String':
          return graphQLString;
        case 'Boolean':
          return graphQLBoolean;
        case 'ID':
          return graphQLId;
        case 'Date':
        case 'DateTime':
          return graphQLDate;
        default:
          return customTypes.firstWhere((t) => t.name == ctx.typeName.name,
              orElse: () => throw new ArgumentError(
                  'Unknown GraphQL type: "${ctx.typeName.name}"'));
      }
    } else {
      throw new ArgumentError('Invalid GraphQL type: "${ctx.span.text}"');
    }
  }

  Future<Map<String, dynamic>> parseAndExecute(String text,
      {String operationName,
      sourceUrl,
      Map<String, dynamic> variableValues: const {},
      initialValue}) {
    var tokens = scan(text, sourceUrl: sourceUrl);
    var parser = new Parser(tokens);
    var document = parser.parseDocument();
    return executeRequest(_schema, document,
        operationName: operationName,
        initialValue: initialValue,
        variableValues: variableValues);
  }

  Future<Map<String, dynamic>> executeRequest(
      GraphQLSchema schema, DocumentContext document,
      {String operationName,
      Map<String, dynamic> variableValues: const {},
      initialValue}) async {
    var operation = getOperation(document, operationName);
    var coercedVariableValues =
        coerceVariableValues(schema, operation, variableValues ?? {});
    if (operation.isQuery)
      return await executeQuery(
          document, operation, schema, coercedVariableValues, initialValue);
    else {
      throw new UnimplementedError('mutations');
//      return executeMutation(
//          document, operation, schema, coercedVariableValues, initialValue);
    }
  }

  OperationDefinitionContext getOperation(
      DocumentContext document, String operationName) {
    var ops =
        document.definitions.where((d) => d is OperationDefinitionContext);

    if (operationName == null) {
      return ops.length == 1
          ? ops.first as OperationDefinitionContext
          : throw new GraphQLException.fromMessage(
              'This document does not define any operations.');
    } else {
      return ops.firstWhere(
              (d) => (d as OperationDefinitionContext).name == operationName,
              orElse: () => throw new GraphQLException.fromMessage(
                  'Missing required operation "$operationName".'))
          as OperationDefinitionContext;
    }
  }

  Map<String, dynamic> coerceVariableValues(
      GraphQLSchema schema,
      OperationDefinitionContext operation,
      Map<String, dynamic> variableValues) {
    var coercedValues = <String, dynamic>{};
    var variableDefinitions =
        operation.variableDefinitions?.variableDefinitions ?? [];

    for (var variableDefinition in variableDefinitions) {
      var variableName = variableDefinition.variable.name;
      var variableType = variableDefinition.type;
      var defaultValue = variableDefinition.defaultValue;
      var value = variableValues[variableName];

      if (value == null) {
        if (defaultValue != null) {
          coercedValues[variableName] = defaultValue.value.value;
        } else if (!variableType.isNullable) {
          throw new GraphQLException.fromSourceSpan(
              'Missing required variable "$variableName".',
              variableDefinition.span);
        }
      } else {
        var type = convertType(variableType);
        var validation = type.validate(variableName, value);

        if (!validation.successful) {
          throw new GraphQLException(validation.errors
              .map((e) => new GraphQLExceptionError(e, locations: [
                    new GraphExceptionErrorLocation.fromSourceLocation(
                        variableDefinition.span.start)
                  ]))
              .toList());
        } else {
          coercedValues[variableName] = type.deserialize(value);
        }
      }
    }

    return coercedValues;
  }

  Future<Map<String, dynamic>> executeQuery(
      DocumentContext document,
      OperationDefinitionContext query,
      GraphQLSchema schema,
      Map<String, dynamic> variableValues,
      initialValue) async {
    var queryType = schema.query;
    var selectionSet = query.selectionSet;
    return await executeSelectionSet(
        document, selectionSet, queryType, initialValue, variableValues);
  }

  Future<Map<String, dynamic>> executeSelectionSet(
      DocumentContext document,
      SelectionSetContext selectionSet,
      GraphQLObjectType objectType,
      objectValue,
      Map<String, dynamic> variableValues) async {
    var groupedFieldSet =
        collectFields(document, objectType, selectionSet, variableValues);
    var resultMap = <String, dynamic>{};

    for (var responseKey in groupedFieldSet.keys) {
      var fields = groupedFieldSet[responseKey];

      for (var field in fields) {
        var fieldName = field.field.fieldName.name;
        var fieldType = objectType.fields
            .firstWhere((f) => f.name == fieldName, orElse: () => null)
            ?.type;
        if (fieldType == null) continue;
        var responseValue = await executeField(document, fieldName, objectType,
            objectValue, fields, fieldType, variableValues);
        resultMap[responseKey] = responseValue;
      }
    }

    return resultMap;
  }

  Future executeField(
      DocumentContext document,
      String fieldName,
      GraphQLObjectType objectType,
      objectValue,
      List<SelectionContext> fields,
      GraphQLType fieldType,
      Map<String, dynamic> variableValues) async {
    var field = fields[0];
    var argumentValues =
        coerceArgumentValues(objectType, field, variableValues);
    var resolvedValue = await resolveFieldValue(
        objectType, objectValue, field.field.fieldName.name, argumentValues);
    return completeValue(
        document, fieldName, fieldType, fields, resolvedValue, variableValues);
  }

  Map<String, dynamic> coerceArgumentValues(GraphQLObjectType objectType,
      SelectionContext field, Map<String, dynamic> variableValues) {
    var coercedValues = <String, dynamic>{};
    var argumentValues = field.field.arguments;
    var fieldName = field.field.fieldName.name;
    var desiredField = objectType.fields.firstWhere((f) => f.name == fieldName);
    var argumentDefinitions = desiredField.arguments;

    for (var argumentDefinition in argumentDefinitions) {
      var argumentName = argumentDefinition.name;
      var argumentType = argumentDefinition.type;
      var defaultValue = argumentDefinition.defaultValue;
      var value = argumentValues.firstWhere((a) => a.name == argumentName,
          orElse: () => null);

      if (value?.valueOrVariable?.variable != null) {
        var variableName = value.valueOrVariable.variable.name;
        var variableValue = variableValues[variableName];

        if (variableValues.containsKey(variableName)) {
          coercedValues[argumentName] = variableValue;
        } else if (defaultValue != null || argumentDefinition.defaultsToNull) {
          coercedValues[argumentName] = defaultValue;
        } else if (argumentType is GraphQLNonNullableType) {
          throw new GraphQLException.fromSourceSpan(
              'Missing value for argument "$argumentName".',
              value.valueOrVariable.span);
        } else {
          continue;
        }
      } else if (value == null) {
        if (defaultValue != null || argumentDefinition.defaultsToNull) {
          coercedValues[argumentName] = defaultValue;
        } else if (argumentType is GraphQLNonNullableType) {
          throw new GraphQLException.fromMessage(
              'Missing value for argument "$argumentName".');
        } else {
          continue;
        }
      } else {
        var validation =
            argumentType.validate(fieldName, value.valueOrVariable.value.value);

        if (!validation.successful) {
          throw new GraphQLException.fromSourceSpan(
              'Coercion error for value of argument "$argumentName".',
              value.valueOrVariable.span);
        } else {
          var coercedValue = validation.value;
          coercedValues[argumentName] = coercedValue;
        }
      }
    }

    return coercedValues;
  }

  Future<T> resolveFieldValue<T>(GraphQLObjectType objectType, T objectValue,
      String fieldName, Map<String, dynamic> argumentValues) async {
    var field = objectType.fields.firstWhere((f) => f.name == fieldName);

    if (field.resolve == null) {
      return null;
    } else {
      return await field.resolve(objectValue, argumentValues) as T;
    }
  }

  Future completeValue(
      DocumentContext document,
      String fieldName,
      GraphQLType fieldType,
      List<SelectionContext> fields,
      result,
      Map<String, dynamic> variableValues) async {
    if (fieldType is GraphQLNonNullableType) {
      var innerType = fieldType.innerType;
      var completedResult = completeValue(
          document, fieldName, innerType, fields, result, variableValues);

      if (completedResult == null) {
        throw new GraphQLException.fromMessage(
            'Null value provided for non-nullable field "$fieldName".');
      } else {
        return completedResult;
      }
    }

    if (result == null) {
      return null;
    }

    if (fieldType is GraphQLListType) {
      if (result is! Iterable) {
        throw new GraphQLException.fromMessage(
            'Value of field "$fieldName" must be a list or iterable, got $result instead.');
      }

      var innerType = fieldType.innerType;
      var out = [];

      for (var resultItem in (result as Iterable)) {
        out.add(await completeValue(document, '(item in "$fieldName")',
            innerType, fields, resultItem, variableValues));
      }

      return out;
    }

    if (fieldType is GraphQLScalarType) {
      try {
        var validation = fieldType.validate(fieldName, result);

        if (!validation.successful) {
          return null;
        } else {
          return validation.value;
        }
      } on TypeError {
        throw new GraphQLException.fromMessage(
            'Value of field "$fieldName" must be ${fieldType.valueType}, got $result instead.');
      }
    }

    if (fieldType is GraphQLObjectType) {
      var objectType = fieldType;
      var subSelectionSet = mergeSelectionSets(fields);
      return await executeSelectionSet(
          document, subSelectionSet, objectType, result, variableValues);
    }

    // TODO: Interface/union type
    throw new UnsupportedError('Unsupported type: $fieldType');
  }

  SelectionSetContext mergeSelectionSets(List<SelectionContext> fields) {
    var selections = <SelectionContext>[];

    for (var field in fields) {
      if (field.field?.selectionSet != null) {
        selections.addAll(field.field.selectionSet.selections);
      } else if (field.inlineFragment?.selectionSet != null) {
        selections.addAll(field.inlineFragment.selectionSet.selections);
      }
    }

    return new SelectionSetContext.merged(selections);
  }

  Map<String, List<SelectionContext>> collectFields(
      DocumentContext document,
      GraphQLObjectType objectType,
      SelectionSetContext selectionSet,
      Map<String, dynamic> variableValues,
      {List visitedFragments}) {
    var groupedFields = <String, List<SelectionContext>>{};
    visitedFragments ??= [];

    for (var selection in selectionSet.selections) {
      if (getDirectiveValue('skip', 'if', selection, variableValues) == true)
        continue;
      if (getDirectiveValue('include', 'if', selection, variableValues) ==
          false) continue;

      if (selection.field != null) {
        var responseKey = selection.field.fieldName.name;
        var groupForResponseKey =
            groupedFields.putIfAbsent(responseKey, () => []);
        groupForResponseKey.add(selection);
      } else if (selection.fragmentSpread != null) {
        var fragmentSpreadName = selection.fragmentSpread.name;
        if (visitedFragments.contains(fragmentSpreadName)) continue;
        visitedFragments.add(fragmentSpreadName);
        var fragment = document.definitions
            .where((d) => d is FragmentDefinitionContext)
            .firstWhere(
                (f) =>
                    (f as FragmentDefinitionContext).name == fragmentSpreadName,
                orElse: () => null) as FragmentDefinitionContext;

        if (fragment == null) continue;
        var fragmentType = fragment.typeCondition;
        if (!doesFragmentTypeApply(objectType, fragmentType)) continue;
        var fragmentSelectionSet = fragment.selectionSet;
        var fragmentGroupFieldSet = collectFields(
            document, objectType, fragmentSelectionSet, variableValues);

        for (var responseKey in fragmentGroupFieldSet.keys) {
          var fragmentGroup = fragmentGroupFieldSet[responseKey];
          var groupForResponseKey =
              groupedFields.putIfAbsent(responseKey, () => []);
          groupForResponseKey.addAll(fragmentGroup);
        }
      } else if (selection.inlineFragment != null) {
        var fragmentType = selection.inlineFragment.typeCondition;
        if (fragmentType != null &&
            !doesFragmentTypeApply(objectType, fragmentType)) continue;
        var fragmentSelectionSet = selection.inlineFragment.selectionSet;
        var fragmentGroupFieldSet = collectFields(
            document, objectType, fragmentSelectionSet, variableValues);

        for (var responseKey in fragmentGroupFieldSet.keys) {
          var fragmentGroup = fragmentGroupFieldSet[responseKey];
          var groupForResponseKey =
              groupedFields.putIfAbsent(responseKey, () => []);
          groupForResponseKey.addAll(fragmentGroup);
        }
      }
    }

    return groupedFields;
  }

  getDirectiveValue(String name, String argumentName,
      SelectionContext selection, Map<String, dynamic> variableValues) {
    if (selection.field == null) return null;
    var directive = selection.field.directives.firstWhere((d) {
      var vv = d.valueOrVariable;
      if (vv.value != null) return vv.value.value == name;
      return vv.variable.name == name;
    }, orElse: () => null);

    if (directive == null) return null;
    if (directive.argument?.name != argumentName) return null;

    var vv = directive.argument.valueOrVariable;

    if (vv.value != null) return vv.value.value;

    var vname = vv.variable.name;
    if (!variableValues.containsKey(vname))
      throw new GraphQLException.fromSourceSpan(
          'Unknown variable: "$vname"', vv.span);

    return variableValues[vname];
  }

  bool doesFragmentTypeApply(
      GraphQLObjectType objectType, TypeConditionContext fragmentType) {
    var type = convertType(new TypeContext(fragmentType.typeName, null));
    // TODO: Handle interface type, union?

    if (type is GraphQLObjectType) {
      for (var field in type.fields)
        if (!objectType.fields.any((f) => f.name == field.name)) return false;

      return true;
    }

    return false;
  }
}
