const PseudoApplication pseudoApplication =
    const PseudoApplication('foo', 'bar', 'http://foo.bar/baz');

class PseudoApplication {
  final String id, secret, redirectUri;

  const PseudoApplication(this.id, this.secret, this.redirectUri);
}
