const PseudoApplication pseudoApplication =
    const PseudoApplication('foo', 'bar', 'http://foo.bar/baz');

class PseudoApplication {
  final String id, secret, redirectUri;

  const PseudoApplication(this.id, this.secret, this.redirectUri);
}

const List<PseudoUser> pseudoUsers = const [
  const PseudoUser(username: 'foo', password: 'bar'),
  const PseudoUser(username: 'michael', password: 'jackson'),
  const PseudoUser(username: 'jon', password: 'skeet'),
];

class PseudoUser {
  final String username, password;

  const PseudoUser({this.username, this.password});
}