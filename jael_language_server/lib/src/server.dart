import 'dart:async';
import 'package:dart_language_server/src/protocol/language_server/interface.dart';
import 'package:dart_language_server/src/protocol/language_server/messages.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:jael/jael.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc_2;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:source_span/source_span.dart';
import 'package:string_scanner/string_scanner.dart';
import 'package:symbol_table/symbol_table.dart';
import 'analyzer.dart';
import 'formatter.dart';
import 'object.dart';

class JaelLanguageServer extends LanguageServer {
  var _diagnostics = new StreamController<Diagnostics>();
  var _done = new Completer();
  var _memFs = new MemoryFileSystem();
  var _localFs = const LocalFileSystem();
  Directory _localRootDir, _memRootDir;
  var logger = new Logger('jael');
  Uri _rootUri;
  var _workspaceEdits = new StreamController<ApplyWorkspaceEditParams>();

  @override
  Stream<Diagnostics> get diagnostics => _diagnostics.stream;

  @override
  Future<void> get onDone => _done.future;

  @override
  Stream<ApplyWorkspaceEditParams> get workspaceEdits => _workspaceEdits.stream;

  @override
  Future<void> shutdown() {
    if (!_done.isCompleted) _done.complete();
    _diagnostics.close();
    _workspaceEdits.close();
    return super.shutdown();
  }

  @override
  void setupExtraMethods(json_rpc_2.Peer peer) {
    peer.registerMethod('textDocument/formatting',
        (json_rpc_2.Parameters params) async {
      var documentId =
          new TextDocumentIdentifier.fromJson(params['textDocument'].asMap);
      var formattingOptions =
          new FormattingOptions.fromJson(params['options'].asMap);
      return await textDocumentFormatting(documentId, formattingOptions);
    });
  }

  @override
  Future<ServerCapabilities> initialize(int clientPid, String rootUri,
      ClientCapabilities clientCapabilities, String trace) async {
    // Find our real root dir.
    _localRootDir = _localFs.directory(_rootUri = Uri.parse(rootUri));
    _memRootDir = _memFs.directory('/');
    await _memRootDir.create(recursive: true);
    _memFs.currentDirectory = _memRootDir;

    // Copy all real files that end in *.jael (and *.jl for legacy) into the in-memory filesystem.
    await for (var entity in _localRootDir.list(recursive: true)) {
      if (entity is File && p.extension(entity.path) == '.jael') {
        logger.info('HEY ${entity.path}');
        var file = _memFs.file(entity.absolute.path);
        await file.create(recursive: true);
        await entity.openRead().pipe(file.openWrite(mode: FileMode.write));
        logger.info(
            'Found Jael file ${file.path}; copied to ${file.absolute.path}');

        // Analyze it
        var documentId = new TextDocumentIdentifier((b) {
          b..uri = _rootUri.replace(path: file.path).toString();
        });

        await analyzerForId(documentId);
      }
    }

    return new ServerCapabilities((b) {
      b
        ..codeActionProvider = false
        ..completionProvider = new CompletionOptions((b) {
          b
            ..resolveProvider = true
            ..triggerCharacters =
                'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdeghijklmnopqrstuvxwyz'
                    .codeUnits
                    .map((c) => new String.fromCharCode(c))
                    .toList();
        })
        ..definitionProvider = true
        ..documentHighlightProvider = true
        ..documentRangeFormattingProvider = false
        ..documentOnTypeFormattingProvider = null
        ..documentSymbolProvider = true
        ..documentFormattingProvider = true
        ..hoverProvider = true
        ..implementationProvider = true
        ..referencesProvider = true
        ..renameProvider = true
        ..signatureHelpProvider = new SignatureHelpOptions((b) {})
        ..textDocumentSync = new TextDocumentSyncOptions((b) {
          b
            ..openClose = true
            ..change = TextDocumentSyncKind.full
            ..save = new SaveOptions((b) {
              b..includeText = false;
            })
            ..willSave = false
            ..willSaveWaitUntil = false;
        })
        ..workspaceSymbolProvider = true;
    });
  }

