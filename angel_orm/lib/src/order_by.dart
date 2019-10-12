class OrderBy {
  final String key;
  final bool descending;

  const OrderBy(this.key, {this.descending = false});

  String compile() => descending ? '$key DESC' : '$key ASC';
}
