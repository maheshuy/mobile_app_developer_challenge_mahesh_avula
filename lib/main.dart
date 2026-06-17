import 'dart:convert';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const PebloApp());
}

class PebloApp extends StatelessWidget {
  const PebloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StoryQuizProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Peblo Story Buddy',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'Arial',
        ),
        home: const StoryBuddyScreen(),
      ),
    );
  }
}

enum AudioState { idle, preparing, speaking, completed, failed }

class QuizData {
  final String question;
  final List<String> options;
  final String answer;

  QuizData({
    required this.question,
    required this.options,
    required this.answer,
  });

  factory QuizData.fromJson(Map<String, dynamic> json) {
    return QuizData(
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      answer: json['answer'] as String,
    );
  }
}

class StoryQuizProvider extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();

  final String storyText =
      "Once upon a time, a clever little robot named Pip lost his shiny blue gear in the Whispering Woods...";

  final String quizJson = '''
{
  "question": "What colour was Pip the Robot's lost gear?",
  "options": ["Red", "Green", "Blue", "Yellow"],
  "answer": "Blue"
}
''';

  late final QuizData quiz;

  AudioState audioState = AudioState.idle;
  bool showQuiz = false;
  bool success = false;
  bool wrongAttempt = false;
  int shakeCount = 0;
  String? selectedOption;
  String friendlyMessage = "Tap the button and I will read the story!";

  StoryQuizProvider() {
    quiz = QuizData.fromJson(jsonDecode(quizJson));
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() {
      audioState = AudioState.speaking;
      friendlyMessage = "Story time is playing...";
      notifyListeners();
    });

    _tts.setCompletionHandler(() {
      audioState = AudioState.completed;
      showQuiz = true;
      friendlyMessage = "Quiz time! Listen carefully and choose the right answer.";
      notifyListeners();
    });

    _tts.setErrorHandler((message) {
      audioState = AudioState.failed;
      friendlyMessage = "Oops! I could not read the story now. Please try again.";
      notifyListeners();
    });
  }

  Future<void> readStory() async {
    try {
      await _tts.stop();

      audioState = AudioState.preparing;
      friendlyMessage = "Getting the story ready...";
      showQuiz = false;
      success = false;
      wrongAttempt = false;
      selectedOption = null;
      notifyListeners();

      await _tts.setLanguage("en-IN");
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.08);
      await _tts.setVolume(1.0);

      await Future.delayed(const Duration(milliseconds: 450));
      await _tts.speak(storyText);
    } catch (e) {
      audioState = AudioState.failed;
      friendlyMessage = "Oops! Something went wrong. Tap again to retry.";
      notifyListeners();
    }
  }

  void checkAnswer(String option) {
    selectedOption = option;

    if (option == quiz.answer) {
      success = true;
      wrongAttempt = false;
      friendlyMessage = "Yay! Pip's blue gear is found!";
      HapticFeedback.mediumImpact();
    } else {
      success = false;
      wrongAttempt = true;
      shakeCount++;
      friendlyMessage = "Oops! That's not right. Try again!";
      HapticFeedback.heavyImpact();

      Future.delayed(const Duration(milliseconds: 650), () {
        wrongAttempt = false;
        notifyListeners();
      });
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}

class StoryBuddyScreen extends StatefulWidget {
  const StoryBuddyScreen({super.key});

  @override
  State<StoryBuddyScreen> createState() => _StoryBuddyScreenState();
}

class _StoryBuddyScreenState extends State<StoryBuddyScreen> {
  late ConfettiController _confettiController;
  bool _playedSuccess = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoryQuizProvider>();

    if (provider.success && !_playedSuccess) {
      _playedSuccess = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
      });
    }

    if (!provider.success) {
      _playedSuccess = false;
    }

    return Scaffold(
      body: Stack(
        children: [
          const JoyfulBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      const TitleSection(),
                      const SizedBox(height: 18),
                      SpeechBubble(text: provider.friendlyMessage),
                      const SizedBox(height: 18),
                      BuddyCharacter(isHappy: provider.success),
                      const SizedBox(height: 24),
                      StoryCard(text: provider.storyText),
                      const SizedBox(height: 18),
                      ReadStoryButton(provider: provider),
                      const SizedBox(height: 22),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        child: provider.showQuiz
                            ? QuizCard(
                                key: ValueKey(
                                  'quiz_${provider.shakeCount}_${provider.success}_${provider.selectedOption}',
                                ),
                                provider: provider,
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 18),
                      const BottomHint(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              shouldLoop: false,
              emissionFrequency: 0.08,
              numberOfParticles: 24,
              maxBlastForce: 16,
              minBlastForce: 6,
              gravity: 0.22,
            ),
          ),
        ],
      ),
    );
  }
}