  Future<File> fileForId(TextDocumentIdentifier documentId) async {
    var uri = Uri.parse(documentId.uri);
    var relativePath = uri.path;
    var file = _memFs.directory('/').childFile(relativePath);

    /*
    logger.info('Searching for $relativePath. All:\n');

    await for (var entity in _memFs.directory('/').list(recursive: true)) {
      if (entity is File) print(' * ${entity.absolute.path}');
    }
    */

    if (!await file.exists()) {
      await file.create(recursive: true);
      await _localFs.file(uri).openRead().pipe(file.openWrite());
      logger.info('Opened Jael file ${file.path}');
    }

    return file;
  }

  Future<Scanner> scannerForId(TextDocumentIdentifier documentId) async {
    var file = await fileForId(documentId);
    return scan(await file.readAsString(), sourceUrl: file.uri);
  }

  Future<Analyzer> analyzerForId(TextDocumentIdentifier documentId) async {
    var scanner = await scannerForId(documentId);
    var analyzer = new Analyzer(scanner, logger)..errors.addAll(scanner.errors);
    analyzer.parseDocument();
    emitDiagnostics(documentId.uri, analyzer.errors.map(toDiagnostic).toList());
    return analyzer;
  }

  Diagnostic toDiagnostic(JaelError e) {
    return new Diagnostic((b) {
      b
        ..message = e.message
        ..range = toRange(e.span)
        ..severity = toSeverity(e.severity)
        ..source = e.span.start.sourceUrl.toString();
    });
  }

  int toSeverity(JaelErrorSeverity s) {
    switch (s) {
      case JaelErrorSeverity.warning:
        return DiagnosticSeverity.warning;
      default:
        return DiagnosticSeverity.error;
    }
  }

  Range toRange(FileSpan span) {
    return new Range((b) {
      b
        ..start = toPosition(span.start)
        ..end = toPosition(span.end);
    });
  }

  Range emptyRange() {
    return new Range((b) => b
      ..start = b.end = new Position((b) {
        b
          ..character = 1
          ..line = 0;
      }));
  }

  Position toPosition(SourceLocation location) {
    return new Position((b) {
      b
        ..line = location.line
        ..character = location.column;
    });
  }

  Location toLocation(String uri, FileSpan span) {
    return new Location((b) {
      b
        ..range = toRange(span)
        ..uri = uri;
    });
  }

  bool isReachable(JaelObject obj, Position position) {
    return obj.span.start.line <= position.line &&
        obj.span.start.column <= position.character;
  }

  CompletionItem toCompletion(Variable<JaelObject> symbol) {
    var value = symbol.value;

    if (value is JaelCustomElement) {
      var name = value.name;
      return new CompletionItem((b) {
        b
          ..kind = CompletionItemKind.classKind
          ..label = symbol.name
          ..textEdit = new TextEdit((b) {
            b
              ..range = emptyRange()
              ..newText = '<$name\$1>\n    \$2\n</name>';
          });
      });
    } else if (value is JaelVariable) {
      return new CompletionItem((b) {
        b
          ..kind = CompletionItemKind.variable
          ..label = symbol.name;
      });
    }

    return null;
  }

  void emitDiagnostics(String uri, Iterable<Diagnostic> diagnostics) {
    _diagnostics.add(new Diagnostics((b) {
      logger.info('$uri => ${diagnostics.map((d) => d.message).toList()}');
      b
        ..diagnostics = diagnostics.toList()
        ..uri = uri.toString();
    }));
  }

  @override
  Future textDocumentDidOpen(TextDocumentItem document) async {
    await analyzerForId(
        new TextDocumentIdentifier((b) => b..uri = document.uri));
  }

