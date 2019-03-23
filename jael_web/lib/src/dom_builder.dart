abstract class DomBuilder<T> {
  DomBuilderElement<T> append(
      String tagName, void Function(DomBuilderElement<T>) f);

  void text(String value);
}

abstract class DomBuilderElement<T> extends DomBuilder<T> {
  void attr(String name, [String value]);

  void attrs(Map<String, String> map);

  T close();
}
