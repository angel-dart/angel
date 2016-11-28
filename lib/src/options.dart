class AngelAuthOptions {
  bool canRespondWithJson;
  String successRedirect;
  String failureRedirect;

  AngelAuthOptions(
      {this.canRespondWithJson: true,
      this.successRedirect,
      String this.failureRedirect});
}
