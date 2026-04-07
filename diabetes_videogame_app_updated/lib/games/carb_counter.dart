import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/shared_widgets.dart';
import '../data/game_data.dart';

class CarbCounterGame extends StatefulWidget {
  const CarbCounterGame({super.key});

  @override
  State<CarbCounterGame> createState() => _CarbCounterGameState();
}

class _CarbCounterGameState extends State<CarbCounterGame> {
  late FoodItem currentFood;
  final TextEditingController _guessController = TextEditingController();
  int score = 0;
  int round = 1;
  final int maxRounds = 10;
  FeedbackData? feedback;
  List<String> usedFoods = [];
  bool gameComplete = false;
  bool showHint = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _selectNewFood();
  }

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  void _selectNewFood() {
    final available = foodItems.where((f) => !usedFoods.contains(f.name)).toList();
    if (available.isEmpty || round > maxRounds) {
      setState(() => gameComplete = true);
      return;
    }
    currentFood = available[_random.nextInt(available.length)];
    usedFoods.add(currentFood.name);
    _guessController.clear();
    feedback = null;
    showHint = false;
  }

  void _submitGuess() {
    final guessText = _guessController.text.trim();
    if (guessText.isEmpty) return;

    final guessNum = int.tryParse(guessText);
    if (guessNum == null) return;

    final actual = currentFood.carbs;
    final diff = (guessNum - actual).abs();

    int points;
    String message;
    String emoji;

    if (diff == 0) {
      points = 100;
      message = 'Perfect!';
      emoji = '🎯';
    } else if (diff <= 3) {
      points = 80;
      message = 'Excellent!';
      emoji = '🌟';
    } else if (diff <= 5) {
      points = 60;
      message = 'Great!';
      emoji = '⭐';
    } else if (diff <= 10) {
      points = 40;
      message = 'Good try!';
      emoji = '👍';
    } else if (diff <= 15) {
      points = 20;
      message = 'Close-ish';
      emoji = '🤔';
    } else {
      points = 0;
      message = 'Way off!';
      emoji = '😅';
    }

    setState(() {
      score += points;
      feedback = FeedbackData(
        points: points,
        message: message,
        emoji: emoji,
        actual: actual,
        guess: guessNum,
        diff: diff,
      );
    });
  }

  void _nextRound() {
    if (round >= maxRounds) {
      setState(() => gameComplete = true);
    } else {
      setState(() {
        round++;
        _selectNewFood();
      });
    }
  }

  void _resetGame() {
    setState(() {
      score = 0;
      round = 1;
      usedFoods.clear();
      gameComplete = false;
      _selectNewFood();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (gameComplete) {
      final percentage = (score / (maxRounds * 100) * 100).round();
      String resultEmoji;
      String resultMessage;

      if (percentage >= 80) {
        resultEmoji = '🏆';
        resultMessage = 'Carb counting master!';
      } else if (percentage >= 60) {
        resultEmoji = '🌟';
        resultMessage = 'Great carb awareness!';
      } else if (percentage >= 40) {
        resultEmoji = '👍';
        resultMessage = 'Keep practicing!';
      } else {
        resultEmoji = '📚';
        resultMessage = 'Review carb values and try again!';
      }

      return Scaffold(
        body: GameOverScreen(
          title: 'Challenge Complete!',
          emoji: resultEmoji,
          score: score,
          maxScore: maxRounds * 100,
          message: resultMessage,
          onPlayAgain: _resetGame,
          onBack: () => Navigator.pop(context),
        ),
      );
    }

    return GameScaffold(
      title: 'Carb Counter',
      emoji: '🥗',
      actions: [
        ScoreDisplay(score: score, maxScore: maxRounds * 100, label: 'Score'),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Round $round of $maxRounds',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                ),
                Text(
                  '${(round / maxRounds * 100).round()}% Complete',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ProgressIndicatorBar(current: round, total: maxRounds),
            const SizedBox(height: 24),

            // Food Card
            GlassCard(
              child: Column(
                children: [
                  Text(
                    currentFood.emoji,
                    style: const TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentFood.name,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (showHint) ...[
                    const SizedBox(height: 8),
                    Text(
                      '💡 Hint: ${currentFood.hint}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  if (feedback == null) ...[
                    Text(
                      'How many grams of carbs?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _guessController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 28,
                                color: Colors.white30,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF10B981),
                                  width: 2,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _submitGuess(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'g',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GameButton(
                          text: 'Submit Guess',
                          onPressed: _guessController.text.isNotEmpty ? _submitGuess : null,
                        ),
                        if (!showHint) ...[
                          const SizedBox(width: 12),
                          GameButton(
                            text: '💡 Hint',
                            isOutlined: true,
                            onPressed: () => setState(() => showHint = true),
                          ),
                        ],
                      ],
                    ),
                  ] else ...[
                    // Feedback
                    Text(
                      feedback!.emoji,
                      style: const TextStyle(fontSize: 56),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      feedback!.message,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ResultChip(
                          label: 'Your guess',
                          value: '${feedback!.guess}g',
                          color: Colors.white.withOpacity(0.1),
                        ),
                        const SizedBox(width: 12),
                        _ResultChip(
                          label: 'Actual',
                          value: '${feedback!.actual}g',
                          color: const Color(0xFF10B981).withOpacity(0.2),
                        ),
                        const SizedBox(width: 12),
                        _ResultChip(
                          label: 'Difference',
                          value: '${feedback!.diff}g',
                          color: feedback!.diff <= 5
                              ? const Color(0xFF10B981).withOpacity(0.2)
                              : const Color(0xFFF59E0B).withOpacity(0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+${feedback!.points} points',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GameButton(
                      text: round >= maxRounds ? 'See Results' : 'Next Food →',
                      onPressed: _nextRound,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Reference
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 Carb Reference Guide',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '🍞 1 slice bread ≈ 15g',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '🍎 Medium fruit ≈ 15-25g',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '🥛 1 cup milk ≈ 12g',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '🍚 1 cup rice ≈ 45g',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedbackData {
  final int points;
  final String message;
  final String emoji;
  final int actual;
  final int guess;
  final int diff;

  FeedbackData({
    required this.points,
    required this.message,
    required this.emoji,
    required this.actual,
    required this.guess,
    required this.diff,
  });
}

class _ResultChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.white60),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
