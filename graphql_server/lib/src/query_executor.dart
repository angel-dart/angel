import 'package:graphql_parser/graphql_parser.dart';
import 'package:symbol_table/symbol_table.dart';

class GraphQLQueryExecutor {
  const GraphQLQueryExecutor();

  Map<String, dynamic> visitDocument(DocumentContext ctx, Map<String, dynamic> inputData) {
    var scope = new SymbolTable();
    return ctx.definitions.fold(inputData, (o, def) {
      var result = visitDefinition(def, o, scope);
      return result ?? o;
    });
  }

  Map<String, dynamic> visitDefinition(
      DefinitionContext ctx, inputData, SymbolTable scope) {
    if (ctx is OperationDefinitionContext)
      return visitOperationDefinition(ctx, inputData, scope);
    else if (ctx is FragmentDefinitionContext)
      return visitFragmentDefinition(ctx, inputData, scope);
    else
      throw new UnsupportedError('Unsupported definition: $ctx');
  }

  Map<String, dynamic> visitOperationDefinition(
      OperationDefinitionContext ctx, inputData, SymbolTable scope) {
    // Add variable definitions
    ctx.variableDefinitions?.variableDefinitions?.forEach((def) {
      scope.assign(def.variable.name, def.defaultValue?.value?.value);
    });

    callback(o, SelectionContext sel) {
      var result = visitSelection(sel, o, scope);
      return result ?? o;
    }

    if (inputData is List) {
      return {
        'data': inputData.map((x) {
          return ctx.selectionSet.selections.fold(x, callback);
        }).toList()
      };
    } else if (inputData is Map) {
      return {'data': ctx.selectionSet.selections.fold(inputData, callback)};
    } else
      throw new UnsupportedError(
          'Cannot execute GraphQL queries against $inputData.');
  }

  Map<String, dynamic> visitFragmentDefinition(
      FragmentDefinitionContext ctx, inputData, SymbolTable scope) {}

  visitSelection(SelectionContext ctx, inputData, SymbolTable scope) {
    if (inputData is! Map && inputData is! List)
      return inputData;
    else if (inputData is List)
      return inputData.map((x) => visitSelection(ctx, x, scope)).toList();

    if (ctx.field != null)
      return visitField(ctx.field, inputData, scope);
    // TODO: Spread, inline fragment
    else
      throw new UnsupportedError('Unsupported selection: $ctx');
  }

  visitField(FieldContext ctx, inputData, SymbolTable scope, [value]) {
    bool hasValue = value != null;
    var s = scope.createChild();
    Map out = {};

    value ??= inputData[ctx.fieldName.name];

    // Apply arguments to query lists...
    if (ctx.arguments.isNotEmpty) {
      var listSearch = value is List ? value : inputData;

      if (listSearch is! List)
        throw new UnsupportedError('Arguments are only supported on Lists.');
      value = listSearch.firstWhere((x) {
        if (x is! Map)
          return null;
        else {
          return ctx.arguments.every((a) {
            var value;

            if (a.valueOrVariable.value != null)
              value = a.valueOrVariable.value.value;
            else {
              // TODO: Unknown key
              value = scope.resolve(a.valueOrVariable.variable.name).value;
            }

            // print('Looking for ${a.name} == $value in $x');
            return x[a.name] == value;
          });
        }
      }, orElse: () => null);
    }

    if (value == null) {
      //print('Why is ${ctx.fieldName.name} null in $inputData??? hasValue: $hasValue');
      return value;
    }

    if (ctx.selectionSet == null) return value;

    var target = {};

    for (var selection in ctx.selectionSet.selections) {
      if (selection.field != null) {
        // Get the corresponding data
        var key = selection.field.fieldName.name;
        var childValue = value[key];

        if (childValue is! List && childValue is! Map)
          target[key] = childValue;
        else {
          applyFieldSelection(x, [root]) {
            //print('Select ${selection.field.fieldName.name} from $x');
            return visitField(selection.field, root ?? x, s, x);
          }

          var output = childValue is List
              ? childValue
              .map((x) => applyFieldSelection(x, childValue))
              .toList()
              : applyFieldSelection(childValue);
          //print('$key => $output');
          target[key] = output;
        }
      }
      // TODO: Spread, inline fragment
    }

    // Set this as the value within the current scope...
    if (hasValue) {
      return target;
    } else
      out[ctx.fieldName.name] = target;
    s.create(ctx.fieldName.name, value: target);

    return out;
  }
}