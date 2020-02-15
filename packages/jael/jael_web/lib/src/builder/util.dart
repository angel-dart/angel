import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:file/file.dart';
import 'package:path/src/context.dart';

/// Converts a [DartType] to a [TypeReference].
TypeReference convertTypeReference(DartType t) {
  return new TypeReference((b) {
    b..symbol = t.name;

    if (t is InterfaceType) {
      b.types.addAll(t.typeArguments.map(convertTypeReference));
    }
  });
}

bool isRequiredParameter(ParameterElement e) {
  return e.isNotOptional;
}

bool isOptionalParameter(ParameterElement e) {
  return e.isOptional;
}

Parameter convertParameter(ParameterElement e) {
  return Parameter((b) {
    b
      ..name = e.name
      ..type = convertTypeReference(e.type)
      ..named = e.isNamed
      ..defaultTo =
          e.defaultValueCode == null ? null : Code(e.defaultValueCode);
  });
}

UnsupportedError _unsupported() =>
    UnsupportedError('Not support in R/O build file system.');

class BuildFileSystem extends FileSystem {
  final AssetReader reader;
  final String package;
  Context _path = Context();

  BuildFileSystem(this.reader, this.package);

  Context get path => _path;

  @override
  Directory get currentDirectory {
    return BuildSystemDirectory(this, reader, package, _path.current);
  }

  set currentDirectory(value) {
    if (value is Directory) {
      _path = Context(current: value.path);
    } else if (value is String) {
      _path = Context(current: value);
    } else {
      throw ArgumentError();
    }
  }

  @override
  Directory directory(path) {
    String p;
    if (path is String)
      p = path;
    else if (path is Uri)
      p = p.toString();
    else if (path is FileSystemEntity)
      p = path.path;
    else
      throw ArgumentError();
    return BuildSystemDirectory(this, reader, package, p);
  }

  @override
  File file(path) {
    String p;
    if (path is String)
      p = path;
    else if (path is Uri)
      p = p.toString();
    else if (path is FileSystemEntity)
      p = path.path;
    else
      throw ArgumentError();
    return BuildSystemFile(this, reader, package, p);
  }

  @override
  Future<bool> identical(String path1, String path2) => throw _unsupported();

  @override
  bool identicalSync(String path1, String path2) => throw _unsupported();

  @override
  bool get isWatchSupported => false;

  @override
  Link link(path) => throw _unsupported();

  @override
  Future<FileStat> stat(String path) => throw _unsupported();

  @override
  FileStat statSync(String path) => throw _unsupported();

  @override
  Directory get systemTempDirectory => throw _unsupported();

  @override
  Future<FileSystemEntityType> type(String path, {bool followLinks = true}) =>
      throw _unsupported();

  @override
  FileSystemEntityType typeSync(String path, {bool followLinks = true}) =>
      throw _unsupported();
}

class BuildSystemFile extends File {
  final BuildFileSystem fileSystem;
  final AssetReader reader;
  final String package;
  final String path;

  BuildSystemFile(this.fileSystem, this.reader, this.package, this.path);

  Uri get uri => fileSystem.path.toUri(path);

  @override
  File get absolute => this;

  @override
  String get basename => fileSystem.path.basename(path);

  @override
  Future<File> copy(String newPath) => throw _unsupported();

  @override
  File copySync(String newPath) => throw _unsupported();

  @override
  Future<File> create({bool recursive = false}) => throw _unsupported();

  @override
  void createSync({bool recursive = false}) => throw _unsupported();

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      throw _unsupported();

  @override
  void deleteSync({bool recursive = false}) => throw _unsupported();

  @override
  String get dirname => fileSystem.path.dirname(path);

  @override
  Future<bool> exists() => throw _unsupported();
  @override
  bool existsSync() => throw _unsupported();

  @override
  bool get isAbsolute => true;

  @override
  Future<DateTime> lastAccessed() => throw _unsupported();

  @override
  DateTime lastAccessedSync() => throw _unsupported();

  @override
  Future<DateTime> lastModified() => throw _unsupported();

  @override
  DateTime lastModifiedSync() => throw _unsupported();

