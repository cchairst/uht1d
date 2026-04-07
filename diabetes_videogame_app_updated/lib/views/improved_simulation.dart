import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uh_t1d_tutor/controllers/glucose_simulation_controller.dart';
import 'package:uh_t1d_tutor/controllers/patient_controller.dart';
import 'package:uh_t1d_tutor/models/answer_model.dart';
import '../models/glucose_warning_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Per-answer record for analytics
// ─────────────────────────────────────────────────────────────────────────────
class AnswerRecord {
  final DateTime timestamp;
  final String scenario;
  final String chosenAnswer;
  final String correctAnswer;
  final bool wasCorrect;
  final WarningType warningType;
  final double glucoseAtTime;

  AnswerRecord({
    required this.timestamp,
    required this.scenario,
    required this.chosenAnswer,
    required this.correctAnswer,
    required this.wasCorrect,
    required this.warningType,
    required this.glucoseAtTime,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Main widget
// ─────────────────────────────────────────────────────────────────────────────
class ImprovedGlucoseSimulation extends StatefulWidget {
  const ImprovedGlucoseSimulation({super.key});
  @override
  State<ImprovedGlucoseSimulation> createState() =>
      _ImprovedGlucoseSimulationState();
}

class _ImprovedGlucoseSimulationState extends State<ImprovedGlucoseSimulation>
    with SingleTickerProviderStateMixin {
  bool loading = true;
  bool gameOver = false;

  GlucoseSimulationController glucoseController = GlucoseSimulationController();
  PatientController patientController = PatientController();

  String selectedAnswer = "";
  int selectedAnswerGlucoseEffect = 0;
  int selectedAnswerEffectTime = 0;
  List<GlucoseWarning> warnings = [];
  List<FlSpot> glucosePredictions = [];

  int score = 0;
  int correctAnswers = 0;
  int totalAnswers = 0;
  int timeInRange = 0;
  int iteration = 0;
  String lastFeedback = "";
  bool showFeedback = false;
  bool lastAnswerCorrect = false;

  List<AnswerRecord> answerHistory = [];
  static const int maxQuestions = 20;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    initControllers().then((_) => setState(() => loading = false));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> initControllers() async {
    await patientController.init();
    await glucoseController.init(patientController);
    setState(() {
      glucosePredictions = glucoseController.getPredictionsList();
      warnings = glucoseController.getWarningsList();
    });
  }

  void _endSession() => setState(() => gameOver = true);

  void nextIterationHandler({int affectGlucose = 0, int affectInTime = 0}) {
    glucoseController.nextIterationOfPredictions(
        patientController, affectGlucose, affectInTime);
    setState(() {
      warnings = glucoseController.getWarningsList();
      glucosePredictions = glucoseController.getPredictionsList();
      iteration++;
      if (glucosePredictions.isNotEmpty) {
        double g = glucosePredictions.first.y;
        if (g >= patientController.patient.lowThreshold &&
            g <= patientController.patient.normalThreshold) {
          timeInRange++;
          score += 10;
        }
      }
    });
  }

  void answerSelectionHandler(
      Answer newSelectedAnswer, String correctAnswer, GlucoseWarning warning) {
    if (newSelectedAnswer.text != selectedAnswer) {
      setState(() {
        selectedAnswer = newSelectedAnswer.text;
        selectedAnswerGlucoseEffect = newSelectedAnswer.affectGlucose;
        selectedAnswerEffectTime = newSelectedAnswer.affectInTime;
      });
    } else {
      bool isCorrect = newSelectedAnswer.text == correctAnswer;
      double bg =
          glucosePredictions.isNotEmpty ? glucosePredictions.first.y : 0;

      answerHistory.add(AnswerRecord(
        timestamp: DateTime.now(),
        scenario: warning.scenario,
        chosenAnswer: newSelectedAnswer.text,
        correctAnswer: correctAnswer,
        wasCorrect: isCorrect,
        warningType: warning.type,
        glucoseAtTime: bg,
      ));

      setState(() {
        totalAnswers++;
        if (isCorrect) {
          correctAnswers++;
          score += 50;
          lastFeedback = "✅ Correct! Great decision!";
          lastAnswerCorrect = true;
        } else {
          lastFeedback = "❌ Not quite. Better choice: $correctAnswer";
          lastAnswerCorrect = false;
        }
        showFeedback = true;
        selectedAnswer = "";
        selectedAnswerGlucoseEffect = 0;
        selectedAnswerEffectTime = 0;
      });

      nextIterationHandler(
        affectGlucose: newSelectedAnswer.affectGlucose,
        affectInTime: newSelectedAnswer.affectInTime,
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => showFeedback = false);
          if (totalAnswers >= maxQuestions) _endSession();
        }
      });
    }
  }

