import 'dart:async';
import 'dart:convert';
import 'package:barback/barback.dart';
import 'package:analyzer/analyzer.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:file/local.dart';
import 'angel_configuration.dart';

class ConfigurationTransformer extends Transformer {
  final BarbackSettings _settings;

  @override
  String get allowedExtensions => ".dart";

  ConfigurationTransformer.asPlugin(this._settings) {}

  Future apply(Transform transform) async {
    try {
      var app = new Angel();

      await app.configure(configuration(
        const LocalFileSystem(),
        directoryPath: _settings.configuration["dir"] ?? "./config",
        overrideEnvironmentName: _settings.configuration["env"],
      ));

      var text = await transform.primaryInput.readAsString();
      var compilationUnit = parseCompilationUnit(text);
      var visitor = new ConfigAstVisitor(app.properties);
      visitor.visitCompilationUnit(compilationUnit);

      await for (Map replaced in visitor.onReplaced) {
        text = text.replaceAll(replaced["needle"], replaced["with"]);
      }

      transform
          .addOutput(new Asset.fromString(transform.primaryInput.id, text));
    } catch (e) {
      // Fail silently...
    }
  }
}

class ConfigAstVisitor extends GeneralizingAstVisitor {
  Map _config;
  var _onReplaced = new StreamController<Map>();
  String _prefix = "";
  Stream<Map> get onReplaced => _onReplaced.stream;

  ConfigAstVisitor(this._config);

  bool isConfigMethod(Expression function) =>
      function is SimpleIdentifier && function.name == "${_prefix}config";

  resolveItem(String key) {
    var split = key.split(".");
    var parent = _config;

    for (int i = 0; i < split.length; i++) {
      if (parent != null && parent is Map) parent = parent[split[i]];
    }

    return parent;
  }

  @override
  visitCompilationUnit(CompilationUnit ctx) {
    var result = super.visitCompilationUnit(ctx);
    _onReplaced.close();
    return result;
  }

  @override
  visitImportDirective(ImportDirective ctx) {
    String uri = ctx.uri.stringValue;

    if (uri == "package:angel_configuration/browser.dart") {
      _onReplaced.add({"needle": ctx.toString(), "with": ""});

      if (ctx.asKeyword != null) {
        _prefix = ctx.prefix.name;
      }
    }

    return super.visitImportDirective(ctx);
  }

  @override
  visitExpression(Expression ctx) {
    if (ctx is MethodInvocation) {
      if (isConfigMethod(ctx.function)) {
        StringLiteral key = ctx.argumentList.arguments[0];
        var resolved = resolveItem(key.stringValue);

        _onReplaced
            .add({"needle": ctx.toString(), "with": JSON.encode(resolved)});
      }
    }
    return super.visitExpression(ctx);
  }
}
