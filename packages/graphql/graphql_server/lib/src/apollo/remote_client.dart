import 'dart:async';
import 'package:stream_channel/stream_channel.dart';
import 'transport.dart';

class RemoteClient extends StreamChannelMixin<OperationMessage> {
  final StreamChannel<Map> channel;
  final StreamChannelController<OperationMessage> _ctrl =
      StreamChannelController();

  RemoteClient.withoutJson(this.channel) {
    _ctrl.local.stream
        .map((m) => m.toJson())
        .cast<Map>()
        .forEach(channel.sink.add);
    channel.stream.listen((m) {
      _ctrl.local.sink.add(OperationMessage.fromJson(m));
    });
  }

  RemoteClient(StreamChannel<String> channel)
      : this.withoutJson(jsonDocument.bind(channel).cast<Map>());
  @override
  StreamSink<OperationMessage> get sink => _ctrl.foreign.sink;

  @override
  Stream<OperationMessage> get stream => _ctrl.foreign.stream;

  void close() {
    channel.sink.close();
    _ctrl.local.sink.close();
  }
}
