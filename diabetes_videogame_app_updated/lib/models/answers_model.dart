class Answer {
  final String text;
  final int glucoseDelta;
  final int effectAfter;

  Answer({
    required this.text,
    required this.glucoseDelta,
    required this.effectAfter,
  });

  factory Answer.fromMap(Map<dynamic, dynamic> map) {
    return Answer(
      text: map['text'].toString(),
      glucoseDelta: map['glucose_delta'] ?? 0,
      effectAfter: map['effect_after'] ?? 0,
    );
  }
}
