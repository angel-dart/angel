import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// Represents information about a file, regardless of whether it exists in the filesystem
/// or in memory.
abstract class FileInfo {
  /// Returns the content of the file.
  Stream<List<int>> get content;

  /// This file's extension.
  String get extension;

  /// The name of the file.
  String get filename;

  /// The time when this file was last modified.
  DateTime get lastModified;

  /// The file's MIME type.
  String get mimeType;

  /// Creates a [FileInfo] instance representing a physical file.
  factory FileInfo.fromFile(File file) => new _FileInfoImpl(
      () => file.openRead(),
      file.absolute.path,
      lookupMimeType(file.path),
      file.statSync().modified);

  /// Creates a [FileInfo] describing a file that might not even exists to begin with.
  factory FileInfo.hypothetical(String hypotheticalFileName) =>
      new _FileInfoImpl(null, hypotheticalFileName,
          lookupMimeType(hypotheticalFileName), null);

  /// Returns an identical instance, but with a different filename.
  FileInfo changeFilename(String newFilename);

  /// Returns an identical instance, but with a different extension.
  FileInfo changeExtension(String newExtension);

  /// Returns an identical instance, but with a different content.
  FileInfo changeContent(Stream<List<int>> newContent);

  /// Returns an identical instance, but with differnet content, set to the given String.
  FileInfo changeText(String newText, {Encoding encoding: UTF8});

  /// Returns an identical instance, but with a different MIME type.
  FileInfo changeMimeType(String newMimeType);
}

class _FileInfoImpl implements FileInfo {
  @override
  Stream<List<int>> get content => getContent();

  @override
  final String filename, mimeType;

  @override
  final DateTime lastModified;

  final Function getContent;

  _FileInfoImpl(Stream<List<int>> this.getContent(), this.filename,
      this.mimeType, this.lastModified);

  @override
  String get extension => p.extension(filename);

  @override
  FileInfo changeFilename(String newFilename) =>
      new _FileInfoImpl(getContent, newFilename, mimeType, lastModified);

  @override
  FileInfo changeExtension(String newExtension) =>
      changeFilename(p.withoutExtension(filename) + newExtension);

  @override
  FileInfo changeContent(Stream<List<int>> newContent) =>
      new _FileInfoImpl(() => newContent, filename, mimeType, lastModified);

  @override
  FileInfo changeText(String newText, {Encoding encoding: UTF8}) =>
      changeContent(new Stream<List<int>>.fromIterable(
          [(encoding ?? UTF8).encode(newText)]));

  @override
  FileInfo changeMimeType(String newMimeType) =>
      new _FileInfoImpl(getContent, filename, newMimeType, lastModified);
}
