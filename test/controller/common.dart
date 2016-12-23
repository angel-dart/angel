import 'package:angel_framework/angel_framework.dart';
import 'package:angel_websocket/server.dart';

class Game {
  final String playerOne, playerTwo;

  const Game({this.playerOne, this.playerTwo});
}

@Expose('/game')
class GameController extends WebSocketController {
  @ExposeWs('search')
  search(WebSocketContext socket) async {
    print('OMG ok');
    socket.send('searched', 'poop');
  }
}