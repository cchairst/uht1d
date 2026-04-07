import 'package:fl_chart/fl_chart.dart';
import 'package:uh_t1d_tutor/controllers/patient_controller.dart';
import 'package:uh_t1d_tutor/models/glucose_simulation_model.dart';
import 'package:uh_t1d_tutor/models/glucose_warning_model.dart';

class GlucoseSimulationController {
  final GlucoseSimulationModel _model = GlucoseSimulationModel();

  Future<void> init(PatientController patientController) async {
    await _model.init(patientController);
  }

  bool hasPredictions() {
    return _model.hasPredictions();
  }

  void nextIterationOfPredictions(
    PatientController patientController,
    int affectGlucose,
    int affectInTime,
  ) {
    _model.removeFistPrediction();
    _model.applySelectedAnswerData(affectGlucose, affectInTime);
    _model.shiftPredictionsLeft();
    _model.generateNewPrediction();
    _model.evaluateWarnings(patientController);
    //_model.generatePredictions();
  }

  bool doesPredictionHaveWarnings() {
    return _model.warnings.isNotEmpty;
  }

  GlucoseWarning getFirstWarning() {
    if (_model.warnings.isNotEmpty) return _model.warnings.first;
    throw "Requesting a Glucose Warning when there are not";
  }

  List<GlucoseWarning> getWarningsList() {
    return _model.warnings;
  }

  List<FlSpot> getPredictionsList() {
    return _model.glucosePredictions;
  }
}
