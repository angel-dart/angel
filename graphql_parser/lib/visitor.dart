import 'graphql_parser.dart';

class GraphQLVisitor {
  visitDocument(DocumentContext ctx) {
    ctx.definitions.forEach(visitDefinition);
  }

  visitDefinition(DefinitionContext ctx) {
    if (ctx is OperationDefinitionContext)
      visitOperationDefinition(ctx);
    else if (ctx is FragmentDefinitionContext) visitFragmentDefinition(ctx);
  }

  visitOperationDefinition(OperationDefinitionContext ctx) {
    if (ctx.variableDefinitions != null)
      visitVariableDefinitions(ctx.variableDefinitions);
    ctx.directives.forEach(visitDirective);
    visitSelectionSet(ctx.selectionSet);
  }

  visitFragmentDefinition(FragmentDefinitionContext ctx) {
    visitTypeCondition(ctx.typeCondition);
    ctx.directives.forEach(visitDirective);
    visitSelectionSet(ctx.selectionSet);
  }

  visitSelectionSet(SelectionSetContext ctx) {
    ctx.selections.forEach(visitSelection);
  }

  visitSelection(SelectionContext ctx) {
    if (ctx.field != null) visitField(ctx.field);
    if (ctx.fragmentSpread != null) visitFragmentSpread(ctx.fragmentSpread);
    if (ctx.inlineFragment != null) visitInlineFragment(ctx.inlineFragment);
  }

  visitInlineFragment(InlineFragmentContext ctx) {
    visitTypeCondition(ctx.typeCondition);
    ctx.directives.forEach(visitDirective);
    visitSelectionSet(ctx.selectionSet);
  }

  visitFragmentSpread(FragmentSpreadContext ctx) {
    ctx.directives.forEach(visitDirective);
  }

  visitField(FieldContext ctx) {
    visitFieldName(ctx.fieldName);
    ctx.arguments.forEach(visitArgument);
    ctx.directives.forEach(visitDirective);
    if (ctx.selectionSet != null) ;
    visitSelectionSet(ctx.selectionSet);
  }

  visitFieldName(FieldNameContext ctx) {
    if (ctx.alias != null) visitAlias(ctx.alias);
  }

  visitAlias(AliasContext ctx) {}

  visitDirective(DirectiveContext ctx) {
    if (ctx.valueOrVariable != null) visitValueOrVariable(ctx.valueOrVariable);
    if (ctx.argument != null) visitArgument(ctx.argument);
  }

  visitArgument(ArgumentContext ctx) {
    visitValueOrVariable(ctx.valueOrVariable);
  }

  visitVariableDefinitions(VariableDefinitionsContext ctx) {
    ctx.variableDefinitions.forEach(visitVariableDefinition);
  }

  visitVariableDefinition(VariableDefinitionContext ctx) {
    visitVariable(ctx.variable);
    visitType(ctx.type);
    if (ctx.defaultValue != null) visitDefaultValue(ctx.defaultValue);
  }

  visitVariable(VariableContext ctx) {}

  visitValueOrVariable(ValueOrVariableContext ctx) {
    if (ctx.variable != null) visitVariable(ctx.variable);
    if (ctx.value != null) visitValue(ctx.value);
  }

  visitDefaultValue(DefaultValueContext ctx) {
    visitValue(ctx.value);
  }

  visitValue(ValueContext ctx) {
    if (ctx is StringValueContext)
      visitStringValue(ctx);
    else if (ctx is NumberValueContext)
      visitNumberValue(ctx);
    else if (ctx is BooleanValueContext)
      visitBooleanValue(ctx);
    else if (ctx is ListValueContext) visitArrayValue(ctx);
  }

  visitStringValue(StringValueContext ctx) {}

  visitBooleanValue(BooleanValueContext ctx) {}

  visitNumberValue(NumberValueContext ctx) {}

  visitArrayValue(ListValueContext ctx) {
    ctx.values.forEach(visitValue);
  }

  visitTypeCondition(TypeConditionContext ctx) {
    visitTypeName(ctx.typeName);
  }

  visitType(TypeContext ctx) {
    if (ctx.typeName != null) visitTypeName(ctx.typeName);
    if (ctx.listType != null) visitListType(ctx.listType);
  }

  visitListType(ListTypeContext ctx) {
    visitType(ctx.type);
  }

  visitTypeName(TypeNameContext ctx) {}
}
