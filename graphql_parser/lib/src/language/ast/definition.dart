import 'node.dart';

/// The base class for top-level GraphQL definitions.
abstract class DefinitionContext extends Node {}

/// An executable definition.
abstract class ExecutableDefinitionContext extends DefinitionContext {}

/// An ad-hoc type system declared in GraphQL.
abstract class TypeSystemDefinitionContext extends DefinitionContext {}

/// An extension to an existing ad-hoc type system.
abstract class TypeSystemExtensionContext extends DefinitionContext {}
