import 'package:charcode/ascii.dart';
import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

/// A common class containing parsing and validation logic for third-party authentication configuration.
class ExternalAuthOptions {
  /// The user's identifier, otherwise known as an "application id".
  final String clientId;

  /// The user's secret, other known as an "application secret".
  final String clientSecret;

  /// The user's redirect URI.
  final Uri redirectUri;

  ExternalAuthOptions._(this.clientId, this.clientSecret, this.redirectUri) {
    if (clientId == null) {
      throw new ArgumentError.notNull('clientId');
    } else if (clientSecret == null) {
      throw new ArgumentError.notNull('clientSecret');
    }
  }

  factory ExternalAuthOptions(
      {@required String clientId,
      @required String clientSecret,
      @required redirectUri}) {
    if (redirectUri is String) {
      return new ExternalAuthOptions._(
          clientId, clientSecret, Uri.parse(redirectUri));
    } else if (redirectUri is Uri) {
      return new ExternalAuthOptions._(clientId, clientSecret, redirectUri);
    } else {
      throw new ArgumentError.value(
          redirectUri, 'redirectUri', 'must be a String or Uri');
    }
  }

  /// Returns a JSON-friendly representation of this object.
  ///
  /// Parses the following fields:
  /// * `client_id`
  /// * `client_secret`
  /// * `redirect_uri`
  factory ExternalAuthOptions.fromMap(Map map) {
    return new ExternalAuthOptions(
      clientId: map['client_id'] as String,
      clientSecret: map['client_secret'] as String,
      redirectUri: map['redirect_uri'],
    );
  }

  @override
  int get hashCode => hash3(clientId, clientSecret, redirectUri);

  @override
  bool operator ==(other) =>
      other is ExternalAuthOptions &&
      other.clientId == clientId &&
      other.clientSecret == other.clientSecret &&
      other.redirectUri == other.redirectUri;

  /// Creates a copy of this object, with the specified changes.
  ExternalAuthOptions copyWith(
      {String clientId, String clientSecret, redirectUri}) {
    return new ExternalAuthOptions(
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      redirectUri: redirectUri ?? this.redirectUri,
    );
  }

  /// Returns a JSON-friendly representation of this object.
  ///
  /// Contains the following fields:
  /// * `client_id`
  /// * `client_secret`
  /// * `redirect_uri`
  ///
  /// If [obscureSecret] is `true` (default), then the [clientSecret] will
  /// be replaced by the string `<redacted>`.
  Map<String, String> toJson({bool obscureSecret = true}) {
    return {
      'client_id': clientId,
      'client_secret': obscureSecret ? '<redacted>' : clientSecret,
      'redirect_uri': redirectUri.toString(),
    };
  }

  /// Returns a [String] representation of this object.
  ///
  /// If [obscureText] is `true` (default), then the [clientSecret] will be
  /// replaced by asterisks in the output.
  ///
  /// If no [asteriskCount] is given, then the number of asterisks will equal the length of
  /// the actual [clientSecret].
  @override
  String toString({bool obscureSecret = true, int asteriskCount}) {
    String secret;

    if (!obscureSecret) {
      secret = clientSecret;
    } else {
      var codeUnits =
          new List<int>.filled(asteriskCount ?? clientSecret.length, $asterisk);
      secret = new String.fromCharCodes(codeUnits);
    }

    var b = new StringBuffer('ExternalAuthOptions(');
    b.write('clientId=$clientId');
    b.write(', clientSecret=$secret');
    b.write(', redirectUri=$redirectUri');
    b.write(')');
    return b.toString();
  }
}
