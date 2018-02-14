import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/hooks.dart' as hooks;
import 'package:angel_websocket/server.dart';
import 'package:eventsource/eventsource.dart';
import 'package:eventsource/src/encoder.dart';
import 'package:eventsource/publisher.dart';
import 'package:json_god/json_god.dart' as god;

class AngelEventSourcePublisher {
  final EventSourcePublisher eventSourcePublisher;

  /// Used to notify other nodes of an event's firing. Good for scaled applications.
  final WebSocketSynchronizer synchronizer;

  /// Serializes a [WebSocketEvent] to JSON.
  ///
  /// Defaults to [god.serialize].
  final String Function(WebSocketEvent) serializer;
  int _count = 0;

  AngelEventSourcePublisher(this.eventSourcePublisher,
      {this.synchronizer, this.serializer});

  Future configureServer(Angel app) async {
    await app.configure(hooks.hookAllServices((service) {
      if (service is HookedService) {
        var path =
            app.services.keys.firstWhere((p) => app.services[p] == service);

        service.after([
          HookedServiceEvent.created,
          HookedServiceEvent.modified,
          HookedServiceEvent.updated,
          HookedServiceEvent.removed,
        ], (e) {
          var event = new WebSocketEvent(
            eventName: '${path.toString()}::${e.eventName}',
            data: e.result,
          );

          _filter(RequestContext req, ResponseContext res) {
            if (e.service.configuration.containsKey('sse:filter'))
              return e.service.configuration['sse:filter'](e, req, res);
            else if (e.params != null && e.params.containsKey('sse:filter'))
              return e.params['sse:filter'](e, req, res);
            else
              return true;
          }

          var canSend = _filter(e.request, e.response);

          if (canSend) {
            batchEvent(event, e.request.properties['channel'] ?? '');
          }
        });
      }
    }));

    if (synchronizer != null) {
      var sub = synchronizer.stream.listen((e) => batchEvent(e, ''));
      app.shutdownHooks.add((_) async {
        sub.cancel();
      });
    }
  }

  Future batchEvent(WebSocketEvent event, String channel) async {
    eventSourcePublisher.add(
      new Event(
        id: (_count++).toString(),
        data: (serializer ?? god.serialize)(event),
      ),
      channels: [channel],
    );
  }

  Future<bool> handleRequest(RequestContext req, ResponseContext res) async {
    if (!req.accepts('text/event-stream', strict: false))
      throw new AngelHttpException.badRequest();

    res
      ..headers.addAll({
        'cache-control': 'no-cache, no-store, must-revalidate',
        'content-type': 'text/event-stream',
        'connection': 'keep-alive',
      })
      ..willCloseItself = true
      ..end();

    var acceptsGzip =
        (req.headers['accept-encoding']?.contains('gzip') == true);

    if (acceptsGzip) res.io.headers.set('content-encoding', 'gzip');
    res.headers.forEach(res.io.headers.set);

    var sock = res.io ?? await res.io.detachSocket();
    sock.flush();

    var eventSink = new EventSourceEncoder(compressed: acceptsGzip)
        .startChunkedConversion(sock);

    eventSourcePublisher.newSubscription(
      onEvent: (e) {
        try {
          eventSink.add(e);
          sock.flush();
        } catch (_) {
          // Ignore disconnect
        }
      },
      onClose: eventSink.close,
      channel: req.properties['channel'] ?? '',
      lastEventId: req.headers.value('last-event-id'),
    );

    return false;
  }
}
