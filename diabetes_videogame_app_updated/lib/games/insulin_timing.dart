import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/shared_widgets.dart';
import '../data/game_data.dart';
import 'dart:math';

class InsulinTimingGame extends StatefulWidget {
  const InsulinTimingGame({super.key});

  @override
  State<InsulinTimingGame> createState() => _InsulinTimingGameState();
}

class _InsulinTimingGameState extends State<InsulinTimingGame> {
  int currentQuestion = 0;
  int? selectedAnswer;
  int score = 0;
  bool answered = false;
  bool gameComplete = false;

  InsulinScenario get question => insulinScenarios[currentQuestion];

  void _handleAnswer(int index) {
    if (answered) return;

    setState(() {
      answered = true;
      selectedAnswer = index;

      final option = question.options[index];
      if (option.timing == question.correctTiming) {
        score += 100;
      }
    });
  }

  void _nextQuestion() {
    if (currentQuestion >= insulinScenarios.length - 1) {
      setState(() => gameComplete = true);
    } else {
      setState(() {
        currentQuestion++;
        selectedAnswer = null;
        answered = false;
      });
    }
  }

  void _resetGame() {
    setState(() {
      currentQuestion = 0;
      selectedAnswer = null;
      score = 0;
      answered = false;
      gameComplete = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (gameComplete) {
      final percentage = (score / (insulinScenarios.length * 100) * 100).round();

      String resultMessage;
      if (percentage >= 80) {
        resultMessage = "Excellent timing knowledge!";
      } else if (percentage >= 60) {
        resultMessage = "Good understanding, keep learning!";
      } else {
        resultMessage = "Review insulin timing principles and try again!";
      }

      return Scaffold(
        body: GameOverScreen(
          title: 'Training Complete!',
          emoji: '💉',
          score: score,
          maxScore: insulinScenarios.length * 100,
          message: resultMessage,
          onPlayAgain: _resetGame,
          onBack: () => Navigator.pop(context),
        ),
      );
    }

    return GameScaffold(
      title: 'Insulin Timing',
      emoji: '⏱️',
      actions: [
        ScoreDisplay(
          score: score,
          maxScore: insulinScenarios.length * 100,
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
                  'Question ${currentQuestion + 1} of ${insulinScenarios.length}',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                ),
                Text(
                  question.insulinType == 'rapid' ? '⚡ Rapid-Acting' : '🕐 Long-Acting',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ProgressIndicatorBar(
              current: currentQuestion + 1,
              total: insulinScenarios.length,
            ),
            const SizedBox(height: 20),

            // Question Card
            GlassCard(
              child: Column(
                children: [
                  // Question
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💉', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question.question,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                              if (question.mealType != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    question.mealType == 'high-fat'
                                        ? '🍕 High-Fat Meal'
                                        : '🥗 Low-Carb Meal',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFFFCD34D),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Options
                  ...List.generate(question.options.length, (index) {
                    final option = question.options[index];
                    final isSelected = selectedAnswer == index;
                    final isCorrect = option.timing == question.correctTiming;

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
                                // Feedback with visualization
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.feedback,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: isCorrect
                                                ? const Color(0xFF6EE7B7)
                                                : const Color(0xFFFCA5A5),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Insulin curve visualization
                                        _InsulinCurveChart(timing: option.timing),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Next Button
                  if (answered) ...[
                    const SizedBox(height: 16),
                    GameButton(
                      text: currentQuestion >= insulinScenarios.length - 1
                          ? 'See Results'
                          : 'Next Question →',
                      onPressed: _nextQuestion,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Educational Info
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📚 Insulin Timing Basics',
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚡ Rapid-Acting:',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF60A5FA),
                              ),
                            ),
                            Text(
                              'Starts: 15 min\nPeaks: 1-2 hrs\nDuration: 3-5 hrs',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🕐 Long-Acting:',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFA78BFA),
                              ),
                            ),
                            Text(
                              'Starts: 2 hrs\nNo peak\nDuration: 20-24 hrs',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ],
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

class _InsulinCurveChart extends StatelessWidget {
  final String timing;

  const _InsulinCurveChart({required this.timing});

  @override
  Widget build(BuildContext context) {
    // Generate insulin action curve data
    List<FlSpot> insulinData = [];
    List<FlSpot> mealData = [];

    for (double i = 0; i <= 6; i += 0.25) {
      // Insulin curve (peaks around 1.5 hours)
      double insulinValue = exp(-pow(i - 1.5, 2) / 0.8) * 100;
      insulinData.add(FlSpot(i, insulinValue));

      // Meal absorption curve (varies by timing)
      double mealStart = 0.33; // Default optimal
      switch (timing) {
        case 'early':
          mealStart = 0.75;
          break;
        case 'optimal':
          mealStart = 0.33;
          break;
        case 'late':
        case 'standard':
          mealStart = 0;
          break;
        case 'very_late':
          mealStart = -0.5;
          break;
      }

      double mealValue = 0;
      if (i >= (0.33 - mealStart)) {
        mealValue = exp(-pow(i - (0.33 - mealStart) - 1, 2) / 1.2) * 80;
      }
      mealData.add(FlSpot(i, mealValue));
    }

    return Column(
      children: [
        SizedBox(
          height: 100,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 2,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}h',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white38,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: insulinData,
                  isCurved: true,
                  color: const Color(0xFF3B82F6),
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: mealData,
                  isCurved: true,
                  color: const Color(0xFFF59E0B),
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Insulin',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF60A5FA),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Carbs',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFFFCD34D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
