import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/shared_widgets.dart';

class GlucoseGuardianGame extends StatefulWidget {
  const GlucoseGuardianGame({super.key});

  @override
  State<GlucoseGuardianGame> createState() => _GlucoseGuardianGameState();
}

class _GlucoseGuardianGameState extends State<GlucoseGuardianGame> {
  double glucose = 120;
  List<FlSpot> history = [];
  int time = 0;
  int score = 0;
  double insulinOnBoard = 0;
  double carbsDigesting = 0;
  double activityLevel = 0;
  bool gameOver = false;
  bool isPaused = false;
  String message = 'Welcome! Keep glucose in the green zone.';
  Timer? _timer;
  final Random _random = Random();

  static const double targetLow = 70;
  static const double targetHigh = 180;
  static const double dangerLow = 54;
  static const double dangerHigh = 250;

  @override
  void initState() {
    super.initState();
    history.add(FlSpot(0, glucose));
    _startGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (gameOver || isPaused) return;

      setState(() {
        time++;

        // Calculate glucose changes
        double change = 0;

        // Insulin effect (lowers glucose)
        change -= insulinOnBoard * 3;

        // Carbs effect (raises glucose)
        change += carbsDigesting * 2;

        // Activity effect (lowers glucose)
        change -= activityLevel * 2;

        // Random drift
        change += (_random.nextDouble() - 0.5) * 5;

        // Dawn phenomenon (slight rise)
        change += 0.5;

        glucose = (glucose + change).clamp(40, 400);

        // Update message based on glucose level
        _updateMessage();

        // Decay effects over time
        insulinOnBoard = max(0, insulinOnBoard - 0.1);
        carbsDigesting = max(0, carbsDigesting - 0.15);
        activityLevel = max(0, activityLevel - 0.2);

        // Update history (keep last 30 points)
        history.add(FlSpot(time.toDouble(), glucose));
        if (history.length > 30) {
          history.removeAt(0);
        }

        // Score for time in range
        if (glucose >= targetLow && glucose <= targetHigh) {
          score++;
        }

        // Game over conditions
        if (glucose < 40 || glucose > 350) {
          gameOver = true;
          _timer?.cancel();
        }
      });
    });
  }

  void _updateMessage() {
    if (glucose < dangerLow) {
      message = '⚠️ SEVERE HYPOGLYCEMIA! Immediate action needed!';
    } else if (glucose > dangerHigh) {
      message = '⚠️ SEVERE HYPERGLYCEMIA! Consider correction dose.';
    } else if (glucose < targetLow) {
      message = '⚡ Low glucose warning - consider carbs';
    } else if (glucose > targetHigh) {
      message = '📈 Above target range';
    } else {
      message = '✅ In target range!';
    }
  }

  void _takeInsulin(int units) {
    setState(() {
      insulinOnBoard += units;
      message = '💉 Took $units unit${units > 1 ? 's' : ''} of insulin';
    });
  }

  void _eatCarbs(int grams) {
    setState(() {
      carbsDigesting += grams / 15;
      message = '🍎 Ate ${grams}g of carbs';
    });
  }

  void _doActivity(int intensity) {
    setState(() {
      activityLevel += intensity;
      message = intensity > 1 ? '🏃 Started intense activity' : '🚶 Started light walk';
    });
  }

  Color _getGlucoseColor() {
    if (glucose < targetLow) return const Color(0xFFEF4444);
    if (glucose > targetHigh) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    if (gameOver) {
      return Scaffold(
        body: GameOverScreen(
          title: 'Game Over!',
          emoji: '🎮',
          score: score,
          maxScore: time,
          message: 'Final Glucose: ${glucose.round()} mg/dL\nTime in Range: $score seconds',
          onPlayAgain: () {
            setState(() {
              glucose = 120;
              history = [FlSpot(0, 120)];
              time = 0;
              score = 0;
              insulinOnBoard = 0;
              carbsDigesting = 0;
              activityLevel = 0;
              gameOver = false;
              isPaused = false;
              message = 'Welcome! Keep glucose in the green zone.';
            });
            _startGame();
          },
          onBack: () => Navigator.pop(context),
        ),
      );
    }

    return GameScaffold(
      title: 'Glucose Guardian',
      emoji: '🛡️',
      actions: [
        IconButton(
          onPressed: () => setState(() => isPaused = !isPaused),
          icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 8),
        ScoreDisplay(score: score, maxScore: time, label: 'Time in Range'),
      ],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Glucose Display
            GlassCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Glucose',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                glucose.round().toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: _getGlucoseColor(),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8, left: 4),
                                child: Text(
                                  'mg/dL',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white60,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Target Range',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                          Text(
                            '${targetLow.toInt()} - ${targetHigh.toInt()} mg/dL',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Chart
                  SizedBox(
                    height: 150,
                    child: LineChart(
                      LineChartData(
                        minY: 40,
                        maxY: 300,
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: history,
                            isCurved: true,
                            color: _getGlucoseColor(),
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: _getGlucoseColor().withOpacity(0.2),
                            ),
                          ),
                        ],
                        rangeAnnotations: RangeAnnotations(
                          horizontalRangeAnnotations: [
                            HorizontalRangeAnnotation(
                              y1: targetLow,
                              y2: targetHigh,
                              color: const Color(0xFF10B981).withOpacity(0.1),
                            ),
                          ],
                        ),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: targetLow,
                              color: const Color(0xFFEF4444).withOpacity(0.5),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                            HorizontalLine(
                              y: targetHigh,
                              color: const Color(0xFFF59E0B).withOpacity(0.5),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Status Indicators
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Effects',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StatusRow(
                    emoji: '💉',
                    label: 'Insulin on Board',
                    value: '${insulinOnBoard.toStringAsFixed(1)} units',
                    progress: insulinOnBoard / 5,
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 8),
                  _StatusRow(
                    emoji: '🍎',
                    label: 'Carbs Digesting',
                    value: '${(carbsDigesting * 15).toStringAsFixed(0)}g',
                    progress: carbsDigesting / 5,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 8),
                  _StatusRow(
                    emoji: '🏃',
                    label: 'Activity Level',
                    value: activityLevel > 0 ? 'Active' : 'Resting',
                    progress: activityLevel / 3,
                    color: const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Controls
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _ControlCard(
                      title: '💉 Insulin',
                      buttons: [
                        _ControlButton(label: '1u', onTap: () => _takeInsulin(1)),
                        _ControlButton(label: '2u', onTap: () => _takeInsulin(2)),
                        _ControlButton(label: '3u', onTap: () => _takeInsulin(3)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ControlCard(
                      title: '🍎 Carbs',
                      buttons: [
                        _ControlButton(label: '15g', onTap: () => _eatCarbs(15)),
                        _ControlButton(label: '30g', onTap: () => _eatCarbs(30)),
                        _ControlButton(label: '45g', onTap: () => _eatCarbs(45)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ControlCard(
                      title: '🏃 Activity',
                      buttons: [
                        _ControlButton(label: 'Walk', onTap: () => _doActivity(1)),
                        _ControlButton(label: 'Run', onTap: () => _doActivity(2)),
                      ],
                    ),
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

class _StatusRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _StatusRow({
    required this.emoji,
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ProgressIndicatorBar(
                current: (progress * 100).toInt(),
                total: 100,
                color: color,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlCard extends StatelessWidget {
  final String title;
  final List<_ControlButton> buttons;

  const _ControlCard({
    required this.title,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ...buttons.map((btn) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: btn,
          )),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ControlButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
