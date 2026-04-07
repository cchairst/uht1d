import 'package:uh_t1d_tutor/models/patient_model.dart';

class PatientController {
  late PatientModel _model;

  Future<void> init ({
    String name = '-',
    int age = 0,
    int baseGlucose = 100,
    int lowThreshold = 70,
    int normalThreshold = 180,
    int highThreshold = 250,
  }) async {
    _model = PatientModel(
      name: name,
      age: age,
      baseGlucose: baseGlucose,
      lowThreshold: lowThreshold,
      normalThreshold: normalThreshold,
      highThreshold: highThreshold,
    );
  }

  PatientModel get patient => _model;
}
