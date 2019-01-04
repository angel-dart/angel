import 'package:angel_auth/angel_auth.dart';
import 'package:test/test.dart';

void main() {
  var options = new ExternalAuthOptions(
    clientId: 'foo',
    clientSecret: 'bar',
    redirectUri: 'http://example.com',
  );

  test('parses uri', () {
    expect(options.redirectUri, Uri(scheme: 'http', host: 'example.com'));
  });

  group('copyWith', () {
    test('empty produces exact copy', () {
      expect(options.copyWith(), options);
    });

    test('all fields', () {
      expect(
        options.copyWith(
          clientId: 'hey',
          clientSecret: 'hello',
          redirectUri: 'https://yes.no',
        ),
        new ExternalAuthOptions(
          clientId: 'hey',
          clientSecret: 'hello',
          redirectUri: 'https://yes.no',
        ),
      );
    });

    test('not equal to original if different', () {
      expect(options.copyWith(clientId: 'hey'), isNot(options));
    });
  });

  group('new()', () {
    test('accepts uri', () {
      expect(
        new ExternalAuthOptions(
          clientId: 'foo',
          clientSecret: 'bar',
          redirectUri: Uri.parse('http://example.com'),
        ),
        options,
      );
    });

    test('accepts string', () {
      expect(
        new ExternalAuthOptions(
          clientId: 'foo',
          clientSecret: 'bar',
          redirectUri: 'http://example.com',
        ),
        options,
      );
    });

    test('rejects invalid redirectUri', () {
      expect(
        () => new ExternalAuthOptions(
            clientId: 'foo', clientSecret: 'bar', redirectUri: 24.5),
        throwsArgumentError,
      );
    });

    test('ensures id not null', () {
      expect(
        () => new ExternalAuthOptions(
            clientId: null,
            clientSecret: 'bar',
            redirectUri: 'http://example.com'),
        throwsArgumentError,
      );
    });

    test('ensures secret not null', () {
      expect(
        () => new ExternalAuthOptions(
            clientId: 'foo',
            clientSecret: null,
            redirectUri: 'http://example.com'),
        throwsArgumentError,
      );
    });
  });

  group('fromMap()', () {
    test('rejects invalid map', () {
      expect(
        () => new ExternalAuthOptions.fromMap({'yes': 'no'}),
        throwsArgumentError,
      );
    });

    test('accepts correct map', () {
      expect(
        new ExternalAuthOptions.fromMap({
          'client_id': 'foo',
          'client_secret': 'bar',
          'redirect_uri': 'http://example.com',
        }),
        options,
      );
    });
  });

  group('toString()', () {
    test('produces correct string', () {
      expect(
        options.toString(obscureSecret: false),
        'ExternalAuthOptions(clientId=foo, clientSecret=bar, redirectUri=http://example.com)',
      );
    });

    test('obscures secret', () {
      expect(
        options.toString(),
        'ExternalAuthOptions(clientId=foo, clientSecret=***, redirectUri=http://example.com)',
      );
    });

    test('asteriskCount', () {
      expect(
        options.toString(asteriskCount: 7),
        'ExternalAuthOptions(clientId=foo, clientSecret=*******, redirectUri=http://example.com)',
      );
    });
  });

  group('toJson()', () {
    test('obscures secret', () {
      expect(
        options.toJson(),
        {
          'client_id': 'foo',
          'client_secret': '<redacted>',
          'redirect_uri': 'http://example.com',
        },
      );
    });

    test('produces correct map', () {
      expect(
        options.toJson(obscureSecret: false),
        {
          'client_id': 'foo',
          'client_secret': 'bar',
          'redirect_uri': 'http://example.com',
        },
      );
    });
  });
}
