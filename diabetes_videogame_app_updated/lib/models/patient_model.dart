class PatientModel {
  final String name;
  final int age;
  final int baseGlucose;

  final int lowThreshold;
  final int normalThreshold;
  final int highThreshold;

  PatientModel({
    required this.name,
    required this.age,
    required this.baseGlucose,
    required this.lowThreshold,
    required this.normalThreshold,
    required this.highThreshold,
  });
}
