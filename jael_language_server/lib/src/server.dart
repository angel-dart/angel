import 'dart:async';
import 'package:dart_language_server/src/protocol/language_server/interface.dart';
import 'package:dart_language_server/src/protocol/language_server/messages.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

class JaelLanguageServer extends LanguageServer {
  var _diagnostics = new StreamController<Diagnostics>();
  var _done = new Completer();
  var _memFs = new MemoryFileSystem();
  var _localFs = const LocalFileSystem();
  Directory _localRootDir;
  var _logger = new Logger('jael');
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
  Future<ServerCapabilities> initialize(int clientPid, String rootUri,
      ClientCapabilities clientCapabilities, String trace) async {
    // Find our real root dir.
    _localRootDir = _localFs.directory(rootUri);

    // Copy all real files that end in *.jael (and *.jl for legacy) into the in-memory filesystem.
    await for (var entity in _localRootDir.list(recursive: true)) {
      if (entity is File && p.extension(entity.path) == '.jael') {
        var relativePath =
            p.relative(entity.absolute.path, from: _localRootDir.absolute.path);
        var file = _memFs.file(relativePath);
        await file.create(recursive: true);
        await entity.openRead().pipe(file.openWrite(mode: FileMode.write));
        _logger.info('Found Jael file ${file.path}');
      }
    }

    return new ServerCapabilities((b) {
      b
        ..documentSymbolProvider = true
        ..documentFormattingProvider = true
        ..hoverProvider = true
        ..implementationProvider = true
        ..referencesProvider = true
        ..renameProvider = true
        ..signatureHelpProvider = new SignatureHelpOptions((b) {})
        ..textDocumentSync = new TextDocumentSyncOptions((b) {
          b
            ..change = TextDocumentSyncKind.incremental
            ..save = new SaveOptions((b) {
              b..includeText = true;
            })
            ..willSave = false;
        });
    });
  }

  @override
  Future<List> textDocumentCodeAction(TextDocumentIdentifier documentId,
      Range range, CodeActionContext context) {
    // TODO: implement textDocumentCodeAction
  }

  @override
  Future<CompletionList> textDocumentCompletion(
      TextDocumentIdentifier documentId, Position position) {
    // TODO: implement textDocumentCompletion
  }

  @override
  Future<Location> textDocumentDefinition(
      TextDocumentIdentifier documentId, Position position) {
    // TODO: implement textDocumentDefinition
  }

  @override
  Future<List<DocumentHighlight>> textDocumentHighlight(
      TextDocumentIdentifier documentId, Position position) {
    // TODO: implement textDocumentHighlight
  }

  @override
  Future textDocumentHover(
      TextDocumentIdentifier documentId, Position position) {
    // TODO: implement textDocumentHover
  }

  @override
  Future<List<Location>> textDocumentImplementation(
      TextDocumentIdentifier documentId, Position position) {
    // TODO: implement textDocumentImplementation
  }

  @override
  Future<List<Location>> textDocumentReferences(
      TextDocumentIdentifier documentId,
      Position position,
      ReferenceContext context) {
    // TODO: implement textDocumentReferences
  }

  @override
  Future<WorkspaceEdit> textDocumentRename(
      TextDocumentIdentifier documentId, Position position, String newName) {
    // TODO: implement textDocumentRename
  }

  @override
  Future<List<SymbolInformation>> textDocumentSymbols(
      TextDocumentIdentifier documentId) {
    // TODO: implement textDocumentSymbols
  }

  @override
  Future<void> workspaceExecuteCommand(String command, List arguments) {
    // TODO: implement workspaceExecuteCommand
  }

  @override
  Future<List<SymbolInformation>> workspaceSymbol(String query) {
    // TODO: implement workspaceSymbol
  }
}
