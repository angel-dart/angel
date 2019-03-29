import 'node.dart';

abstract class DefinitionContext extends Node {}

abstract class ExecutableDefinitionContext extends DefinitionContext {}

abstract class TypeSystemDefinitionContext extends DefinitionContext {}

abstract class TypeSystemExtensionContext extends DefinitionContext {}
