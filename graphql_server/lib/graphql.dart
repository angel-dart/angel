import 'package:graphql_parser/graphql_parser.dart';
import 'package:graphql_schema/graphql_schema.dart';

class GraphQL {
  final Map<String, GraphQLType> customTypes = {};
  final GraphQLSchema schema;

  GraphQL(this.schema) {
    if (schema.query != null) customTypes[schema.query.name] = schema.query;
    if (schema.mutation != null)
      customTypes[schema.mutation.name] = schema.mutation;
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
          if (customTypes.containsKey(ctx.typeName.name))
            return customTypes[ctx.typeName.name];
          throw new ArgumentError(
              'Unknown GraphQL type: "${ctx.typeName.name}"\n${ctx.span
                  .highlight()}');
          break;
      }
    } else {
      throw new ArgumentError(
          'Invalid GraphQL type: "${ctx.span.text}"\n${ctx.span.highlight()}');
    }
  }

  executeRequest(
      GraphQLSchema schema, DocumentContext document, String operationName,
      {Map<String, dynamic> variableValues: const {}, initialValue}) {
    var operation = getOperation(document, operationName);
    var coercedVariableValues =
    coerceVariableValues(schema, operation, variableValues ?? {});
    if (operation.isQuery)
      return executeQuery(
          document, operation, schema, coercedVariableValues, initialValue);
    else
      return executeMutation(
          document, operation, schema, coercedVariableValues, initialValue);
  }

  OperationDefinitionContext getOperation(
      DocumentContext document, String operationName) {
    var ops = document.definitions.whereType<OperationDefinitionContext>();

    if (operationName == null) {
      return ops.length == 1
          ? ops.first
          : throw new GraphQLException(
          'Missing required operation "$operationName".');
    } else {
      return ops.firstWhere((d) => d.name == operationName,
          orElse: () => throw new GraphQLException(
              'Missing required operation "$operationName".'));
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
          throw new GraphQLException(
              'Missing required variable "$variableName".');
        }
      } else {
        var type = convertType(variableType);
        var validation = type.validate(variableName, value);

        if (!validation.successful) {
          throw new GraphQLException(validation.errors[0]);
        } else {
          coercedValues[variableName] = type.deserialize(value);
        }
      }
    }

    return coercedValues;
  }

  GraphQLResult executeQuery(
      DocumentContext document,
      OperationDefinitionContext query,
      GraphQLSchema schema,
      Map<String, dynamic> variableValues,
      initialValue) {
    var queryType = schema.query;
    var selectionSet = query.selectionSet;
    return executeSelectionSet(
        document, selectionSet, queryType, initialValue, variableValues);
  }

  Map<String, dynamic> executeSelectionSet(
      DocumentContext document,
      SelectionSetContext selectionSet,
      GraphQLObjectType objectType,
      objectValue,
      Map<String, dynamic> variableValues) {
    var groupedFieldSet =
    collectFields(document, objectType, selectionSet, variableValues);
    var resultMap = <String, dynamic>{};

    for (var responseKey in groupedFieldSet.keys) {
      var fields = groupedFieldSet[responseKey];

      for (var field in fields) {
        var fieldName = field.field.fieldName.name;
        var fieldType =
            objectType.fields.firstWhere((f) => f.name == fieldName)?.type;
        if (fieldType == null) continue;
        var responseValue = executeField(
            objectType, objectValue, fields, fieldType, variableValues);
        resultMap[responseKey] = responseValue;
      }
    }

    return resultMap;
  }

  executeField(
      GraphQLObjectType objectType,
      objectValue,
      List<SelectionContext> fields,
      GraphQLType fieldType,
      Map<String, dynamic> variableValues) {
    var field = fields[0];
    var argumentValues =
    coerceArgumentValues(objectType, field, variableValues);
    var resolvedValue = resolveFieldValue(
        objectType, objectValue, field.field.fieldName.name, argumentValues);
    return completeValue(fieldType, fields, resolvedValue, variableValues);
  }

  Map<String, dynamic> coerceArgumentValues(GraphQLObjectType objectType,
      SelectionContext field, Map<String, dynamic> variableValues) {
    var coercedValues = <String, dynamic>{};
    var argumentValues = field.field.arguments;
    var fieldName = field.field.fieldName.name;
    var desiredField = objectType.fields.firstWhere((f) => f.name == fieldName);

    // TODO: Multiple arguments?
    var argumentDefinitions = desiredField.argument;

    return coercedValues;
  }

  Map<String, List<SelectionContext>> collectFields(
      DocumentContext document,
      GraphQLObjectType objectType,
      SelectionSetContext selectionSet,
      Map<String, dynamic> variableValues,
      {List visitedFragments: const []}) {
    var groupedFields = <String, List<SelectionContext>>{};

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
            .whereType<FragmentDefinitionContext>()
            .firstWhere((f) => f.name == fragmentSpreadName,
            orElse: () => null);

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
      throw new GraphQLException(
          'Unknown variable: "$vname"\n${vv.variable.span.highlight()}');

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

class GraphQLException extends FormatException {
  GraphQLException(String message) : super(message);
}