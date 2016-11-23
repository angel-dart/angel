import 'dart:io';
import 'package:angel_framework/angel_framework.dart';

@deprecated
RequestMiddleware serveStatic(
    {Directory sourceDirectory,
    List<String> indexFileNames: const ['index.html'],
    String virtualRoot: '/'}) {
  throw new Exception(
      'The `serveStatic` API is now deprecated. Please update your application to use the new `VirtualDirectory` API.');
}
