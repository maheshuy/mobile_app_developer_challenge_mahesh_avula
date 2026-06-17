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
          fontFamily: 'Comic Sans MS',
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
      question: json['question'],
      options: List<String>.from(json['options']),
      answer: json['answer'],
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
  String friendlyMessage = "Tap the button and I will read the story!";

  StoryQuizProvider() {
    quiz = QuizData.fromJson(jsonDecode(quizJson));

    _tts.setStartHandler(() {
      audioState = AudioState.speaking;
      friendlyMessage = "Story time is playing...";
      notifyListeners();
    });

    _tts.setCompletionHandler(() {
      audioState = AudioState.completed;
      showQuiz = true;
      friendlyMessage = "Great listening! Now answer the quiz.";
      notifyListeners();
    });

    _tts.setErrorHandler((message) {
      audioState = AudioState.failed;
      friendlyMessage = "Oops! I could not read right now. Please try again.";
      notifyListeners();
    });
  }

  Future<void> readStory() async {
    try {
      showQuiz = false;
      success = false;
      wrongAttempt = false;
      audioState = AudioState.preparing;
      friendlyMessage = "Getting the story ready...";
      notifyListeners();

      await _tts.setLanguage("en-IN");
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.15);
      await _tts.speak(storyText);
    } catch (_) {
      audioState = AudioState.failed;
      friendlyMessage = "Oops! Something went wrong. Tap again to retry.";
      notifyListeners();
    }
  }

  void checkAnswer(String selected) {
    if (selected == quiz.answer) {
      success = true;
      wrongAttempt = false;
      friendlyMessage = "Yay! You found Pip's blue gear!";
      HapticFeedback.mediumImpact();
    } else {
      wrongAttempt = true;
      friendlyMessage = "Oops! Try again, little explorer!";
      HapticFeedback.heavyImpact();

      Future.delayed(const Duration(milliseconds: 500), () {
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

    if (provider.success) {
      _confettiController.play();
    }

    return Scaffold(
      body: Stack(
        children: [
          const _JoyfulBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    "Peblo Story Buddy",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3D2C8D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    provider.friendlyMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5E548E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  BuddyCharacter(isHappy: provider.success),
                  const SizedBox(height: 18),
                  StoryCard(text: provider.storyText),
                  const SizedBox(height: 18),
                  ReadStoryButton(provider: provider),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: provider.showQuiz
                        ? QuizCard(
                            key: const ValueKey("quiz"),
                            provider: provider,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.08,
              numberOfParticles: 20,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _JoyfulBackground extends StatelessWidget {
  const _JoyfulBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFF3B0),
            Color(0xFFFFD6E0),
            Color(0xFFD0F4DE),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class BuddyCharacter extends StatelessWidget {
  final bool isHappy;

  const BuddyCharacter({super.key, required this.isHappy});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 145,
      height: 145,
      decoration: BoxDecoration(
        color: isHappy ? const Color(0xFFFFC857) : const Color(0xFF7BDFF2),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          isHappy ? "🤖🎉" : "🤖",
          style: const TextStyle(fontSize: 70),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFF9F1C), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Today's Story",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3D405B),
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
    final isLoading = provider.audioState == AudioState.preparing;
    final isSpeaking = provider.audioState == AudioState.speaking;

    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        onPressed: isLoading || isSpeaking ? null : provider.readStory,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          elevation: 8,
        ),
        child: isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Preparing...",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              )
            : Text(
                isSpeaking ? "Reading..." : "Read Me a Story",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
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
    return AnimatedSlide(
      duration: const Duration(milliseconds: 120),
      offset: provider.wrongAttempt ? const Offset(0.04, 0) : Offset.zero,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: provider.success
              ? const Color(0xFFD0F4DE)
              : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: provider.success
                ? const Color(0xFF2ECC71)
                : const Color(0xFF9B5DE5),
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              provider.success ? "Success!" : "Quiz Time!",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: provider.success
                    ? const Color(0xFF1B9AAA)
                    : const Color(0xFF7B2CBF),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              provider.quiz.question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3D405B),
              ),
            ),
            const SizedBox(height: 16),

            // DATA-DRIVEN OPTIONS: no hardcoding here
            ...provider.quiz.options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: provider.success
                        ? null
                        : () => provider.checkAnswer(option),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BBF9),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF80ED99),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      option,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (provider.success)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "Pip's shiny blue gear is found!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2D6A4F),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}