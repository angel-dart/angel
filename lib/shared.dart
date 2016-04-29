library angel_websocket;
import 'dart:math';

String _randomString(int length) {
  var rand = new Random();
  var codeUnits = new List.generate(
      length,
      (index){
    return rand.nextInt(33)+89;
  }
  );

  return new String.fromCharCodes(codeUnits);
}

/// A WebSocket message sent from server to client, or vice-versa.
class AngelMessage {
  String id;
  String service;
  String method;
  Map body;

  AngelMessage(String this.service, String this.method,
      {Map this.body: const {}}) {
    id = _randomString(32);
  }

  /// Parses a Map into an AngelMessage.
  AngelMessage.fromMap(Map msg) {
    bool invalid = !(msg['service'] is String) ||
        (msg['service'] is String && msg['service'].isEmpty);
    invalid = invalid || !(msg['method'] is String) ||
        (msg['method'] is String && msg['method'].isEmpty);

    if (invalid) {
      throw new Exception("Invalid message supplied.");
    } else {
      this.id = _randomString(32);
      this.service = msg['service'];
      this.method = msg['method'];
      this.body = msg['body'] ?? {};
    }
  }

  Map toMap() {
    return {
      'id': id,
      'service': service,
      'method': method,
      'body': body
    };
  }
}