  @override
  Future textDocumentDidChange(VersionedTextDocumentIdentifier documentId,
      List<TextDocumentContentChangeEvent> changes) async {
    var id = new TextDocumentIdentifier((b) => b..uri = documentId.uri);
    var file = await fileForId(id);

    for (var change in changes) {
      if (change.text != null) {
        await file.writeAsString(change.text);
      } else if (change.range != null) {
        var contents = await file.readAsString();

        int findIndex(Position position) {
          var lines = contents.split('\n');

          // Sum the length of the previous lines.
          int lineLength = lines
              .take(position.line - 1)
              .map((s) => s.length)
              .reduce((a, b) => a + b);
          return lineLength + position.character - 1;
        }

        if (change.range == null) {
          contents = change.text;
        } else {
          var start = findIndex(change.range.start),
              end = findIndex(change.range.end);
          contents = contents.replaceRange(start, end, change.text);
        }

        logger.info('${file.path} => $contents');
        await file.writeAsString(contents);
      }
    }

    await analyzerForId(id);
  }

  @override
  Future<List> textDocumentCodeAction(TextDocumentIdentifier documentId,
      Range range, CodeActionContext context) async {
    // TODO: implement textDocumentCodeAction
    return [];
  }

  @override
  Future<CompletionList> textDocumentCompletion(
      TextDocumentIdentifier documentId, Position position) async {
    var analyzer = await analyzerForId(documentId);
    var symbols = analyzer.scope.allVariables;
    var reachable = symbols.where((s) => isReachable(s.value, position));
    return new CompletionList((b) {
      b
        ..isIncomplete = false
        ..items = reachable.map(toCompletion).toList();
    });
  }

  final RegExp _id =
      new RegExp(r'(([A-Za-z][A-Za-z0-9_]*-)*([A-Za-z][A-Za-z0-9_]*))');

  Future<String> currentName(
      TextDocumentIdentifier documentId, Position position) async {
    // First, read the file.
    var file = await fileForId(documentId);
    var contents = await file.readAsString();

    // Next, find the current index.
    var scanner = new SpanScanner(contents);

    while (!scanner.isDone &&
        (scanner.state.line != position.line ||
            scanner.state.column != position.character)) {
      scanner.readChar();
    }

    // Next, just read the name.
    if (scanner.matches(_id)) {
      var longest = scanner.lastSpan.text;

      while (scanner.matches(_id) && scanner.position > 0 && !scanner.isDone) {
        longest = scanner.lastSpan.text;
        scanner.position--;
      }

      return longest;
    } else {
      return null;
    }
  }

  Future<JaelObject> currentSymbol(
      TextDocumentIdentifier documentId, Position position) async {
    var name = await currentName(documentId, position);
    if (name == null) return null;
    var analyzer = await analyzerForId(documentId);
    var symbols = analyzer.allDefinitions ?? analyzer.scope.allVariables;
    logger
        .info('Current symbols, seeking $name: ${symbols.map((v) => v.name)}');
    return analyzer.scope.resolve(name)?.value;
  }

  @override
  Future<Location> textDocumentDefinition(
      TextDocumentIdentifier documentId, Position position) async {
    var symbol = await currentSymbol(documentId, position);
    if (symbol != null) {
      return toLocation(documentId.uri, symbol.span);
    }
    return null;
  }

  @override
  Future<List<DocumentHighlight>> textDocumentHighlight(
      TextDocumentIdentifier documentId, Position position) async {
    var symbol = await currentSymbol(documentId, position);
    if (symbol != null) {
      return symbol.usages.map((u) {
        return new DocumentHighlight((b) {
          b
            ..range = toRange(u.span)
            ..kind = u.type == SymbolUsageType.definition
                ? DocumentHighlightKind.write
                : DocumentHighlightKind.read;
        });
      }).toList();
    }
    return [];
  }

  @override
  Future<Hover> textDocumentHover(
      TextDocumentIdentifier documentId, Position position) async {
    var symbol = await currentSymbol(documentId, position);
    if (symbol != null) {
      return new Hover((b) {
        b
          ..contents = symbol.span.text
          ..range = toRange(symbol.span);
      });
    }

    return null;
  }