  Color _glucoseColor(double g) {
    if (g < patientController.patient.lowThreshold)
      return const Color(0xFFEF4444);
    if (g <= patientController.patient.normalThreshold)
      return const Color(0xFF10B981);
    if (g <= patientController.patient.highThreshold)
      return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _glucoseStatus(double g) {
    if (g < patientController.patient.lowThreshold) return "LOW - Action needed!";
    if (g <= patientController.patient.normalThreshold) return "In Target Range ✓";
    if (g <= patientController.patient.highThreshold) return "HIGH - Monitor closely";
    return "VERY HIGH - Action needed!";
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1)),
        ),
        const Spacer(),
        const Text('🩺', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Text('Glucose Simulation',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const Spacer(),
        TextButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: Text('End Session?',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              content: Text('Stop and view your results?',
                  style: GoogleFonts.poppins(color: Colors.white70)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel',
                        style: GoogleFonts.poppins(color: Colors.white54))),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _endSession();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444)),
                    child: Text('End',
                        style: GoogleFonts.poppins(color: Colors.white))),
              ],
            ),
          ),
          icon: const Icon(Icons.stop_circle_outlined,
              color: Color(0xFFEF4444), size: 18),
          label: Text('Stop',
              style: GoogleFonts.poppins(
                  color: const Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
        _buildScoreChip(),
      ]),
    );
  }

  Widget _buildScoreChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('⭐', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text('$score',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ]),
      );

  // ─── Stats bar ─────────────────────────────────────────────────────────────
  Widget _buildStatsBar() {
    double acc = totalAnswers > 0 ? correctAnswers / totalAnswers * 100 : 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _StatItem(icon: '🎯', label: 'Accuracy', value: '${acc.toStringAsFixed(0)}%'),
        _StatItem(icon: '✅', label: 'Correct', value: '$correctAnswers/$totalAnswers'),
        _StatItem(icon: '⏱️', label: 'In Range', value: '$timeInRange'),
        _StatItem(icon: '❓', label: 'Left', value: '${maxQuestions - totalAnswers}'),
      ]),
    );
  }

  // ─── Glucose display ───────────────────────────────────────────────────────
  Widget _buildCurrentGlucoseDisplay() {
    if (glucosePredictions.isEmpty) return const SizedBox();
    double g = glucosePredictions.first.y;
    Color c = _glucoseColor(g);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.5), width: 2),
      ),
      child: Row(children: [
        ScaleTransition(
          scale: warnings.isNotEmpty
              ? _pulseAnimation
              : const AlwaysStoppedAnimation(1.0),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: c.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: c, width: 3)),
            child: Center(
              child: Text(g.toStringAsFixed(0),
                  style: GoogleFonts.poppins(
                      fontSize: 28, fontWeight: FontWeight.bold, color: c)),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Current Glucose',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60)),
            Text('${g.toStringAsFixed(0)} mg/dL',
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(_glucoseStatus(g),
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: c)),
          ]),
        ),
        if (warnings.isEmpty)
          ElevatedButton.icon(
            onPressed: () => nextIterationHandler(),
            icon: const Icon(Icons.skip_next),
            label: const Text('Next Hour'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ]),
    );
  }

  // ─── Chart ─────────────────────────────────────────────────────────────────
  Widget _buildGlucoseChart() {
    List<FlSpot> chartData = [...glucosePredictions];
    if (selectedAnswer.isNotEmpty) {
      for (int x = 0; x < chartData.length; x++) {
        if (chartData[x].x == selectedAnswerEffectTime.toDouble()) {
          chartData[x] = FlSpot(
              chartData[x].x, chartData[x].y + selectedAnswerGlucoseEffect);
        }
      }
    }
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('📈 Glucose Forecast',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          if (selectedAnswer.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10)),
              child: Text('👁️ Preview',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: const Color(0xFF60A5FA))),
            ),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: LineChart(LineChartData(
            minY: 0,
            maxY: 300,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 50,
              getDrawingHorizontalLine: (v) =>
                  FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 100,
                  reservedSize: 36,
                  getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                      style: GoogleFonts.poppins(
                          fontSize: 9, color: Colors.white60)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 60,
                  getTitlesWidget: (v, _) => Text(
                      '+${(v / 60).round()}h',
                      style: GoogleFonts.poppins(
                          fontSize: 9, color: Colors.white60)),
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              if (selectedAnswer.isNotEmpty)
                LineChartBarData(
                    spots: glucosePredictions,
                    isCurved: true,
                    color: Colors.white.withOpacity(0.3),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 5]),
              LineChartBarData(
                spots: chartData,
                isCurved: true,
                color: selectedAnswer.isNotEmpty
                    ? const Color(0xFF3B82F6)
                    : Colors.white,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: (selectedAnswer.isNotEmpty
                          ? const Color(0xFF3B82F6)
                          : Colors.white)
                      .withOpacity(0.1),
                ),
              ),
            ],
            rangeAnnotations: RangeAnnotations(
              horizontalRangeAnnotations: [
                HorizontalRangeAnnotation(
                    y1: 0,
                    y2: patientController.patient.lowThreshold.toDouble(),
                    color: const Color(0xFFEF4444).withOpacity(0.15)),
                HorizontalRangeAnnotation(
                    y1: patientController.patient.lowThreshold.toDouble(),
                    y2: patientController.patient.normalThreshold.toDouble(),
                    color: const Color(0xFF10B981).withOpacity(0.15)),
                HorizontalRangeAnnotation(
                    y1: patientController.patient.normalThreshold.toDouble(),
                    y2: patientController.patient.highThreshold.toDouble(),
                    color: const Color(0xFFF59E0B).withOpacity(0.15)),
                HorizontalRangeAnnotation(
                    y1: patientController.patient.highThreshold.toDouble(),
                    y2: 300,
                    color: const Color(0xFFEF4444).withOpacity(0.15)),
              ],
            ),
          )),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _LegendItem(color: const Color(0xFFEF4444), label: 'Low/High'),
          const SizedBox(width: 14),
          _LegendItem(color: const Color(0xFF10B981), label: 'Target'),
          const SizedBox(width: 14),
          _LegendItem(color: const Color(0xFFF59E0B), label: 'Elevated'),
        ]),
      ]),
    );
  }

  // ─── Warning modal ─────────────────────────────────────────────────────────
  Widget _buildWarningModal(GlucoseWarning warning) {
    Color wc;
    String we;
    switch (warning.type) {
      case WarningType.low:
        wc = const Color(0xFFEF4444);
        we = '⚠️';
        break;
      case WarningType.high:
        wc = const Color(0xFFF59E0B);
        we = '📈';
        break;
      case WarningType.veryHigh:
        wc = const Color(0xFFEF4444);
        we = '🚨';
        break;
    }

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: wc.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                  color: wc.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5)
            ],
          ),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Progress pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Question ${totalAnswers + 1} of $maxQuestions',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white54,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 14),
              // Header
              Row(children: [
                Text(we, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(warning.title.toUpperCase(),
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: wc)),
                        Text('Alert in ${warning.time.toInt()} min',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.white70)),
                      ]),
                ),
              ]),
              const SizedBox(height: 14),
              // Scenario
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: wc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: wc.withOpacity(0.3)),
                ),
                child: Text(
                  warning.scenario,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Options
              ...warning.options.map((option) {
                bool isSel = option.text == selectedAnswer;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Material(
                    color: isSel
                        ? const Color(0xFF3B82F6).withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => answerSelectionHandler(
                          option, warning.correctOption, warning),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel
                                ? const Color(0xFF3B82F6)
                                : Colors.white.withOpacity(0.2),
                            width: isSel ? 2 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSel
                                  ? const Color(0xFF3B82F6)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF3B82F6)
                                    : Colors.white54,
                                width: 2,
                              ),
                            ),
                            child: isSel
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(option.text,
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: Colors.white)),
                          ),
                        ]),
                      ),
                    ),
                  ),
                );
              }),
              if (selectedAnswer.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('👆 Tap again to confirm',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: const Color(0xFF60A5FA))),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  // ─── Feedback overlay ──────────────────────────────────────────────────────
  Widget _buildFeedbackOverlay() => AnimatedOpacity(
        opacity: showFeedback ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: lastAnswerCorrect
                ? const Color(0xFF10B981).withOpacity(0.9)
                : const Color(0xFFEF4444).withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Text(lastAnswerCorrect ? '✅' : '❌',
                style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(lastFeedback,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // RESULTS SCREEN
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildResultsScreen() {
    double accuracy =
        totalAnswers > 0 ? correctAnswers / totalAnswers * 100 : 0;

    String grade;
    Color gradeColor;
    String gradeEmoji;
    if (accuracy >= 90) {
      grade = 'A'; gradeColor = const Color(0xFF10B981); gradeEmoji = '🏆';
    } else if (accuracy >= 75) {
      grade = 'B'; gradeColor = const Color(0xFF3B82F6); gradeEmoji = '🌟';
    } else if (accuracy >= 60) {
      grade = 'C'; gradeColor = const Color(0xFFF59E0B); gradeEmoji = '📈';
    } else {
      grade = 'D'; gradeColor = const Color(0xFFEF4444); gradeEmoji = '💪';
    }

    // Group by calendar day
    final Map<String, List<AnswerRecord>> byDay = {};
    for (final r in answerHistory) {
      final k =
          '${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2, '0')}-${r.timestamp.day.toString().padLeft(2, '0')}';
      byDay.putIfAbsent(k, () => []).add(r);
    }

    // Category breakdown
    final Map<WarningType, int> typeTotal = {};
    final Map<WarningType, int> typeCorrect = {};
    for (final r in answerHistory) {
      typeTotal[r.warningType] = (typeTotal[r.warningType] ?? 0) + 1;
      if (r.wasCorrect)
        typeCorrect[r.warningType] = (typeCorrect[r.warningType] ?? 0) + 1;
    }

    // Streak
    int maxStreak = 0, curStreak = 0, streak = 0;
    for (final r in answerHistory) {
      if (r.wasCorrect) {
        streak++;
        if (streak > maxStreak) maxStreak = streak;
      } else {
        streak = 0;
      }
    }
    curStreak = streak;

    double avgBg = answerHistory.isEmpty
        ? 0
        : answerHistory
                .map((r) => r.glucoseAtTime)
                .reduce((a, b) => a + b) /
            answerHistory.length;

    final missed = answerHistory.where((r) => !r.wasCorrect).toList();

    String typeLabel(WarningType t) {
      switch (t) {
        case WarningType.low: return 'Low BG Scenarios';
        case WarningType.high: return 'High BG Scenarios';
        case WarningType.veryHigh: return 'Very High BG Scenarios';
      }
    }

    Color typeColor(WarningType t) {
      switch (t) {
        case WarningType.low: return const Color(0xFFEF4444);
        case WarningType.high: return const Color(0xFFF59E0B);
        case WarningType.veryHigh: return const Color(0xFFEF4444);
      }
    }

    String gradeMsg(double a) {
      if (a >= 90) return 'Outstanding! You make excellent T1D management decisions.';
      if (a >= 75) return 'Great work! You have a solid understanding of diabetes management.';
      if (a >= 60) return 'Good effort! Review the scenarios you missed to improve.';
      return 'Keep practicing — every session helps you learn safer T1D decisions.';
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Nav ─────────────────────────────────────────────────────
                Row(children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1)),
                  ),
                  const Spacer(),
                  Text('📊 Session Results',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ]),
                const SizedBox(height: 20),

                // ── Grade card ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradeColor.withOpacity(0.3),
                        gradeColor.withOpacity(0.1)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: gradeColor.withOpacity(0.5), width: 2),
                  ),
                  child: Column(children: [
                    Text(gradeEmoji, style: const TextStyle(fontSize: 52)),
                    const SizedBox(height: 8),
                    Text('Grade $grade',
                        style: GoogleFonts.poppins(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: gradeColor)),
                    Text('${accuracy.toStringAsFixed(1)}% accuracy',
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: Colors.white70)),
                    const SizedBox(height: 12),
                    Text(gradeMsg(accuracy),
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.white70, height: 1.4),
                        textAlign: TextAlign.center),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Summary row ─────────────────────────────────────────────
                Row(children: [
                  Expanded(
                      child: _SummaryCard(
                          icon: '⭐',
                          label: 'Score',
                          value: '$score',
                          color: const Color(0xFFF59E0B))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _SummaryCard(
                          icon: '✅',
                          label: 'Correct',
                          value: '$correctAnswers/$totalAnswers',
                          color: const Color(0xFF10B981))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _SummaryCard(
                          icon: '🩺',
                          label: 'In Range',
                          value: '$timeInRange h',
                          color: const Color(0xFF3B82F6))),
                ]),
                const SizedBox(height: 20),

                // ╔═══════════════════════════════════════════════════════════╗
                // ║  CALENDAR HEATMAP                                         ║
                // ╚═══════════════════════════════════════════════════════════╝
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📅 Activity Calendar — Last 28 Days',
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                          'Each cell shows accuracy % for that day. Number inside = questions answered.',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.white38)),
                      const SizedBox(height: 16),
                      _buildCalendarGrid(byDay),
                      const SizedBox(height: 14),
                      // Legend
                      Wrap(spacing: 12, runSpacing: 6, children: [
                        _CalLegend(
                            color: const Color(0xFF10B981), label: '≥ 80%'),
                        _CalLegend(
                            color: const Color(0xFF3B82F6), label: '60–79%'),
                        _CalLegend(
                            color: const Color(0xFFF59E0B), label: '40–59%'),
                        _CalLegend(
                            color: const Color(0xFFEF4444), label: '< 40%'),
                        _CalLegend(
                            color: Colors.white.withOpacity(0.1),
                            label: 'No data'),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ╔═══════════════════════════════════════════════════════════╗
                // ║  ADVANCED ANALYTICS                                        ║
                // ╚═══════════════════════════════════════════════════════════╝
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🔬 Advanced Analytics',
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 16),

                        // Streak / BG tiles
                        Row(children: [
                          Expanded(
                              child: _AnalyticTile(
                                  label: 'Current Streak',
                                  value: '$curStreak 🔥',
                                  sub: 'consecutive correct')),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _AnalyticTile(
                                  label: 'Best Streak',
                                  value: '$maxStreak ⚡',
                                  sub: 'this session')),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _AnalyticTile(
                                  label: 'Avg BG at Q',
                                  value: '${avgBg.toStringAsFixed(0)}',
                                  sub: 'mg/dL')),
                        ]),
                        const SizedBox(height: 20),

                        // Per-type bars
                        Text('Performance by Alert Type',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70)),
                        const SizedBox(height: 10),
                        if (typeTotal.isEmpty)
                          Text('No alert-based questions answered yet.',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.white38))
                        else
                          ...typeTotal.entries.map((e) {
                            final correct = typeCorrect[e.key] ?? 0;
                            final pct =
                                e.value > 0 ? correct / e.value : 0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(typeLabel(e.key),
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.white60)),
                                          Text(
                                              '$correct/${e.value}  (${(pct * 100).toStringAsFixed(0)}%)',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: typeColor(e.key),
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ]),
                                    const SizedBox(height: 5),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: pct.toDouble(),
                                        minHeight: 10,
                                        backgroundColor:
                                            Colors.white.withOpacity(0.1),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                typeColor(e.key)),
                                      ),
                                    ),
                                  ]),
                            );
                          }),
                        const SizedBox(height: 16),

                        // Q-by-Q accuracy bar chart
                        if (answerHistory.length >= 3) ...[
                          Text(
                              'Answer Accuracy Over Time  (green = correct)',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70)),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 70,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: answerHistory.take(20).map((r) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    child: Container(
                                      height: r.wasCorrect ? 55 : 18,
                                      decoration: BoxDecoration(
                                        color: r.wasCorrect
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Q1',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10, color: Colors.white38)),
                                Text(
                                    'Q${min(answerHistory.length, 20)}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10, color: Colors.white38)),
                              ]),
                        ],
                      ]),
                ),
                const SizedBox(height: 20),

                // ╔═══════════════════════════════════════════════════════════╗
                // ║  MISSED QUESTIONS REVIEW                                   ║
                // ╚═══════════════════════════════════════════════════════════╝
                if (missed.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('❌ Missed Questions — Review (${missed.length})',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEF4444))),
                        const SizedBox(height: 12),
                        ...missed.map((r) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.scenario,
                                        style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.white,
                                            height: 1.4)),
                                    const SizedBox(height: 8),
                                    Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('You chose:  ',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: const Color(
                                                      0xFFEF4444))),
                                          Expanded(
                                              child: Text(r.chosenAnswer,
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: const Color(
                                                          0xFFEF4444)))),
                                        ]),
                                    const SizedBox(height: 4),
                                    Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Best answer:  ',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: const Color(
                                                      0xFF10B981),
                                                  fontWeight:
                                                      FontWeight.w600)),
                                          Expanded(
                                              child: Text(r.correctAnswer,
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: const Color(
                                                          0xFF10B981),
                                                      fontWeight:
                                                          FontWeight.w600))),
                                        ]),
                                  ]),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ╔═══════════════════════════════════════════════════════════╗
                // ║  FULL SESSION LOG                                          ║
                // ╚═══════════════════════════════════════════════════════════╝
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📋 Full Session Log',
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 12),
                      ...answerHistory.asMap().entries.map((e) {
                        final r = e.value;
                        final idx = e.key;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: r.wasCorrect
                                ? const Color(0xFF10B981).withOpacity(0.08)
                                : const Color(0xFFEF4444).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: r.wasCorrect
                                  ? const Color(0xFF10B981).withOpacity(0.3)
                                  : const Color(0xFFEF4444).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${idx + 1}.',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white54,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(r.scenario,
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.white70,
                                                height: 1.3)),
                                        const SizedBox(height: 4),
                                        Text(
                                          r.wasCorrect
                                              ? '✅ ${r.chosenAnswer}'
                                              : '❌ ${r.chosenAnswer}',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: r.wasCorrect
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFEF4444),
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ]),
                                ),
                                Text(
                                  '${r.glucoseAtTime.toStringAsFixed(0)}\nmg/dL',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10, color: Colors.white38),
                                  textAlign: TextAlign.right,
                                ),
                              ]),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Action buttons ─────────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.home_outlined,
                          color: Colors.white70),
                      label: Text('Menu',
                          style: GoogleFonts.poppins(color: Colors.white70)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          gameOver = false;
                          loading = true;
                          score = 0;
                          correctAnswers = 0;
                          totalAnswers = 0;
                          timeInRange = 0;
                          iteration = 0;
                          answerHistory.clear();
                          selectedAnswer = "";
                        });
                        glucoseController = GlucoseSimulationController();
                        patientController = PatientController();
                        initControllers()
                            .then((_) => setState(() => loading = false));
                      },
                      icon: const Icon(Icons.replay, color: Colors.white),
                      label: Text('Play Again',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Calendar grid helper ──────────────────────────────────────────────────
  Widget _buildCalendarGrid(Map<String, List<AnswerRecord>> byDay) {
    final today = DateTime.now();
    final days =
        List.generate(28, (i) => today.subtract(Duration(days: 27 - i)));
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: dayLabels
            .map((d) => SizedBox(
                  width: 36,
                  child: Center(
                    child: Text(d,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.white38)),
                  ),
                ))
            .toList(),
      ),
      const SizedBox(height: 6),
      ...List.generate(4, (week) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (d) {
              final idx = week * 7 + d;
              if (idx >= days.length)
                return const SizedBox(width: 36, height: 36);
              final day = days[idx];
              final k =
                  '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
              final records = byDay[k];
              Color cellColor;
              String tip = '${day.month}/${day.day}';
              if (records == null || records.isEmpty) {
                cellColor = Colors.white.withOpacity(0.08);
              } else {
                final acc =
                    records.where((r) => r.wasCorrect).length /
                        records.length *
                        100;
                tip = '${day.month}/${day.day}: ${acc.toStringAsFixed(0)}% (${records.length} Qs)';
                if (acc >= 80)       cellColor = const Color(0xFF10B981);
                else if (acc >= 60)  cellColor = const Color(0xFF3B82F6);
                else if (acc >= 40)  cellColor = const Color(0xFFF59E0B);
                else                 cellColor = const Color(0xFFEF4444);
              }
              bool isToday = day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;

              return Tooltip(
                message: tip,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: records != null && records.isNotEmpty
                      ? Center(
                          child: Text('${records.length}',
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        )
                      : null,
                ),
              );
            }),
          ),
        );
      }),
    ]);
  }

  // ─── Main build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E293B),
                Color(0xFF0F172A)
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF10B981)),
          ),
        ),
      );
    }

    if (gameOver) return _buildResultsScreen();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Stack(children: [
            Column(children: [
              _buildHeader(),
              _buildStatsBar(),
              _buildCurrentGlucoseDisplay(),
              Expanded(child: _buildGlucoseChart()),
            ]),
            if (warnings.isNotEmpty) _buildWarningModal(warnings.first),
            if (showFeedback)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildFeedbackOverlay(),
              ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String icon, label, value;
  const _StatItem({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.white60)),
      ]);
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color.withOpacity(0.5),
              borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.white60)),
      ]);
}

class _SummaryCard extends StatelessWidget {
  final String icon, label, value;
  final Color color;
  const _SummaryCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(label,
              style:
                  GoogleFonts.poppins(fontSize: 10, color: Colors.white54)),
        ]),
      );
}

class _AnalyticTile extends StatelessWidget {
  final String label, value, sub;
  const _AnalyticTile(
      {required this.label, required this.value, required this.sub});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(sub,
              style: GoogleFonts.poppins(
                  fontSize: 9, color: Colors.white38)),
        ]),
      );
}

class _CalLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _CalLegend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Text(label,
              style:
                  GoogleFonts.poppins(fontSize: 10, color: Colors.white54)),
        ],
      );
}
