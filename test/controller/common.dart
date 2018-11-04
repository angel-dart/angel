import 'package:angel_framework/angel_framework.dart';
import 'package:angel_websocket/server.dart';

class Game {
  final String playerOne, playerTwo;

  const Game({this.playerOne, this.playerTwo});

  factory Game.fromJson(Map data) => new Game(
      playerOne: data['playerOne'].toString(),
      playerTwo: data['playerTwo'].toString());

  Map<String, dynamic> toJson() {
    return {'playerOne': playerOne, 'playerTwo': playerTwo};
  }

  @override
  bool operator ==(other) =>
      other is Game &&
      other.playerOne == playerOne &&
      other.playerTwo == playerTwo;
}

const Game johnVsBob = const Game(playerOne: 'John', playerTwo: 'Bob');

@Expose('/game')
class GameController extends WebSocketController {
  GameController(AngelWebSocket ws) : super(ws);

  @ExposeWs('search')
  search(WebSocketContext socket) async {
    print('User is searching for a game...');
    socket.send('searched', johnVsBob);
  }
}
