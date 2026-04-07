import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/shared_widgets.dart';
import '../data/game_data.dart';

class EmergencyResponseGame extends StatefulWidget {
  const EmergencyResponseGame({super.key});

  @override
  State<EmergencyResponseGame> createState() => _EmergencyResponseGameState();
}

class _EmergencyResponseGameState extends State<EmergencyResponseGame> {
  int currentScenario = 0;
  int? selectedAnswer;
  int score = 0;
  bool answered = false;
  int timeLeft = 30;
  bool timerActive = true;
  bool gameComplete = false;
  int streak = 0;
  Timer? _timer;

  EmergencyScenario get scenario => emergencyScenarios[currentScenario];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!timerActive || answered || gameComplete) return;

      setState(() {
        if (timeLeft <= 1) {
          _handleTimeout();
        } else {
          timeLeft--;
        }
      });
    });
  }

  void _handleTimeout() {
    setState(() {
      answered = true;
      selectedAnswer = -1;
      streak = 0;
    });
  }

  void _handleAnswer(int index) {
    if (answered) return;

    setState(() {
      answered = true;
      selectedAnswer = index;
      timerActive = false;

      final option = scenario.options[index];
      if (option.correct) {
        final timeBonus = (timeLeft / 3).floor();
        final points = 100 + timeBonus + (streak * 10);
        score += points;
        streak++;
      } else {
        streak = 0;
      }
    });
  }

  void _nextScenario() {
    if (currentScenario >= emergencyScenarios.length - 1) {
      setState(() => gameComplete = true);
    } else {
      setState(() {
        currentScenario++;
        selectedAnswer = null;
        answered = false;
        timeLeft = 30;
        timerActive = true;
      });
      _startTimer();
    }
  }

  void _resetGame() {
    setState(() {
      currentScenario = 0;
      selectedAnswer = null;
      score = 0;
      answered = false;
      timeLeft = 30;
      timerActive = true;
      gameComplete = false;
      streak = 0;
    });
    _startTimer();
  }

  Color _getTimerColor() {
    if (timeLeft > 20) return const Color(0xFF10B981);
    if (timeLeft > 10) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    if (gameComplete) {
      final maxPossible = emergencyScenarios.length * 110;
      final percentage = (score / maxPossible * 100).round();

      String resultMessage;
      if (percentage >= 80) {
        resultMessage = "You're ready for emergencies!";
      } else if (percentage >= 60) {
        resultMessage = "Good knowledge, keep practicing!";
      } else {
        resultMessage = "Review emergency protocols and try again!";
      }

      return Scaffold(
        body: GameOverScreen(
          title: 'Training Complete!',
          emoji: '🚑',
          score: score,
          maxScore: maxPossible,
          message: resultMessage,
          onPlayAgain: _resetGame,
          onBack: () => Navigator.pop(context),
        ),
      );
    }

    return GameScaffold(
      title: 'Emergency Response',
      emoji: '🚨',
      actions: [
        if (streak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '🔥 $streak Streak',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ),
        const SizedBox(width: 8),
        ScoreDisplay(
          score: score,
          maxScore: emergencyScenarios.length * 110,
          label: 'Score',
        ),
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
                  'Scenario ${currentScenario + 1} of ${emergencyScenarios.length}',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                ),
                Text(
                  scenario.category,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ProgressIndicatorBar(
              current: currentScenario + 1,
              total: emergencyScenarios.length,
            ),
            const SizedBox(height: 16),

            // Timer
            if (!answered)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    const Text('⏱️', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: timeLeft / 30,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getTimerColor(),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${timeLeft}s',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getTimerColor(),
                      ),
                    ),
                  ],
                ),
              ),

            // Scenario Card
            GlassCard(
              child: Column(
                children: [
                  // Situation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🚨', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EMERGENCY SCENARIO',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                scenario.situation,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Options
                  ...List.generate(scenario.options.length, (index) {
                    final option = scenario.options[index];
                    final isSelected = selectedAnswer == index;
                    final isCorrect = option.correct;

                    Color bgColor = Colors.white.withOpacity(0.1);
                    Color borderColor = Colors.white.withOpacity(0.2);

                    if (answered) {
                      if (isCorrect) {
                        bgColor = const Color(0xFF10B981).withOpacity(0.3);
                        borderColor = const Color(0xFF10B981);
                      } else if (isSelected && !isCorrect) {
                        bgColor = const Color(0xFFEF4444).withOpacity(0.3);
                        borderColor = const Color(0xFFEF4444);
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: answered ? null : () => _handleAnswer(index),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: answered && isCorrect
                                            ? const Color(0xFF10B981)
                                            : answered && isSelected
                                                ? const Color(0xFFEF4444)
                                                : Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Center(
                                        child: answered && isCorrect
                                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                                            : Text(
                                                String.fromCharCode(65 + index),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        option.text,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Feedback
                                if (answered && (isSelected || isCorrect))
                                  Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isCorrect
                                          ? const Color(0xFF10B981).withOpacity(0.2)
                                          : const Color(0xFFEF4444).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      option.feedback,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: isCorrect
                                            ? const Color(0xFF6EE7B7)
                                            : const Color(0xFFFCA5A5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Timeout Message
                  if (selectedAnswer == -1)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "⏰ Time's up! In emergencies, quick action is critical.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFCD34D),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Next Button
                  if (answered) ...[
                    const SizedBox(height: 20),
                    GameButton(
                      text: currentScenario >= emergencyScenarios.length - 1
                          ? 'See Results'
                          : 'Next Scenario →',
                      onPressed: _nextScenario,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
