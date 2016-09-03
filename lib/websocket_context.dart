part of angel_websocket.server;

class WebSocketContext {
  WebSocket underlyingSocket;
  RequestContext requestContext;
  ResponseContext responseContext;

  WebSocketContext(WebSocket this.underlyingSocket,
      RequestContext this.requestContext, ResponseContext this.responseContext);

  send(String eventName, data) {
    underlyingSocket.add(
        god.serialize(new WebSocketEvent(eventName: eventName, data: data)));
  }

  sendError(AngelHttpException error) => send("error", error);
}
