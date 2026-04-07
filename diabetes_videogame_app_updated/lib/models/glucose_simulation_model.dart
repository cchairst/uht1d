import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:uh_t1d_tutor/controllers/patient_controller.dart';
import 'package:uh_t1d_tutor/models/glucose_warning_model.dart';

import '../services/answers_for_warnings_service.dart';

class GlucoseSimulationModel {
  List<FlSpot> glucosePredictions = [];
  List<GlucoseWarning> warnings = [];

  List<WarningQuestion> _lowQuestions = [];
  List<WarningQuestion> _highQuestions = [];
  List<WarningQuestion> _veryHighQuestions = [];

  final Random _rng = Random();

  Future<void> init(PatientController patientController) async {
    glucosePredictions = [];
    warnings = [];
    final svc = AnswersForWarnings();
    _lowQuestions = await svc.loadQuestions("low");
    _highQuestions = await svc.loadQuestions("high");
    _veryHighQuestions = await svc.loadQuestions("veryHigh");
    await generatePredictions();
    evaluateWarnings(patientController);
  }

  WarningQuestion _pick(List<WarningQuestion> pool) {
    if (pool.isEmpty) throw Exception("Empty question pool");
    return pool[_rng.nextInt(pool.length)];
  }

  bool hasPredictions() {
    return glucosePredictions.isNotEmpty;
  }

  // X axis is based on the minutes from current time until the predicted value.
  Future<void> generatePredictions() async {
    glucosePredictions.add(FlSpot(0, 130.0));
    glucosePredictions.add(FlSpot(60, 100.0));
    glucosePredictions.add(FlSpot(120, 100.0));
    glucosePredictions.add(FlSpot(180, 120.0));
    glucosePredictions.add(FlSpot(240, 190.1));
    glucosePredictions.add(FlSpot(300, 125.1));
  }

  void removeFistPrediction() {
    glucosePredictions.removeAt(0);
  }

  void applySelectedAnswerData(int affectGlucose, int affectInTime) {
    for (int x = 0; x < glucosePredictions.length; x++) {
      if (glucosePredictions[x].x.toInt() == affectInTime) {
        glucosePredictions[x] = FlSpot(
          glucosePredictions[x].x,
          glucosePredictions[x].y + affectGlucose.toDouble(),
        );
      }
    }
  }

  void shiftPredictionsLeft() {
    glucosePredictions =
        glucosePredictions.map((item) => FlSpot(item.x - 60, item.y)).toList();
  }

  void shiftWarningsLeft() {
    for (var warning in warnings) {
      warning.time = warning.time - 60;
    }
  }

  void generateNewPrediction() {
    num lastPredictedMinute =
        glucosePredictions.isNotEmpty ? glucosePredictions.last.x : -60;

    double max = 200.0;
    double min = 100.0;
    double randomValue = _rng.nextDouble() * (max - min) + min;
    glucosePredictions.add(FlSpot(lastPredictedMinute + 60, randomValue));
  }

  void removeWarningIfIsFromFirstPrediction() {
    if (warnings.isNotEmpty && glucosePredictions.isNotEmpty) {
      if (warnings.first.time == glucosePredictions.first.x) {
        warnings.removeAt(0);
      }
    }
  }

  void removeFirstWarning() {
    if (warnings.isNotEmpty) warnings.removeAt(0);
  }

  void evaluateWarnings(PatientController patientController) {
    warnings.clear();

    for (FlSpot prediction in glucosePredictions) {
      if (prediction.y < patientController.patient.lowThreshold) {
        final q = _pick(_lowQuestions);
        warnings.add(GlucoseWarning(
          type: WarningType.low,
          title: "Low Glucose Alert",
          scenario: q.scenario,
          options: q.options,
          correctOption: q.correctOption,
          time: prediction.x,
        ));
      } else if (prediction.y >= patientController.patient.highThreshold) {
        final q = _pick(_veryHighQuestions);
        warnings.add(GlucoseWarning(
          type: WarningType.veryHigh,
          title: "Very High Glucose Alert",
          scenario: q.scenario,
          options: q.options,
          correctOption: q.correctOption,
          time: prediction.x,
        ));
      } else if (prediction.y >= patientController.patient.normalThreshold) {
        final q = _pick(_highQuestions);
        warnings.add(GlucoseWarning(
          type: WarningType.high,
          title: "High Glucose Alert",
          scenario: q.scenario,
          options: q.options,
          correctOption: q.correctOption,
          time: prediction.x,
        ));
      }
    }
  }
}
