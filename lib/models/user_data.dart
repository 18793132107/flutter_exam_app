class UserData {
  final int totalCount;
  final int correctCount;
  final int wrongCount;
  final String lastAnswer;
  final bool isWrong;

  UserData({
    this.totalCount = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.lastAnswer = '',
    this.isWrong = false,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      totalCount: json['total_count'] ?? 0,
      correctCount: json['correct_count'] ?? 0,
      wrongCount: json['wrong_count'] ?? 0,
      lastAnswer: json['last_answer'] ?? '',
      isWrong: json['is_wrong'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_count': totalCount,
      'correct_count': correctCount,
      'wrong_count': wrongCount,
      'last_answer': lastAnswer,
      'is_wrong': isWrong,
    };
  }
}
