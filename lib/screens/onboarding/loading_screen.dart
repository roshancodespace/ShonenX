import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          // gradient: LinearGradient(
          //   begin: Alignment.topCenter,
          //   end: Alignment.bottomCenter,
          //   colors: [
          //     Colors.black,
          //     Colors.blue.shade900.withOpacity(0.3),
          //     Colors.black,
          //   ],
          // ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Image.asset(
                'lib/assets/images/onboarding/logo.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 40),
              
              // Custom Animated Loading Indicator
              SizedBox(
                width: 160,
                child: Column(
                  children: [
                    // Primary loader
                    const LinearProgressIndicator(
                      // backgroundColor: Colors.white24,
                      // valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 16),
                    
                    // Loading text with shimmer effect
                    ShimmerText(
                      text: "Setting up your anime world...",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 80),
              
              // Random anime quote
              const RandomAnimeQuote(),
            ],
          ),
        ),
      ),
    );
  }
}

// Shimmer effect for text
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const ShimmerText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Text(
            widget.text,
            style: widget.style,
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Random anime quotes widget
class RandomAnimeQuote extends StatefulWidget {
  const RandomAnimeQuote({super.key});

  @override
  State<RandomAnimeQuote> createState() => _RandomAnimeQuoteState();
}

class _RandomAnimeQuoteState extends State<RandomAnimeQuote> {
 final List<Map<String, String>> quotes = [
    // One Piece Quotes
    {
      'quote': "I don't want to conquer anything. I just think the one with the most freedom is the Pirate King.",
      'character': 'Monkey D. Luffy',
      'anime': 'One Piece'
    },
    {
      'quote': "When do you think people die? When they are forgotten!",
      'character': 'Dr. Hiluluk',
      'anime': 'One Piece'
    },
    {
      'quote': "I have no regrets. My journey brought me here.",
      'character': 'Roronoa Zoro',
      'anime': 'One Piece'
    },

    // Jujutsu Kaisen Quotes
    {
      'quote': "You should be proud of the path you've chosen.",
      'character': 'Gojo Satoru',
      'anime': 'Jujutsu Kaisen'
    },
    {
      'quote': "Throughout heaven and earth, I alone am the honored one.",
      'character': 'Ryomen Sukuna',
      'anime': 'Jujutsu Kaisen'
    },
    {
      'quote': "My brother is my brother, and I am me.",
      'character': 'Megumi Fushiguro',
      'anime': 'Jujutsu Kaisen'
    },

    // Attack on Titan Quotes
    {
      'quote': "If you win, you live. If you lose, you die. If you don't fight, you can't win!",
      'character': 'Eren Yeager',
      'anime': 'Attack on Titan'
    },
    {
      'quote': "The world is cruel, but it is also very beautiful.",
      'character': 'Mikasa Ackerman',
      'anime': 'Attack on Titan'
    },
    {
      'quote': "Everyone had to be drunk on somethin' to keep pushing on.",
      'character': 'Kenny Ackerman',
      'anime': 'Attack on Titan'
    },

    // Naruto Quotes
    {
      'quote': "In the ninja world, those who break the rules are scum, but those who abandon their friends are worse than scum.",
      'character': 'Kakashi Hatake',
      'anime': 'Naruto'
    },
    {
      'quote': "When a man learns to love, he must bear the risk of hatred.",
      'character': 'Madara Uchiha',
      'anime': 'Naruto'
    },
    {
      'quote': "The moment people come to know love, they run the risk of carrying hate.",
      'character': 'Obito Uchiha',
      'anime': 'Naruto'
    },

    // My Hero Academia Quotes
    {
      'quote': "If you feel yourself hitting up against your limit, remember for what cause you clench your fists.",
      'character': 'All Might',
      'anime': 'My Hero Academia'
    },
    {
      'quote': "Sometimes I do feel like I'm a failure. Like there's no hope for me. But even so, I'm not gonna give up.",
      'character': 'Izuku Midoriya',
      'anime': 'My Hero Academia'
    },
    {
      'quote': "If all the villains out there hurt people, then I'll accept the challenge to protect everyone!",
      'character': 'Ochaco Uraraka',
      'anime': 'My Hero Academia'
    },

    // Demon Slayer Quotes (Added for more variety)
    {
      'quote': "No matter how many people you may lose, you have no choice but to go on living.",
      'character': 'Tanjiro Kamado',
      'anime': 'Demon Slayer'
    },
    {
      'quote': "Don't ever give up. Even if it's painful, even if it's agonizing, don't try to take the easy way out.",
      'character': 'Giyu Tomioka',
      'anime': 'Demon Slayer'
    }
  ];

  late Map<String, String> currentQuote;

  @override
  void initState() {
    super.initState();
    currentQuote = quotes[DateTime.now().microsecond % quotes.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(
            '"${currentQuote['quote']}"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '- ${currentQuote['character']} (${currentQuote['anime']})',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}