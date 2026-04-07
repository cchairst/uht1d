import 'package:flutter/material.dart';
import 'package:uh_t1d_tutor/models/answers_model.dart';

class Question {
  final String question;
  final List<Answer> options;
  final String answer;
  final TimeOfDay time;

  Question({
    required this.question,
    required this.options,
    required this.answer,
    required this.time,
  });

  factory Question.fromMap(Map<dynamic, dynamic> map) {
    final timeParts = (map['time'] as String).split(':');
    return Question(
      question: map['question'].toString(),
      options: (map['options'] as List).map((e) => Answer.fromMap(e)).toList(),
      answer: map['answer'].toString(),
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
    );
  }
}
