import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/exam_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final examService = Provider.of<ExamService>(context);
    
    int practicedQuestions = 0;
    int totalAnswers = 0;
    int correctAnswers = 0;
    int wrongAnswers = 0;
    int wrongQuestionCount = 0;

    if (examService.userProgress.isNotEmpty) {
      practicedQuestions = examService.userProgress.values
          .where((data) => data.totalCount > 0)
          .length;
      
      totalAnswers = examService.userProgress.values
          .map((data) => data.totalCount)
          .fold(0, (a, b) => a + b);
      
      correctAnswers = examService.userProgress.values
          .map((data) => data.correctCount)
          .fold(0, (a, b) => a + b);
      
      wrongAnswers = examService.userProgress.values
          .map((data) => data.wrongCount)
          .fold(0, (a, b) => a + b);
      
      wrongQuestionCount = examService.userProgress.values
          .where((data) => data.isWrong)
          .length;
    }

    final totalQuestions = examService.questions.length;
    final accuracy = totalAnswers > 0 ? (correctAnswers / totalAnswers * 100).toStringAsFixed(1) : '0.0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('学习进度'),
        backgroundColor: Colors.orange.shade400, // 温暖的橙色
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 学习进度统计',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.orange.shade50, // 温暖的背景色
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressItem('题库总量', '$totalQuestions 道'),
                    _buildProgressItem('已练习题', '$practicedQuestions 道'),
                    _buildProgressItem('未练习题', '${totalQuestions - practicedQuestions} 道'),
                    const Divider(height: 20),
                    _buildProgressItem('总答题次数', '$totalAnswers 次'),
                    _buildProgressItem('答对次数', '$correctAnswers 次'),
                    _buildProgressItem('答错次数', '$wrongAnswers 次'),
                    const Divider(height: 20),
                    _buildProgressItem('总体正确率', '$accuracy%'),
                    const SizedBox(height: 10),
                    _buildProgressItem('当前错题数', '$wrongQuestionCount 道'),
                  ],
                ),
              ),
            ),
            if (wrongQuestionCount > 0) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '建议重点复习错题，提高学习效果！',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w500,
              color: Colors.orange.shade700, // 温暖的橙色
            ),
          ),
        ],
      ),
    );
  }
}