  @override
  Future<int> length() => throw _unsupported();
  @override
  int lengthSync() => throw _unsupported();

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) =>
      throw _unsupported();

  @override
  Stream<List<int>> openRead([int start, int end]) => throw _unsupported();

  @override
  RandomAccessFile openSync({FileMode mode = FileMode.read}) =>
      throw _unsupported();

  @override
  IOSink openWrite(
          {FileMode mode = FileMode.write, Encoding encoding = utf8}) =>
      throw _unsupported();

  @override
  Directory get parent => BuildSystemDirectory(
      fileSystem, reader, package, fileSystem.path.dirname(path));

  @override
  Future<List<int>> readAsBytes() {
    var assetId = AssetId(package, path);
    return reader.readAsBytes(assetId);
  }

  @override
  List<int> readAsBytesSync() => throw _unsupported();
  @override
  Future<List<String>> readAsLines({Encoding encoding = utf8}) =>
      throw _unsupported();

  @override
  List<String> readAsLinesSync({Encoding encoding = utf8}) =>
      throw _unsupported();

  @override
  Future<String> readAsString({Encoding encoding = utf8}) {
    var assetId = AssetId(package, path);
    return reader.readAsString(assetId);
  }

  @override
  String readAsStringSync({Encoding encoding = utf8}) => throw _unsupported();

  @override
  Future<File> rename(String newPath) => throw _unsupported();

  @override
  File renameSync(String newPath) => throw _unsupported();

  @override
  Future<String> resolveSymbolicLinks() => throw _unsupported();

  @override
  String resolveSymbolicLinksSync() => throw _unsupported();

  @override
  Future setLastAccessed(DateTime time) => throw _unsupported();

  @override
  void setLastAccessedSync(DateTime time) => throw _unsupported();

  @override
  Future setLastModified(DateTime time) => throw _unsupported();

  @override
  void setLastModifiedSync(DateTime time) => throw _unsupported();

  @override
  Future<FileStat> stat() => throw _unsupported();

  @override
  FileStat statSync() => throw _unsupported();

  @override
  Stream<FileSystemEvent> watch(
          {int events = FileSystemEvent.all, bool recursive = false}) =>
      throw _unsupported();

  @override
  Future<File> writeAsBytes(List<int> bytes,
          {FileMode mode = FileMode.write, bool flush = false}) =>
      throw _unsupported();

  @override
  void writeAsBytesSync(List<int> bytes,
          {FileMode mode = FileMode.write, bool flush = false}) =>
      throw _unsupported();

  @override
  Future<File> writeAsString(String contents,
          {FileMode mode = FileMode.write,
          Encoding encoding = utf8,
          bool flush = false}) =>
      throw _unsupported();

  @override
  void writeAsStringSync(String contents,
          {FileMode mode = FileMode.write,
          Encoding encoding = utf8,
          bool flush = false}) =>
      throw _unsupported();
}

class BuildSystemDirectory extends Directory {
  final BuildFileSystem fileSystem;
  final AssetReader reader;
  final String package;
  final String path;

  BuildSystemDirectory(this.fileSystem, this.reader, this.package, this.path);

  @override
  Directory get absolute => this;

  @override
  String get basename => fileSystem.path.basename(path);

  @override
  Directory childDirectory(String basename) {
    return BuildSystemDirectory(
        fileSystem, reader, package, fileSystem.path.join(path, basename));
  }

  @override
  File childFile(String basename) {
    return BuildSystemFile(
        fileSystem, reader, package, fileSystem.path.join(path, basename));
  }

  @override
  Link childLink(String basename) => throw _unsupported();

  @override
  Future<Directory> create({bool recursive = false}) => throw _unsupported();

  @override
  void createSync({bool recursive = false}) => throw _unsupported();

  @override
  Future<Directory> createTemp([String prefix]) => throw _unsupported();

  @override
  Directory createTempSync([String prefix]) => throw _unsupported();

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      throw _unsupported();

  @override
  void deleteSync({bool recursive = false}) => throw _unsupported();

  @override
  String get dirname => fileSystem.path.dirname(path);

  @override
  Future<bool> exists() => throw _unsupported();

  @override
  bool existsSync() => throw _unsupported();

  @override
  bool get isAbsolute => true;

  @override
  Stream<FileSystemEntity> list(
          {bool recursive = false, bool followLinks = true}) =>
      throw _unsupported();

  @override
  List<FileSystemEntity> listSync(
          {bool recursive = false, bool followLinks = true}) =>
      throw _unsupported();

  @override
  Directory get parent {
    return BuildSystemDirectory(
        fileSystem, reader, package, fileSystem.path.dirname(path));
  }

  @override
  Future<Directory> rename(String newPath) => throw _unsupported();

  @override
  Directory renameSync(String newPath) => throw _unsupported();

  @override
  Future<String> resolveSymbolicLinks() => throw _unsupported();

  @override
  String resolveSymbolicLinksSync() => throw _unsupported();

  @override
  Future<FileStat> stat() => throw _unsupported();

  @override
  FileStat statSync() => throw _unsupported();

  @override
  Uri get uri => fileSystem.path.toUri(path);

  @override
  Stream<FileSystemEvent> watch(
          {int events = FileSystemEvent.all, bool recursive = false}) =>
      throw _unsupported();
}
