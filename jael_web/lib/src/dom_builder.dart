abstract class DomBuilder<T> {
  DomBuilderElement<T> open(String tagName);

  void emitText(String value);
}

abstract class DomBuilderElement<T> implements DomBuilder<T> {
  T close();
}