class JoyfulBackground extends StatelessWidget {
  const JoyfulBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFF3BE),
                Color(0xFFFFE2E8),
                Color(0xFFE9D5FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const Positioned(top: 34, left: 36, child: Sparkle(size: 20)),
        const Positioned(top: 74, left: 76, child: StarBurst(color: Color(0xFFFFC107), size: 18)),
        const Positioned(top: 52, right: 82, child: StarBurst(color: Color(0xFFFF6FAE), size: 22)),
        const Positioned(top: 96, right: 48, child: StarBurst(color: Color(0xFF4FC3F7), size: 18)),
        const Positioned(top: 132, right: 98, child: Sparkle(size: 18)),
        const Positioned(top: 98, left: 18, child: CloudWidget(width: 110, height: 52)),
        const Positioned(top: 112, right: 12, child: CloudWidget(width: 120, height: 56)),
        const Positioned(top: 370, left: 18, child: CloudWidget(width: 105, height: 48)),
        const Positioned(top: 520, right: 36, child: CloudWidget(width: 90, height: 42)),
        const Positioned(bottom: 150, left: 16, child: Sparkle(size: 16)),
        const Positioned(bottom: 100, right: 50, child: Sparkle(size: 14)),
      ],
    );
  }
}

class TitleSection extends StatelessWidget {
  const TitleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
            children: [
              TextSpan(
                text: "Peblo ",
                style: TextStyle(color: Color(0xFF7E57C2)),
              ),
              TextSpan(
                text: "Story Buddy",
                style: TextStyle(color: Color(0xFFFF4F87)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Your AI buddy who reads and plays!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4A2F8A),
          ),
        ),
      ],
    );
  }
}
class SpeechBubble extends StatelessWidget {
  final String text;

  const SpeechBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: min(MediaQuery.of(context).size.width * 0.88, 460),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: const Color(0xFFB57EDC),
                width: 3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4B2E83),
                height: 1.35,
              ),
            ),
          ),
          Positioned(
            bottom: -18,
            right: 54,
            child: CustomPaint(
              size: const Size(34, 22),
              painter: BubbleTailPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = const Color(0xFFB57EDC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(2, 0)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.2, size.width - 2, 2)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.72, size.width * 0.44, size.height - 1)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.45, 2, 0);

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BuddyCharacter extends StatelessWidget {
  final bool isHappy;

  const BuddyCharacter({super.key, required this.isHappy});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 350),
      scale: isHappy ? 1.05 : 1,
      child: SizedBox(
        width: 240,
        height: 250,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 34,
              top: 92,
              child: Transform.rotate(
                angle: -0.28,
                child: const DragonWing(side: WingSide.left),
              ),
            ),
            Positioned(
              right: 34,
              top: 92,
              child: Transform.rotate(
                angle: 0.28,
                child: const DragonWing(side: WingSide.right),
              ),
            ),
            Positioned(
              top: 12,
              child: Container(
                width: 16,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF8F00),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 28,
              left: 82,
              child: const HornWidget(),
            ),
            Positioned(
              top: 28,
              right: 82,
              child: const HornWidget(),
            ),
            Positioned(
              top: 36,
              child: Container(
                width: 128,
                height: 118,
                decoration: BoxDecoration(
                  color: const Color(0xFF4DD0E1),
                  borderRadius: BorderRadius.circular(38),
                  border: Border.all(
                    color: const Color(0xFF2C3E50),
                    width: 3,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 16,
                      child: Container(
                        width: 98,
                        height: 62,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D4F73),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white,
                            width: 5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            BuddyEye(isHappy: isHappy),
                            const SizedBox(width: 16),
                            BuddyEye(isHappy: isHappy),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 84,
                      child: Row(
                        children: const [
                          NostrilDot(),
                          SizedBox(width: 10),
                          NostrilDot(),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      child: Container(
                        width: isHappy ? 34 : 28,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF053B50),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 126,
              child: Container(
                width: 132,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFF12BFCB),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color(0xFF2C3E50),
                    width: 3,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 18,
                      child: Container(
                        width: 54,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC145),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE68A00),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 28,
                      child: Container(
                        width: 42,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7E57C2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 28,
              left: 58,
              child: const BuddyFoot(),
            ),
            Positioned(
              bottom: 28,
              right: 58,
              child: const BuddyFoot(),
            ),
            Positioned(
              bottom: 58,
              left: 42,
              child: const BuddyArm(side: WingSide.left),
            ),
            Positioned(
              bottom: 58,
              right: 42,
              child: const BuddyArm(side: WingSide.right),
            ),
            Positioned(
              bottom: 52,
              right: 28,
              child: Transform.rotate(
                angle: 0.42,
                child: Container(
                  width: 64,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF12BFCB),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF2C3E50),
                      width: 3,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF8E44AD),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (isHappy)
              const Positioned(
                top: 42,
                right: 22,
                child: Text("✨", style: TextStyle(fontSize: 26)),
              ),
          ],
        ),
      ),
    );
  }
}