  @override
  Future<List<Location>> textDocumentImplementation(
      TextDocumentIdentifier documentId, Position position) async {
    var defn = await textDocumentDefinition(documentId, position);
    return defn == null ? [] : [defn];
  }

  @override
  Future<List<Location>> textDocumentReferences(
      TextDocumentIdentifier documentId,
      Position position,
      ReferenceContext context) async {
    var symbol = await currentSymbol(documentId, position);
    if (symbol != null) {
      return symbol.usages.map((u) {
        return toLocation(documentId.uri, u.span);
      }).toList();
    }

    return [];
  }

  @override
  Future<WorkspaceEdit> textDocumentRename(TextDocumentIdentifier documentId,
      Position position, String newName) async {
    var symbol = await currentSymbol(documentId, position);
    if (symbol != null) {
      return new WorkspaceEdit((b) {
        b
          ..changes = {
            symbol.name: symbol.usages.map((u) {
              return new TextEdit((b) {
                b
                  ..range = toRange(u.span)
                  ..newText = (symbol is JaelCustomElement &&
                          u.type == SymbolUsageType.definition)
                      ? '"$newName"'
                      : newName;
              });
            }).toList()
          };
      });
    }
    return new WorkspaceEdit((b) {
      b..changes = {};
    });
  }

  @override
  Future<List<SymbolInformation>> textDocumentSymbols(
      TextDocumentIdentifier documentId) async {
    var analyzer = await analyzerForId(documentId);
    return analyzer.allDefinitions.map((symbol) {
      return new SymbolInformation((b) {
        b
          ..kind = SymbolKind.classSymbol
          ..name = symbol.name
          ..location = toLocation(documentId.uri, symbol.value.span);
      });
    }).toList();
  }

  @override
  Future<void> workspaceExecuteCommand(String command, List arguments) async {
    // TODO: implement workspaceExecuteCommand
  }

  @override
  Future<List<SymbolInformation>> workspaceSymbol(String query) async {
    var values = <JaelObject>[];

    await for (var file in _memRootDir.list(recursive: true)) {
      if (file is File) {
        var id = new TextDocumentIdentifier((b) {
          b..uri = file.uri.toString();
        });
        var analyzer = await analyzerForId(id);
        values.addAll(analyzer.allDefinitions.map((v) => v.value));
      }
    }

    return values.map((o) {
      return new SymbolInformation((b) {
        b
          ..name = o.name
          ..location = toLocation(o.span.sourceUrl.toString(), o.span)
          ..containerName = p.basename(o.span.sourceUrl.path)
          ..kind = o is JaelCustomElement
              ? SymbolKind.classSymbol
              : SymbolKind.variable;
      });
    }).toList();
  }

  Future<List<TextEdit>> textDocumentFormatting(
      TextDocumentIdentifier documentId,
      FormattingOptions formattingOptions) async {
    try {
      var errors = <JaelError>[];
      var file = await fileForId(documentId);
      var contents = await file.readAsString();
      var document =
          parseDocument(contents, sourceUrl: file.uri, onError: errors.add);
      if (errors.isNotEmpty) return null;
      var formatter = new JaelFormatter(
          formattingOptions.tabSize, formattingOptions.insertSpaces);
      var formatted = formatter.apply(document);
      logger.info('Original:${contents}\nFormatted:\n$formatted');
      if (formatted.isNotEmpty) await file.writeAsString(formatted);
      return [
        new TextEdit((b) {
          b
            ..newText = formatted
            ..range = document == null ? emptyRange() : toRange(document.span);
        })
      ];
    } catch (e, st) {
      logger.severe('Formatter error', e, st);
      return null;
    }
  }
}

abstract class DiagnosticSeverity {
  static const int error = 0, warning = 1, information = 2, hint = 3;
}

class FormattingOptions {
  final num tabSize;

  final bool insertSpaces;

  FormattingOptions(this.tabSize, this.insertSpaces);

  factory FormattingOptions.fromJson(Map json) {
    return new FormattingOptions(
        json['tabSize'] as num, json['insertSpaces'] as bool);
  }
}
