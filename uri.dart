main() {
  final uri = Uri.parse('/foo');
  print(uri);
  print(uri.resolve('/bar'));
}