import 'package:angel_framework/angel_framework.dart';
import 'package:http_parser/http_parser.dart';
import 'options.dart';

/// Displays a default callback page to confirm authentication via popups.
AngelAuthCallback confirmPopupAuthentication({String eventName: 'token'}) {
  return (req, ResponseContext res, String jwt) async {
    res
      ..contentType = new MediaType('text', 'html')
      ..write('''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Authentication Success</title>
          <script>
            var ev = new CustomEvent('$eventName', { detail: '$jwt' });
            window.opener.dispatchEvent(ev);
            window.close();
          </script>
        </head>
        <body>
          <h1>Authentication Success</h1>
          <p>
            Now logging you in... If you continue to see this page, you may need to enable JavaScript.
          </p>
        </body>
      </html>
      ''');
    return false;
  };
}
