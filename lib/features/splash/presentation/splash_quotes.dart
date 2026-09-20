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
    SplashQuote(
      quote: 'A lesson without pain is meaningless.',
      author: 'Edward Elric',
      source: 'Fullmetal Alchemist: Brotherhood',
    ),
    SplashQuote(
      quote:
          'A person becomes strong when they have someone they want to protect.',
      author: 'Haku',
      source: 'Naruto',
    ),
    SplashQuote(
      quote:
          'Hard work is worthless for those that don’t believe in themselves.',
      author: 'Naruto Uzumaki',
      source: 'Naruto',
    ),
    SplashQuote(
      quote: 'I won’t run away anymore. I won’t go back on my word.',
      author: 'Naruto Uzumaki',
      source: 'Naruto',
    ),
    SplashQuote(
      quote: 'A dropout will beat a genius through hard work.',
      author: 'Rock Lee',
      source: 'Naruto',
    ),
    SplashQuote(
      quote:
          'The moment people come to know love, they run the risk of carrying hate.',
      author: 'Obito Uchiha',
      source: 'Naruto Shippuden',
    ),
    SplashQuote(
      quote:
          'People’s lives don’t end when they die. It ends when they lose faith.',
      author: 'Itachi Uchiha',
      source: 'Naruto Shippuden',
    ),
    SplashQuote(
      quote: 'The world is cruel, but it’s also very beautiful.',
      author: 'Mikasa Ackerman',
      source: 'Attack on Titan',
    ),
    SplashQuote(
      quote:
          'If you win, you live. If you lose, you die. If you don’t fight, you can’t win!',
      author: 'Eren Yeager',
      source: 'Attack on Titan',
    ),
    SplashQuote(
      quote: 'The only truth is that there is no truth.',
      author: 'Eren Yeager',
      source: 'Attack on Titan',
    ),
    SplashQuote(
      quote:
          'No one knows what the future holds. That is why its potential is infinite.',
      author: 'Erwin Smith',
      source: 'Attack on Titan',
    ),
    SplashQuote(
      quote: 'Give up on your dreams and die.',
      author: 'Levi Ackerman',
      source: 'Attack on Titan',
    ),
    SplashQuote(
      quote:
          'I don’t know which choice is right. But I do know that you have to believe in yourself.',
      author: 'Levi Ackerman',
      source: 'Attack on Titan',
    ),
    SplashQuote(
      quote: 'Power comes in response to a need, not a desire.',
      author: 'Goku',
      source: 'Dragon Ball Z',
    ),
    SplashQuote(
      quote:
          'I would rather be a fool who believes in people than a fool who doesn’t.',
      author: 'Goku',
      source: 'Dragon Ball',
    ),
    SplashQuote(
      quote: 'I’m going to be the Pirate King!',
      author: 'Monkey D. Luffy',
      source: 'One Piece',
    ),
    SplashQuote(
      quote: 'If you don’t take risks, you can’t create a future.',
      author: 'Monkey D. Luffy',
      source: 'One Piece',
    ),
    SplashQuote(
      quote:
          'Forgetting is like a wound. The wound may heal but it has already left a scar.',
      author: 'Monkey D. Luffy',
      source: 'One Piece',
    ),
    SplashQuote(
      quote: 'A man’s dream will never die!',
      author: 'Marshall D. Teach',
      source: 'One Piece',
    ),
    SplashQuote(
      quote: 'When you think people die? When they are forgotten.',
      author: 'Dr. Hiriluk',
      source: 'One Piece',
    ),
    SplashQuote(
      quote: 'A lesson in fighting: if you’re weaker, don’t fight fair.',
      author: 'Gin Ichimaru',
      source: 'Bleach',
    ),
    SplashQuote(
      quote: 'Fear is not evil. It tells you what your weakness is.',
      author: 'Gildarts Clive',
      source: 'Fairy Tail',
    ),
    SplashQuote(
      quote:
          'You should enjoy the little detours. Because that’s where you’ll find the things more important than what you want.',
      author: 'Ging Freecss',
      source: 'Hunter x Hunter',
    ),
    SplashQuote(
      quote:
          'An important part of being a good person is simply trying to be better.',
      author: 'All Might',
      source: 'My Hero Academia',
    ),
    SplashQuote(
      quote:
          'Sometimes you have to hurt in order to know, fall in order to grow, lose in order to gain.',
      author: 'Izuku Midoriya',
      source: 'My Hero Academia',
    ),
    SplashQuote(
      quote: 'When you hit the wall, all you can do is climb over it.',
      author: 'Izuku Midoriya',
      source: 'My Hero Academia',
    ),
    SplashQuote(
      quote: 'Plus Ultra!',
      author: 'All Might',
      source: 'My Hero Academia',
    ),
    SplashQuote(
      quote: 'I will become the Wizard King!',
      author: 'Asta',
      source: 'Black Clover',
    ),
    SplashQuote(
      quote: 'I’m not done yet!',
      author: 'Asta',
      source: 'Black Clover',
    ),
    SplashQuote(
      quote: 'If you’re going to do something, do it until the end.',
      author: 'Yami Sukehiro',
      source: 'Black Clover',
    ),
    SplashQuote(
      quote: 'Set your heart ablaze.',
      author: 'Kyojuro Rengoku',
      source: 'Demon Slayer',
    ),
    SplashQuote(
      quote:
          'Don’t ever give up. Even if it’s painful, even if it’s agonizing.',
      author: 'Tanjiro Kamado',
      source: 'Demon Slayer',
    ),
    SplashQuote(
      quote: 'Life is a series of decisions.',
      author: 'Kyojuro Rengoku',
      source: 'Demon Slayer',
    ),
    SplashQuote(
      quote: 'The strong should protect the weak.',
      author: 'Kyojuro Rengoku',
      source: 'Demon Slayer',
    ),
    SplashQuote(
      quote: 'Dead people are dead.',
      author: 'Satoru Gojo',
      source: 'Jujutsu Kaisen',
    ),
    SplashQuote(
      quote: 'When you die, you’ll be alone.',
      author: 'Satoru Gojo',
      source: 'Jujutsu Kaisen',
    ),
    SplashQuote(
      quote: 'Love is the most twisted curse of all.',
      author: 'Yuta Okkotsu',
      source: 'Jujutsu Kaisen',
    ),
    SplashQuote(
      quote: 'Throughout heaven and earth, I alone am the honored one.',
      author: 'Satoru Gojo',
      source: 'Jujutsu Kaisen',
    ),
    SplashQuote(
      quote: 'I’m the strongest.',
      author: 'Satoru Gojo',
      source: 'Jujutsu Kaisen',
    ),
    SplashQuote(
      quote: 'If you’re going to regret it, regret it after you do it.',
      author: 'Satoru Gojo',
      source: 'Jujutsu Kaisen',
    ),
    SplashQuote(
      quote: 'The future is yours.',
      author: 'Satoru Gojo',
      source: 'Jujutsu Kaisen',
    ),
    SplashQuote(
      quote: 'The weak have no rights or choices.',
      author: 'Sung Jin-Woo',
      source: 'Solo Leveling',
    ),
    SplashQuote(
      quote: 'I must become stronger.',
      author: 'Sung Jin-Woo',
      source: 'Solo Leveling',
    ),
    SplashQuote(
      quote: 'I’m the only one who can level up.',
      author: 'Sung Jin-Woo',
      source: 'Solo Leveling',
    ),
    SplashQuote(
      quote: 'Arise.',
      author: 'Sung Jin-Woo',
      source: 'Solo Leveling',
    ),
    SplashQuote(
      quote: 'It’s what Himmel the Hero would have done.',
      author: 'Heiter',
      source: 'Frieren: Beyond Journey’s End',
    ),
    SplashQuote(
      quote: 'The purpose of life is to be known and remembered.',
      author: 'Himmel',
      source: 'Frieren: Beyond Journey’s End',
    ),
    SplashQuote(
      quote: 'You should know that people are not necessarily good or evil.',
      author: 'Frieren',
      source: 'Frieren: Beyond Journey’s End',
    ),
    SplashQuote(
      quote:
          'Talent is something you make bloom, instinct is something you polish.',
      author: 'Toru Oikawa',
      source: 'Haikyuu!!',
    ),
    SplashQuote(
      quote: 'The future belongs to those who believe in their dreams.',
      author: 'Shoyo Hinata',
      source: 'Haikyuu!!',
    ),
    SplashQuote(
      quote: 'I’ll take a potato chip... and eat it!',
      author: 'Light Yagami',
      source: 'Death Note',
    ),
    SplashQuote(
      quote: 'The human who wrote that name in this note shall die.',
      author: 'Ryuk',
      source: 'Death Note',
    ),
    SplashQuote(
      quote: 'This world is rotten.',
      author: 'Light Yagami',
      source: 'Death Note',
    ),
    SplashQuote(
      quote: 'I am justice!',
      author: 'Light Yagami',
      source: 'Death Note',
    ),
    SplashQuote(
      quote: 'People aren’t born monsters. They become them.',
      author: 'Kenzo Tenma',
      source: 'Monster',
    ),
    SplashQuote(
      quote: 'There is no such thing as a perfect human being.',
      author: 'Johan Liebert',
      source: 'Monster',
    ),
    SplashQuote(
      quote: 'The more you know, the more you realize how little you know.',
      author: 'Sosuke Aizen',
      source: 'Bleach',
    ),
    SplashQuote(
      quote: 'If you give me wings, I will soar for you.',
      author: 'Orihime Inoue',
      source: 'Bleach',
    ),
    SplashQuote(
      quote: 'We stand in awe before that which cannot be seen.',
      author: 'Sosuke Aizen',
      source: 'Bleach',
    ),
    SplashQuote(
      quote: 'The difference between the novice and the master is that the master has failed more times.',
      author: 'Koro-sensei',
      source: 'Assassination Classroom',
    ),
    SplashQuote(
      quote: 'There is no shame in falling down. The shame is in not getting back up.',
      author: 'Shoyo Hinata',
      source: 'Haikyuu!!',
    ),
    SplashQuote(
      quote: 'Once you conquer your weakness, you can become stronger.',
      author: 'Tobio Kageyama',
      source: 'Haikyuu!!',
    ),
    SplashQuote(
      quote: 'The future is not promised to anyone.',
      author: 'Kiyoko Shimizu',
      source: 'Haikyuu!!',
    ),
    SplashQuote(
      quote: 'The moment you give up is the moment you lose.',
      author: 'Shoyo Hinata',
      source: 'Haikyuu!!',
    ),
    SplashQuote(
      quote: 'The view from the top is different.',
      author: 'Tobio Kageyama',
      source: 'Haikyuu!!',
    ),
    SplashQuote(
      quote: 'If you can still move, then you haven’t lost yet.',
      author: 'Shoyo Hinata',
      source: 'Haikyuu!!',
    ),
    SplashQuote(
      quote: 'A sword is merely a tool. The person holding it gives it meaning.',
      author: 'Kenshin Himura',
      source: 'Rurouni Kenshin',
    ),
    SplashQuote(
      quote: 'Those who cling to life die, and those who defy death live.',
      author: 'Kenshin Himura',
      source: 'Rurouni Kenshin',
    ),
    SplashQuote(
      quote: 'There is no such thing as an accident in this world.',
      author: 'Yuuko Ichihara',
      source: 'xxxHOLiC',
    ),
    SplashQuote(
      quote: 'The world is full of things that cannot be explained.',
      author: 'Shiki Ryougi',
      source: 'The Garden of Sinners',
    ),
    SplashQuote(
      quote: 'People die when they are killed.',
      author: 'Shirou Emiya',
      source: 'Fate/stay night',
    ),
    SplashQuote(
      quote: 'I am the bone of my sword.',
      author: 'Archer',
      source: 'Fate/stay night',
    ),
    SplashQuote(
      quote: 'People have dreams. People have hopes. That is what makes them human.',
      author: 'Emiya Shirou',
      source: 'Fate/stay night',
    ),
    SplashQuote(
      quote: 'You cannot save everyone. You must choose.',
      author: 'Kiritsugu Emiya',
      source: 'Fate/Zero',
    ),
    SplashQuote(
      quote: 'The world is not beautiful, therefore it is.',
      author: 'Kino',
      source: 'Kino’s Journey',
    ),
    SplashQuote(
      quote: 'A journey is best measured in friends rather than miles.',
      author: 'Timothy',
      source: 'Pokémon',
    ),
    SplashQuote(
      quote: 'A lesson without pain is meaningless.',
      author: 'Edward Elric',
      source: 'Fullmetal Alchemist: Brotherhood',
    ),
    SplashQuote(
      quote: 'Nothing’s perfect, the world’s not perfect, but it’s there for us.',
      author: 'Roy Mustang',
      source: 'Fullmetal Alchemist: Brotherhood',
    ),
    SplashQuote(
      quote: 'Stand up and walk. Keep moving forward.',
      author: 'Edward Elric',
      source: 'Fullmetal Alchemist: Brotherhood',
    ),
    SplashQuote(
      quote: 'Humankind cannot gain anything without first giving something in return.',
      author: 'Alphonse Elric',
      source: 'Fullmetal Alchemist: Brotherhood',
    ),
    SplashQuote(
      quote: 'The world is not as simple as you think.',
      author: 'Lelouch vi Britannia',
      source: 'Code Geass',
    ),
    SplashQuote(
      quote: 'What do you do when there is an evil you cannot defeat?',
      author: 'Lelouch vi Britannia',
      source: 'Code Geass',
    ),
    SplashQuote(
      quote: 'A life without regrets is impossible.',
      author: 'Kallen Stadtfeld',
      source: 'Code Geass',
    ),
    SplashQuote(
      quote: 'The only ones who should kill are those prepared to be killed.',
      author: 'Lelouch vi Britannia',
      source: 'Code Geass',
    ),
    SplashQuote(
      quote: 'Humans are weak creatures. But that is why they can become strong.',
      author: 'Reigen Arataka',
      source: 'Mob Psycho 100',
    ),
    SplashQuote(
      quote: 'Your life is your own. You decide what to do with it.',
      author: 'Reigen Arataka',
      source: 'Mob Psycho 100',
    ),
    SplashQuote(
      quote: 'You can’t control your emotions, but you can control your actions.',
      author: 'Reigen Arataka',
      source: 'Mob Psycho 100',
    ),
    SplashQuote(
      quote: 'It’s okay to run away. Running away is also a strategy.',
      author: 'Reigen Arataka',
      source: 'Mob Psycho 100',
    ),
    SplashQuote(
      quote: 'If you ever need help, ask for it.',
      author: 'Ritsu Kageyama',
      source: 'Mob Psycho 100',
    ),
    SplashQuote(
      quote: 'I am Atomic.',
      author: 'Cid Kagenou',
      source: 'The Eminence in Shadow',
    ),
    SplashQuote(
      quote: 'The weak don’t get to decide how they die.',
      author: 'Cid Kagenou',
      source: 'The Eminence in Shadow',
    ),
    SplashQuote(
      quote: 'The world is full of mysteries.',
      author: 'Frieren',
      source: 'Frieren: Beyond Journey’s End',
    ),
    SplashQuote(
      quote: 'Humans are interesting creatures.',
      author: 'Frieren',
      source: 'Frieren: Beyond Journey’s End',
    ),
    SplashQuote(
      quote: 'I want to get to know people better.',
      author: 'Frieren',
      source: 'Frieren: Beyond Journey’s End',
    ),
    SplashQuote(
      quote: 'Memories are proof that we lived.',
      author: 'Frieren',
      source: 'Frieren: Beyond Journey’s End',
    ),
    SplashQuote(
      quote: 'Being alone is not the same as being lonely.',
      author: 'Fern',
      source: 'Frieren: Beyond Journey’s End',
    ),
    SplashQuote(
      quote: 'If you don’t like your destiny, don’t accept it.',
      author: 'Natsu Dragneel',
      source: 'Fairy Tail',
    ),
    SplashQuote(
      quote: 'Fear is not evil. It tells you what your weakness is.',
      author: 'Gildarts Clive',
      source: 'Fairy Tail',
    ),
    SplashQuote(
      quote: 'You should never give up on something you can’t go a day without thinking about.',
      author: 'Natsu Dragneel',
      source: 'Fairy Tail',
    ),
  ];
}
