import 'package:jael/jael.dart';
import 'package:logging/logging.dart';
import 'package:symbol_table/symbol_table.dart';
import 'object.dart';

class Analyzer extends Parser {
  final Logger logger;
  Analyzer(Scanner scanner, this.logger) : super(scanner);

  final errors = <JaelError>[];
  var _scope = new SymbolTable<JaelObject>();
  var allDefinitions = <Variable<JaelObject>>[];

  SymbolTable<JaelObject> get parentScope =>
      _scope.isRoot ? _scope : _scope.parent;

  SymbolTable<JaelObject> get scope => _scope;

  bool ensureAttributeIsPresent(Element element, String name) {
    if (element.getAttribute(name) == null) {
      errors.add(new JaelError(JaelErrorSeverity.error,
          'Missing required attribute `$name`.', element.span));
      return false;
    }
    return true;
  }

  @override
  Element parseElement() {
    try {
      _scope = _scope.createChild();
      var element = super.parseElement();
      if (element == null) {
        // TODO: ???
        if (next(TokenType.lt)) {
          var tagName = parseIdentifier();
          if (tagName != null) {
            errors.add(
                new JaelError(JaelErrorSeverity.error, "Hmm", tagName.span));
          }
        }
        return null;
      }

      logger.info('!!! ${element.tagName.name}');

      // Check if any custom element exists.
      _scope
          .resolve(element.tagName.name)
          ?.value
          ?.usages
          ?.add(new SymbolUsage(SymbolUsageType.read, element.span));

      // Validate attrs
      // TODO: if, for-each

      // Validate the tag itself
      if (element is RegularElement) {
        if (element.tagName.name == 'block') {
          ensureAttributeIsPresent(element, 'name');
          logger.info('Found <block> at ${element.span.start.toolString}');
        } else if (element.tagName.name == 'case') {
          ensureAttributeIsPresent(element, 'value');
          logger.info('Found <case> at ${element.span.start.toolString}');
        } else if (element.tagName.name == 'element') {
          if (ensureAttributeIsPresent(element, 'name')) {
            var nameCtx = element.getAttribute('name').value;

            if (nameCtx is! StringLiteral) {
              errors.add(new JaelError(
                  JaelErrorSeverity.warning,
                  "`name` attribute should be a constant string literal.",
                  nameCtx.span));
            } else {
              var name = (nameCtx as StringLiteral).value;
              logger.info(
                  'Found custom element $name at ${element.span.start.toolString}');
              try {
                var symbol = parentScope.create(name,
                    value: new JaelCustomElement(name, element.tagName.span),
                    constant: true);
                allDefinitions.add(symbol);
              } on StateError catch (e) {
                errors.add(new JaelError(
                    JaelErrorSeverity.error, e.message, element.tagName.span));
              }
            }
          }
        } else if (element.tagName.name == 'extend') {
          ensureAttributeIsPresent(element, 'src');
          logger.info('Found <extend> at ${element.span.start.toolString}');
        }
      } else if (element is SelfClosingElement) {
        if (element.tagName.name == 'include') {
          logger.info('Found <include> at ${element.span.start.toolString}');
          ensureAttributeIsPresent(element, 'src');
        }
      }

      return element;
    } finally {
      _scope = _scope.parent;
      return null;
    }
  }
}