enum WingSide { left, right }

class DragonWing extends StatelessWidget {
  final WingSide side;

  const DragonWing({super.key, required this.side});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: WingClipper(side: side),
      child: Container(
        width: 64,
        height: 74,
        decoration: BoxDecoration(
          color: const Color(0xFF9C4DFF),
          border: Border.all(
            color: const Color(0xFF2C3E50),
            width: 3,
          ),
        ),
      ),
    );
  }
}

class WingClipper extends CustomClipper<Path> {
  final WingSide side;

  WingClipper({required this.side});

  @override
  Path getClip(Size size) {
    final path = Path();

    if (side == WingSide.left) {
      path.moveTo(size.width, 0);
      path.quadraticBezierTo(size.width * 0.3, size.height * 0.1, 0, size.height * 0.58);
      path.quadraticBezierTo(size.width * 0.34, size.height * 0.48, size.width * 0.55, size.height * 0.66);
      path.quadraticBezierTo(size.width * 0.74, size.height * 0.42, size.width, size.height * 0.48);
      path.close();
    } else {
      path.moveTo(0, 0);
      path.quadraticBezierTo(size.width * 0.7, size.height * 0.1, size.width, size.height * 0.58);
      path.quadraticBezierTo(size.width * 0.66, size.height * 0.48, size.width * 0.45, size.height * 0.66);
      path.quadraticBezierTo(size.width * 0.26, size.height * 0.42, 0, size.height * 0.48);
      path.close();
    }

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class HornWidget extends StatelessWidget {
  const HornWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 30),
      painter: HornPainter(),
    );
  }
}

class HornPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = const Color(0xFF8E44AD)
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = const Color(0xFF5E2A84)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..quadraticBezierTo(size.width * 0.1, size.height * 0.3, 0, size.height)
      ..lineTo(size.width, size.height)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.3, size.width / 2, 0)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BuddyEye extends StatelessWidget {
  final bool isHappy;

  const BuddyEye({super.key, required this.isHappy});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 12,
          height: isHappy ? 12 : 14,
          decoration: const BoxDecoration(
            color: Color(0xFF0D1B2A),
            shape: BoxShape.circle,
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(left: 2, top: 2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NostrilDot extends StatelessWidget {
  const NostrilDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: Color(0xFF0D4F73),
        shape: BoxShape.circle,
      ),
    );
  }
}

class BuddyArm extends StatelessWidget {
  final WingSide side;

  const BuddyArm({super.key, required this.side});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: side == WingSide.left ? -0.35 : 0.35,
      child: Container(
        width: 34,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFF12BFCB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF2C3E50),
            width: 3,
          ),
        ),
      ),
    );
  }
}

