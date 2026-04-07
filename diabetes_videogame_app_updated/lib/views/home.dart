import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uh_t1d_tutor/controllers/glucose_simulation_controller.dart';
import 'package:uh_t1d_tutor/controllers/patient_controller.dart';
import 'package:uh_t1d_tutor/models/answer_model.dart';

import '../models/glucose_warning_model.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool loading = true;
  GlucoseSimulationController glucoseController = GlucoseSimulationController();
  PatientController patientController = PatientController();

  // Variables for controlling the selected answer.
  String selectedAnswer = "";
  int selectedAnswerGlucoseEffect = 0;
  int selectedAnswerEffectTime = 0;
  List<GlucoseWarning> warnings = [];
  List<FlSpot> glucosePredictions = [];

  @override
  void initState() {
    super.initState();
    initControllers().then((_) => setState(() => loading = false));
  }

  Future<void> initControllers() async {
    await patientController.init();
    await glucoseController.init(patientController);
    setState(() {
      glucosePredictions = glucoseController.getPredictionsList();
      warnings = glucoseController.getWarningsList();
    });
  }

  void nextIterationHandler({int affectGlucose = 0, int affectInTime = 0}) {
    glucoseController.nextIterationOfPredictions(
      patientController,
      affectGlucose,
      affectInTime,
    );

    setState(() {
      warnings = glucoseController.getWarningsList();
      glucosePredictions = glucoseController.getPredictionsList();
    });
  }

  void answerSelectionHandler(Answer newSelectedAnswer, String correctAnswer) {
    // Selecting a new answer.
    if (newSelectedAnswer.text != selectedAnswer) {
      setState(() {
        selectedAnswer = newSelectedAnswer.text;
        selectedAnswerGlucoseEffect = newSelectedAnswer.affectGlucose;
        selectedAnswerEffectTime = newSelectedAnswer.affectInTime;
      });
    } else {
      // Reset the selected answer.
      setState(() {
        selectedAnswer = "";
        selectedAnswerGlucoseEffect = 0;
        selectedAnswerEffectTime = 0;
      });

      nextIterationHandler(
        affectGlucose: newSelectedAnswer.affectGlucose,
        affectInTime: newSelectedAnswer.affectInTime,
      );
    }
  }

  List<Widget> createGlucosePredictionGraph({
    required bool isForQuestionModal,
  }) {
    // In order to change the prediction when the user selects a question a new list is created to add the effects of each answer.
    List<FlSpot> glucosePredictionsForGraph = [...glucosePredictions];

    if (isForQuestionModal) {
      for (int x = 0; x < glucosePredictionsForGraph.length; x++) {
        if (glucosePredictionsForGraph[x].x ==
            selectedAnswerEffectTime.toDouble()) {
          glucosePredictionsForGraph[x] = FlSpot(
            glucosePredictionsForGraph[x].x,
            glucosePredictionsForGraph[x].y + selectedAnswerGlucoseEffect,
          );
        }
      }
    }

    return [
      Text(
        'Estimated Glucose Impact',
        style: GoogleFonts.poppins(
          fontSize: isForQuestionModal ? 16 : 40,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      SizedBox(height: isForQuestionModal ? 10 : 30),
      SizedBox(
        height: isForQuestionModal ? 200 : 400,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 300,
            titlesData: FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 60,
                  getTitlesWidget: (value, _) {
                    final hour = (value / 60).round();
                    return Text(
                      'T+$hour h',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: glucosePredictionsForGraph,
                isCurved: true,
                color: Colors.white,
                barWidth: 6,
                dotData: FlDotData(show: false),
              ),
            ],
            rangeAnnotations: RangeAnnotations(
              horizontalRangeAnnotations: [
                HorizontalRangeAnnotation(
                  y1: 0,
                  y2: patientController.patient.lowThreshold.toDouble(),
                  color: const Color.fromRGBO(255, 0, 0, 0.6), // Red
                ),
                HorizontalRangeAnnotation(
                  y1: patientController.patient.lowThreshold.toDouble(),
                  y2: patientController.patient.normalThreshold.toDouble(),
                  color: const Color.fromRGBO(0, 255, 0, 0.6), // Green
                ),
                HorizontalRangeAnnotation(
                  y1: patientController.patient.normalThreshold.toDouble(),
                  y2: patientController.patient.highThreshold.toDouble(),
                  color: const Color.fromRGBO(255, 255, 0, 0.6), // Yellow
                ),
                HorizontalRangeAnnotation(
                  y1: patientController.patient.highThreshold.toDouble(),
                  y2: 300,
                  color: const Color.fromRGBO(255, 0, 0, 0.6), // Red
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget createQuestionModal(GlucoseWarning warning) {
    return Center(
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.8,
        height: MediaQuery.sizeOf(context).height * 0.6,
        margin: const EdgeInsets.all(30.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title.
            Text(warning.title, style: TextStyle(fontSize: 35)),
            SizedBox(height: 10),
            // Scenario question.
            Text(
              warning.scenario,
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            // Answers list.
            ListView(
              shrinkWrap: true,
              children:
                  warning.options.map((option) {
                    return Container(
                      margin: const EdgeInsets.all(5.0), // External margin
                      child: ElevatedButton(
                        onPressed:
                            () => answerSelectionHandler(
                              option,
                              warning.correctOption,
                            ),
                        style: ElevatedButton.styleFrom(
                          // give it a fixed background (or whatever you like)
                          backgroundColor:
                              option.text == selectedAnswer
                                  ? Colors.blue.shade50
                                  : Colors.white,

                          // conditionally change the border color
                          side: BorderSide(
                            color:
                                option.text == selectedAnswer
                                    ? Colors.blue
                                    : Colors.blue.shade200,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            option.text,
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            // Glucose graph.
            ...createGlucosePredictionGraph(isForQuestionModal: true),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    Widget mainContent = Padding(
      padding: const EdgeInsets.all(30.0),
      child: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Vertically center the column.
          crossAxisAlignment:
              CrossAxisAlignment.center, // Horizontally center children.
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glucosePredictions.isNotEmpty) ...[
              const SizedBox(height: 30),
              ...createGlucosePredictionGraph(isForQuestionModal: false),
              SizedBox(height: 30),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: nextIterationHandler,
                    child: Text("Next iteration"),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            mainContent,
            if (warnings.isNotEmpty) createQuestionModal(warnings.first),
          ],
        ),
      ),
    );
  }
}
