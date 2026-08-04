/// A-Z hızlı gezinme — harfe göre popüler sanatçılar (web ile aynı UX).
abstract final class MusicAzArtists {
  static const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ#';

  static List<String> forLetter(String letter) {
    final key = letter.toUpperCase();
    return _byLetter[key] ?? const [];
  }

  static const _byLetter = <String, List<String>>{
    'A': ['Adele', 'Ariana Grande', 'Arctic Monkeys', 'AC/DC', 'Adele'],
    'B': ['Billie Eilish', 'Beyoncé', 'Bruno Mars', 'BTS', 'Barış Manço'],
    'C': ['Coldplay', 'Cem Karaca', 'Can Bonomo', 'Celine Dion', 'Calvin Harris'],
    'D': ['Drake', 'Duman', 'Dua Lipa', 'David Guetta', 'Demet Akalın'],
    'E': ['Ed Sheeran', 'Eminem', 'Emre Aydın', 'Elton John', 'Ebru Gündeş'],
    'F': ['Foo Fighters', 'Ferdi Tayfur', 'Foster The People', 'Florence + The Machine'],
    'G': ['Gülşen', 'Gazapizm', 'Green Day', 'George Michael', 'Gökhan Türkmen'],
    'H': ['Hadise', 'Haluk Levent', 'Halsey', 'Harry Styles', 'Hande Yener'],
    'I': ['Imagine Dragons', 'Ibrahim Tatlıses', 'Ilhan İrem', 'Indila'],
    'J': ['Justin Bieber', 'Jennifer Lopez', 'John Legend', 'Juanes'],
    'K': ['Kanye West', 'Kolpa', 'Kıraç', 'Katy Perry', 'Kenan Doğulu'],
    'L': ['Lady Gaga', 'Lana Del Rey', 'Linkin Park', 'Levent Yüksel'],
    'M': ['Müslüm Gürses', 'Metallica', 'Mor ve Ötesi', 'Madonna', 'Mabel Matiz'],
    'N': ['Nirvana', 'Nazan Öncel', 'Nazan Öncel', 'Nicki Minaj', 'Nazan Öncel'],
    'O': ['Oasis', 'Orhan Gencebay', 'OneRepublic', 'Ozbi', 'Özgün'],
    'P': ['Pink Floyd', 'Pentagram', 'P!nk', 'Post Malone', 'Pinhani'],
    'Q': ['Queen', 'Quavo', 'Quality Control'],
    'R': ['Rihanna', 'Red Hot Chili Peppers', 'Rafet El Roman', 'Ragga Oktay'],
    'S': ['Sezen Aksu', 'Sertab Erener', 'Sia', 'Shakira', 'Sting'],
    'T': ['Tarkan', 'Teoman', 'The Weeknd', 'Taylor Swift', 'Tarkan'],
    'U': ['U2', 'Ufuk Beydemir', 'Usher'],
    'V': ['Volbeat', 'Vega', 'Van Halen'],
    'W': ['Whitney Houston', 'Will Smith', 'Wiz Khalifa'],
    'X': ['XXXTentacion', 'X Ambassadors'],
    'Y': ['Yalın', 'Yıldız Tilbe', 'Yusuf Güney', 'Yalın'],
    'Z': ['Zeki Müren', 'Zara', 'Zaz', 'Zakkum'],
    '#': ['50 Cent', '21 Savage', '6ix9ine'],
  };
}
