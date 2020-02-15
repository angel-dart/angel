const PseudoApplication pseudoApplication =
    PseudoApplication('foo', 'bar', 'http://foo.bar/baz');

class PseudoApplication {
  final String id, secret, redirectUri;

  const PseudoApplication(this.id, this.secret, this.redirectUri);
}

const List<PseudoUser> pseudoUsers = [
  PseudoUser(username: 'foo', password: 'bar'),
  PseudoUser(username: 'michael', password: 'jackson'),
  PseudoUser(username: 'jon', password: 'skeet'),
];

class PseudoUser {
  final String username, password;

  const PseudoUser({this.username, this.password});
}
