import 'dart:math';

class SplashQuote {
  final String quote;
  final String author;
  final String? source;

  const SplashQuote({required this.quote, required this.author, this.source});

  String get formattedAuthor =>
      source != null && source!.isNotEmpty ? '$author ($source)' : author;
}

class SplashQuotes {
  static final _random = Random();

  static SplashQuote getRandomQuote([SplashQuote? current]) {
    if (quotes.isEmpty) {
      return const SplashQuote(
        quote: 'The journey of a thousand miles begins with one step.',
        author: 'Lao Tzu',
      );
    }
    if (quotes.length == 1) return quotes.first;

    SplashQuote selected;
    do {
      selected = quotes[_random.nextInt(quotes.length)];
    } while (selected == current);
    return selected;
  }

  static const List<SplashQuote> quotes = [
    SplashQuote(
      quote:
          'You have no enemies. No one has any enemies. There is no one that you should hurt.',
      author: 'Thors Snorresson',
      source: 'Vinland Saga',
    ),
    SplashQuote(
      quote: 'A true warrior doesn’t need a sword.',
      author: 'Thors Snorresson',
      source: 'Vinland Saga',
    ),
    SplashQuote(
      quote:
          'I want what lies beyond the horizon. Beyond the sea, there is a land free from war and slavery.',
      author: 'Thorfinn Karlsefni',
      source: 'Vinland Saga',
    ),
    SplashQuote(
      quote:
          'If you don’t have an enemy, it means you haven’t done anything to stand up for peace.',
      author: 'Thorfinn Karlsefni',
      source: 'Vinland Saga',
    ),
    SplashQuote(
      quote:
          'Those who forgive themselves, and are able to accept their true nature... they are the strong ones!',
      author: 'Itachi Uchiha',
      source: 'Naruto Shippuden',
    ),
    SplashQuote(
      quote: 'When a man learns to love, he must bear the risk of hatred.',
      author: 'Madara Uchiha',
      source: 'Naruto Shippuden',
    ),
    SplashQuote(
      quote:
          'If there is such a thing as peace, I will find it. I won’t give up!',
      author: 'Naruto Uzumaki',
      source: 'Naruto Shippuden',
    ),
    SplashQuote(
      quote:
          'Even the most ignorant, innocent child will eventually grow up as they learn what true pain is. It affects what they say, what they think… and they become real people.',
      author: 'Pain (Nagato)',
      source: 'Naruto Shippuden',
    ),
    SplashQuote(
      quote: 'If the king doesn’t move, then his subjects won’t follow.',
      author: 'Lelouch vi Britannia',
      source: 'Code Geass',
    ),
    SplashQuote(
      quote:
          'The only ones who should kill are those who are prepared to be killed.',
      author: 'Lelouch vi Britannia',
      source: 'Code Geass',
    ),
    SplashQuote(
      quote:
          'A life that lives without doing anything is the same as a slow death.',
      author: 'Lelouch vi Britannia',
      source: 'Code Geass',
    ),
    SplashQuote(
      quote: 'When do you think people die? When they are forgotten.',
      author: 'Dr. Hiriluk',
      source: 'One Piece',
    ),
    SplashQuote(
      quote: 'Fools who don’t respect the past are likely to repeat it.',
      author: 'Nico Robin',
      source: 'One Piece',
    ),
    SplashQuote(
      quote:
          'Maybe nothing in this world happens by accident. As everything happens for a reason, our destiny slowly takes form.',
      author: 'Silvers Rayleigh',
      source: 'One Piece',
    ),
    SplashQuote(
      quote:
          'Pirates are evil? The Marines are righteous? These terms have always changed throughout the course of history! Kids who have never seen peace and kids who have never seen war have different values!',
      author: 'Donquixote Doflamingo',
      source: 'One Piece',
    ),
    SplashQuote(
      quote: 'Do not live bowing down. You must die standing up.',
      author: 'Genryusai Shigekuni Yamamoto',
      source: 'Bleach',
    ),
    SplashQuote(
      quote: 'Admiration is the furthest state from understanding.',
      author: 'Sosuke Aizen',
      source: 'Bleach',
    ),
    SplashQuote(
      quote:
          'We are all like fireworks. We climb, shine and always go our separate ways and become further apart.',
      author: 'Toshiro Hitsugaya',
      source: 'Bleach',
    ),
    SplashQuote(
      quote:
          'Preoccupation with a single leaf will prevent you from seeing the tree. Preoccupation with a single tree will prevent you from seeing the forest.',
      author: 'Takuan Soho',
      source: 'Vagabond',
    ),
    SplashQuote(
      quote: 'The only thing humans are equal in is death.',
      author: 'Johan Liebert',
      source: 'Monster',
    ),
    SplashQuote(
      quote:
          'If you have time to think of a beautiful end, then live beautifully until the end.',
      author: 'Sakata Gintoki',
      source: 'Gintama',
    ),
    SplashQuote(
      quote:
          'The world isn’t perfect. But it’s there for us, doing the best it can... that’s what makes it so damn beautiful.',
      author: 'Roy Mustang',
      source: 'Fullmetal Alchemist',
    ),
    SplashQuote(
      quote:
          'The only thing we’re allowed to do is to believe that we won’t regret the choice we made.',
      author: 'Levi Ackerman',
      source: 'Attack on Titan',
    ),
  ];
}
