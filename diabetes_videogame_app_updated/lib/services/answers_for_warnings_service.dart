import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import '../models/answer_model.dart';

class WarningQuestion {
  final String scenario;
  final List<Answer> options;
  final String correctOption;

  WarningQuestion({
    required this.scenario,
    required this.options,
    required this.correctOption,
  });
}

class AnswersForWarnings {
  /// Returns all questions for a given warningType.
  Future<List<WarningQuestion>> loadQuestions(String filter) async {
    final yamlString = await rootBundle.loadString('assets/answers.yaml');
    final data = loadYaml(yamlString) as YamlMap;
    final warnings = data["warnings"] as YamlList;

    List<WarningQuestion> questions = [];
    for (var warning in warnings) {
      if (warning["warningType"] == filter) {
        final options = warning["options"] as YamlList;
        final answers = options.map((option) => Answer(
          text: option["text"] as String,
          affectGlucose: option["affectGlucose"] as int,
          affectInTime: option["affectInTime"] as int,
        )).toList();

        questions.add(WarningQuestion(
          scenario: warning["scenario"] as String? ?? "What action should you take?",
          options: answers,
          correctOption: warning["correctOption"] as String,
        ));
      }
    }
    return questions;
  }

  /// Returns one random question for a given warningType.
  Future<WarningQuestion> loadRandomQuestion(String filter) async {
    final questions = await loadQuestions(filter);
    if (questions.isEmpty) {
      throw Exception("No questions found for warningType: $filter");
    }
    return questions[Random().nextInt(questions.length)];
  }

  /// Legacy method — returns answers from a random question for the given type.
  Future<List<Answer>> loadAnswers(String filter) async {
    final q = await loadRandomQuestion(filter);
    return q.options;
  }
}
