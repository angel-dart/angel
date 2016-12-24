import 'package:angel_framework/angel_framework.dart';
import 'package:angel_websocket/server.dart';

class Game {
  final String playerOne, playerTwo;

  const Game({this.playerOne, this.playerTwo});

  factory Game.fromJson(Map data) =>
      new Game(playerOne: data['playerOne'], playerTwo: data['playerTwo']);

  @override
  bool operator ==(other) =>
      other is Game &&
      other.playerOne == playerOne &&
      other.playerTwo == playerTwo;
}

const Game JOHN_VS_BOB = const Game(playerOne: 'John', playerTwo: 'Bob');

@Expose('/game')
class GameController extends WebSocketController {
  @ExposeWs('search')
  search(WebSocketContext socket) async {
    print('User is searching for a game...');
    socket.send('searched', JOHN_VS_BOB);
  }
}
