import 'package:charcode/ascii.dart';
import 'package:collection/collection.dart';
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

  /// The scopes to be passed to the external server.
  final Set<String> scopes;

  ExternalAuthOptions._(
      this.clientId, this.clientSecret, this.redirectUri, this.scopes) {
    if (clientId == null) {
      throw ArgumentError.notNull('clientId');
    } else if (clientSecret == null) {
      throw ArgumentError.notNull('clientSecret');
    }
  }

  factory ExternalAuthOptions(
      {@required String clientId,
      @required String clientSecret,
      @required redirectUri,
      Iterable<String> scopes = const []}) {
    if (redirectUri is String) {
      return ExternalAuthOptions._(
          clientId, clientSecret, Uri.parse(redirectUri), scopes.toSet());
    } else if (redirectUri is Uri) {
      return ExternalAuthOptions._(
          clientId, clientSecret, redirectUri, scopes.toSet());
    } else {
      throw ArgumentError.value(
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
    return ExternalAuthOptions(
      clientId: map['client_id'] as String,
      clientSecret: map['client_secret'] as String,
      redirectUri: map['redirect_uri'],
      scopes: map['scopes'] is Iterable
          ? ((map['scopes'] as Iterable).map((x) => x.toString()))
          : <String>[],
    );
  }

  @override
  int get hashCode => hash4(clientId, clientSecret, redirectUri, scopes);

  @override
  bool operator ==(other) =>
      other is ExternalAuthOptions &&
      other.clientId == clientId &&
      other.clientSecret == other.clientSecret &&
      other.redirectUri == other.redirectUri &&
      const SetEquality<String>().equals(other.scopes, scopes);

  /// Creates a copy of this object, with the specified changes.
  ExternalAuthOptions copyWith(
      {String clientId,
      String clientSecret,
      redirectUri,
      Iterable<String> scopes}) {
    return ExternalAuthOptions(
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      redirectUri: redirectUri ?? this.redirectUri,
      scopes: (scopes ??= []).followedBy(this.scopes),
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
  Map<String, dynamic> toJson({bool obscureSecret = true}) {
    return {
      'client_id': clientId,
      'client_secret': obscureSecret ? '<redacted>' : clientSecret,
      'redirect_uri': redirectUri.toString(),
      'scopes': scopes.toList(),
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
          List<int>.filled(asteriskCount ?? clientSecret.length, $asterisk);
      secret = String.fromCharCodes(codeUnits);
    }

    var b = StringBuffer('ExternalAuthOptions(');
    b.write('clientId=$clientId');
    b.write(', clientSecret=$secret');
    b.write(', redirectUri=$redirectUri');
    b.write(', scopes=${scopes.toList()}');
    b.write(')');
    return b.toString();
  }
}
