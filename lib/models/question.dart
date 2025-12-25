class Question {
  final String id;
  final String type;
  final String question;
  final Map<String, String> options;
  final String correctAnswer;
  final String analysis;
  final String sourceFile;

  Question({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.analysis,
    required this.sourceFile,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      type: json['type'],
      question: json['question'],
      options: Map<String, String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
      analysis: json['analysis'],
      sourceFile: json['sourceFile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'analysis': analysis,
      'sourceFile': sourceFile,
    };
  }

  bool isCorrect(String userAnswer) {
    if (type == '多选题') {
      return _normalizeAnswer(userAnswer) == _normalizeAnswer(correctAnswer);
    } else {
      return userAnswer.toUpperCase() == correctAnswer.toUpperCase();
    }
  }

  String _normalizeAnswer(String answer) {
    List<String> chars = answer.toUpperCase().split('');
    chars.sort();
    return chars.join('');
  }
}
