class Foo {
  final String bar;

  Foo({this.bar});

  Map<String, dynamic> toJson() {
    return {'bar': bar};
  }
}
