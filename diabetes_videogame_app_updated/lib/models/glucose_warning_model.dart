import 'answer_model.dart';

enum WarningType { low, high, veryHigh }

class GlucoseWarning {
  WarningType type;
  String title;
  String scenario;
  List<Answer> options;
  String correctOption;
  double time;

  GlucoseWarning({
    required this.type,
    required this.title,
    required this.scenario,
    required this.options,
    required this.correctOption,
    required this.time,
  });

  String toString() {
    return "[time:${time}]";
  }
}
