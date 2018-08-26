import 'package:angel_container/angel_container.dart';
import 'package:test/test.dart';

void main() {
  Container container;

  setUp(() {
    container = new Container(const EmptyReflector())
      ..registerSingleton<Song>(new Song(title: 'I Wish'))
      ..registerFactory<Artist>((container) {
        return new Artist(
          name: 'Stevie Wonder',
          song: container.make<Song>(),
        );
      });
  });

  test('has on singleton', () {
    expect(container.has<Song>(), true);
  });

  test('has on factory', () {
    expect(container.has<Artist>(), true);
  });

  test('false if neither', () {
    expect(container.has<bool>(), false);
  });
}

class Artist {
  final String name;
  final Song song;

  Artist({this.name, this.song});
}

class Song {
  final String title;

  Song({this.title});
}