class BuddyFoot extends StatelessWidget {
  const BuddyFoot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF12BFCB),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF2C3E50),
          width: 3,
        ),
      ),
      child: Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Color(0xFFFFC145),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class StoryCard extends StatelessWidget {
  final String text;

  const StoryCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 760;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFF4B400),
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(child: StoryTextArea(text: text)),
                const SizedBox(width: 16),
                const StoryThumbnail(),
              ],
            )
          : Column(
              children: [
                StoryTextArea(text: text),
                const SizedBox(height: 14),
                const StoryThumbnail(),
              ],
            ),
    );
  }
}

class StoryTextArea extends StatelessWidget {
  final String text;

  const StoryTextArea({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(
              child: Divider(
                thickness: 2,
                color: Color(0xFFF5D7A1),
                endIndent: 10,
              ),
            ),
            Icon(Icons.star, color: Color(0xFFF4B400), size: 20),
            SizedBox(width: 10),
            Text(
              "Today's Story",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFF6B35),
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.star, color: Color(0xFFF4B400), size: 20),
            Expanded(
              child: Divider(
                thickness: 2,
                color: Color(0xFFF5D7A1),
                indent: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF182B6C),
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class StoryThumbnail extends StatelessWidget {
  const StoryThumbnail({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 115,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF94D79B),
            Color(0xFF72C9A0),
            Color(0xFFB2F0FF),
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 14,
            bottom: 16,
            child: Icon(Icons.park, size: 36, color: Colors.green.shade800),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: Icon(Icons.park, size: 40, color: Colors.green.shade700),
          ),
          Positioned(
            left: 62,
            bottom: 18,
            child: Icon(Icons.settings, size: 46, color: Colors.blue.shade700),
          ),
          Positioned(
            top: 10,
            right: 12,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReadStoryButton extends StatelessWidget {
  final StoryQuizProvider provider;

  const ReadStoryButton({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isPreparing = provider.audioState == AudioState.preparing;
    final isSpeaking = provider.audioState == AudioState.speaking;

    return Container(
      width: double.infinity,
      height: 84,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(42),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB347), Color(0xFFFF2D79)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: isPreparing || isSpeaking ? null : provider.readStory,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(38),
            side: const BorderSide(color: Color(0xFFFFC16F), width: 2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: isPreparing
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Color(0xFFFF7A00),
                      ),
                    )
                  : Icon(
                      isSpeaking ? Icons.graphic_eq : Icons.volume_up_rounded,
                      color: const Color(0xFFFF6B35),
                      size: 30,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Center(
                child: Text(
                  isPreparing
                      ? "Preparing..."
                      : isSpeaking
                          ? "Reading..."
                          : "Read Me a Story",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0x55000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 54),
          ],
        ),
      ),
    );
  }
}

class QuizCard extends StatelessWidget {
  final StoryQuizProvider provider;

  const QuizCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final bool isWrong = provider.wrongAttempt;
    final bool isSuccess = provider.success;

    Color bgColor;
    Color borderColor;
    Color titleColor;
    Color shadowColor;

    if (isSuccess) {
      bgColor = const Color(0xFFE8FFF0);
      borderColor = const Color(0xFF34C759);
      titleColor = const Color(0xFF5D3FD3);
      shadowColor = const Color(0x4434C759);
    } else if (isWrong) {
      bgColor = const Color(0xFFFFE4E6);
      borderColor = const Color(0xFFFF4D4F);
      titleColor = const Color(0xFFD72638);
      shadowColor = const Color(0x44FF4D4F);
    } else {
      bgColor = Colors.white.withOpacity(0.95);
      borderColor = const Color(0xFFB388FF);
      titleColor = const Color(0xFF7E57C2);
      shadowColor = const Color(0x22000000);
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey('shake_${provider.shakeCount}_${provider.success}'),
      tween: Tween(begin: 0, end: isWrong ? 1 : 0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.elasticIn,
      builder: (context, value, child) {
        final dx = sin(value * pi * 8) * 12;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: 4),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Divider(
                    thickness: 2,
                    color: borderColor.withOpacity(0.35),
                    endIndent: 10,
                  ),
                ),
                Text(
                  isSuccess
                      ? "Success!"
                      : isWrong
                          ? "Oops! Try Again!"
                          : "Quiz Time!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
                Expanded(
                  child: Divider(
                    thickness: 2,
                    color: borderColor.withOpacity(0.35),
                    indent: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              provider.quiz.question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF182B6C),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            QuizOptionsGrid(provider: provider),
            const SizedBox(height: 14),
            if (isWrong)
              const Text(
                "Wrong answer! Try one more time.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD72638),
                ),
              ),
            if (isSuccess)
              const Text(
                "Yay! Pip's shiny blue gear is found! 🎉",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF15803D),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class QuizOptionsGrid extends StatelessWidget {
  final StoryQuizProvider provider;

  const QuizOptionsGrid({super.key, required this.provider});

  Color _defaultOptionColor(int index) {
    const colors = [
      Color(0xFFD8ECFF),
      Color(0xFFE4F7CF),
      Color(0xFFFFF1BF),
      Color(0xFFFFE0EA),
      Color(0xFFE9D5FF),
    ];
    return colors[index % colors.length];
  }

  Color _defaultBorderColor(int index) {
    const colors = [
      Color(0xFF63B3ED),
      Color(0xFF8BC34A),
      Color(0xFFF4C542),
      Color(0xFFF48FB1),
      Color(0xFFB388FF),
    ];
    return colors[index % colors.length];
  }

  String _optionLetter(int index) {
    return String.fromCharCode(65 + index);
  }

  @override
  Widget build(BuildContext context) {
    final options = provider.quiz.options;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final halfWidth = (maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(options.length, (index) {
            final option = options[index];
            final isLastOddItem = options.length.isOdd && index == options.length - 1;
            final isCorrect = option == provider.quiz.answer;
            final isSelectedWrong =
                provider.wrongAttempt && provider.selectedOption == option && !isCorrect;

            Color bg;
            Color border;
            Color circle;
            Color textColor = const Color(0xFF182B6C);

            if (provider.success) {
              bg = isCorrect
                  ? const Color(0xFFC8F7D1)
                  : const Color(0xFFE9FBEF);
              border = const Color(0xFF34C759);
              circle = const Color(0xFF34C759);
              textColor = const Color(0xFF166534);
            } else if (isSelectedWrong) {
              bg = const Color(0xFFFFD5D8);
              border = const Color(0xFFFF4D4F);
              circle = const Color(0xFFFF6B6B);
              textColor = const Color(0xFF9F1239);
            } else {
              bg = _defaultOptionColor(index);
              border = _defaultBorderColor(index);
              circle = _defaultBorderColor(index);
            }

            return SizedBox(
              width: options.length == 1
                  ? maxWidth
                  : isLastOddItem
                      ? maxWidth
                      : halfWidth,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: provider.success
                    ? null
                    : () => provider.checkAnswer(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: border, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x15000000),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: circle,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _optionLetter(index),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class BottomHint extends StatelessWidget {
  const BottomHint({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("💖", style: TextStyle(fontSize: 24)),
        SizedBox(width: 10),
        Flexible(
          child: Text(
            "Listen carefully and choose the right answer!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF4A2F8A),
            ),
          ),
        ),
      ],
    );
  }
}

class CloudWidget extends StatelessWidget {
  final double width;
  final double height;

  const CloudWidget({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: width * 0.12,
            bottom: 0,
            child: _cloudCircle(height * 0.55),
          ),
          Positioned(
            left: width * 0.30,
            top: 0,
            child: _cloudCircle(height * 0.72),
          ),
          Positioned(
            right: width * 0.10,
            bottom: 0,
            child: _cloudCircle(height * 0.58),
          ),
          Positioned(
            left: width * 0.18,
            right: width * 0.16,
            bottom: 0,
            child: Container(
              height: height * 0.48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cloudCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
    );
  }
}

class Sparkle extends StatelessWidget {
  final double size;

  const Sparkle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome,
      size: size,
      color: Colors.white.withOpacity(0.92),
    );
  }
}

class StarBurst extends StatelessWidget {
  final Color color;
  final double size;

  const StarBurst({
    super.key,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.star_rounded,
      size: size,
      color: color,
    );
  }
}