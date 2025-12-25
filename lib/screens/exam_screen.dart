import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../services/exam_service.dart';
import 'dart:async';

/// 模拟考试屏幕
/// 
/// 提供完整的考试功能，包括计时、题目导航、答案保存和成绩计算
class ExamScreen extends StatefulWidget {
  const ExamScreen({Key? key}) : super(key: key);

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  int _currentQuestionIndex = 0;
  List<String> _selectedOptions = [];
  List<Question> _examQuestions = [];
  Map<String, String> _examAnswers = {};
  DateTime? _examStartTime;
  final int _examDuration = 3600; // 60分钟考试时间
  Timer? _timer;
  int _remainingTime = 0;
  bool _isLoading = true;

  Future<int> _getSetting(String key, int defaultValue) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? defaultValue;
  }

  @override
  void initState() {
    super.initState();
    _startExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startExam() async {
    final examService = Provider.of<ExamService>(context, listen: false);
    await examService.loadQuestions();
    
    // 按题型分类
    final allQuestions = examService.questions;
    final singleQuestions = allQuestions.where((q) => q.type == '单选题').toList();
    final multiQuestions = allQuestions.where((q) => q.type == '多选题').toList();
    final judgmentQuestions = allQuestions.where((q) => q.type == '判断题').toList();

    // 检查题目数量
    if (singleQuestions.length < 20 || multiQuestions.length < 20 || judgmentQuestions.length < 10) {
      if (mounted) {
        _showMessage('题库题目数量不足，无法开始考试');
      }
      return;
    }

    // 从设置中获取考试题目数量
    final examSingleCount = await _getSetting('exam_single_count', 20);
    final examMultiCount = await _getSetting('exam_multi_count', 20);
    final examJudgmentCount = await _getSetting('exam_judgment_count', 10);
    
    // 随机选择题目
    final examSingle = _randomSample(singleQuestions, examSingleCount);
    final examMulti = _randomSample(multiQuestions, examMultiCount);
    final examJudgment = _randomSample(judgmentQuestions, examJudgmentCount);

    _examQuestions = [...examSingle, ...examMulti, ...examJudgment];
    _examQuestions.shuffle(); // 随机打乱顺序

    _currentQuestionIndex = 0;
    _examAnswers = {};
    _examStartTime = DateTime.now();
    _remainingTime = _examDuration;

    // 开始计时
    _startTimer();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Question> _randomSample(List<Question> list, int count) {
    if (list.length <= count) return list;
    
    final shuffled = List<Question>.from(list)..shuffle();
    return shuffled.take(count).toList();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingTime = _remainingTime > 0 ? _remainingTime - 1 : 0;
        });
        
        if (_remainingTime <= 0) {
          _submitExam();
        }
      }
    });
  }

  void _selectOption(String option) {
    final question = _examQuestions[_currentQuestionIndex];

    if (question.type == '多选题') {
      setState(() {
        if (_selectedOptions.contains(option)) {
          _selectedOptions.remove(option);
        } else {
          _selectedOptions.add(option);
        }
      });
    } else {
      setState(() {
        _selectedOptions = [option];
      });
    }
  }

  void _saveAnswer() {
    if (_selectedOptions.isNotEmpty) {
      final question = _examQuestions[_currentQuestionIndex];
      final userAnswer = _selectedOptions.join('');
      setState(() {
        _examAnswers[question.id] = userAnswer;
      });
    }
  }

  void _submitAnswer() {
    if (_selectedOptions.isEmpty) {
      _showMessage('请先选择一个答案');
      return;
    }

    _saveAnswer();
    _submitExam();
  }

  void _prevQuestion() {
    if (_currentQuestionIndex > 0) {
      _saveAnswer();
      setState(() {
        _currentQuestionIndex--;
        _selectedOptions = _examAnswers[_examQuestions[_currentQuestionIndex].id]?.split('') ?? [];
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _examQuestions.length - 1) {
      _saveAnswer();
      setState(() {
        _currentQuestionIndex++;
        _selectedOptions = _examAnswers[_examQuestions[_currentQuestionIndex].id]?.split('') ?? [];
      });
    }
  }

  void _submitExam() {
    _saveAnswer();
    _timer?.cancel();

    // 计算成绩
    double totalScore = 0;
    int correctCount = 0;

    for (final question in _examQuestions) {
      if (_examAnswers.containsKey(question.id)) {
        final userAnswer = _examAnswers[question.id]!;
        final isCorrect = question.isCorrect(userAnswer);

        if (isCorrect) {
          correctCount++;
          if (question.type == '单选题') {
            totalScore += 1;
          } else if (question.type == '多选题') {
            totalScore += 2;
          } else if (question.type == '判断题') {
            totalScore += 0.5;
          }
        }

        // 记录答题情况
        final examService = Provider.of<ExamService>(context, listen: false);
        examService.recordAnswer(question, userAnswer, isCorrect);
      }
    }

    _showExamResult(totalScore, correctCount);
  }

  void _showExamResult(double totalScore, int correctCount) {
    final accuracy = _examQuestions.isNotEmpty 
        ? (correctCount / _examQuestions.length * 100).toStringAsFixed(1) 
        : '0.0';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('考试完成！'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('考试成绩: $totalScore 分'),
              const SizedBox(height: 10),
              Text('单选题: 20题 × 1分 = 20分'),
              Text('多选题: 20题 × 2分 = 40分'),
              Text('判断题: 10题 × 0.5分 = 5分'),
              Text('满分: 65分'),
              const SizedBox(height: 10),
              Text('答对题数: $correctCount/${_examQuestions.length}'),
              Text('正确率: $accuracy%'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // 返回主菜单
              },
              child: const Text('返回主菜单'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _examQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('模拟考试'),
          backgroundColor: Colors.orange.shade400, // 温暖的橙色
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final question = _examQuestions[_currentQuestionIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('模拟考试'),
        backgroundColor: Colors.orange.shade400, // 温暖的橙色
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '剩余时间: ${_formatTime(_remainingTime)}',
              style: const TextStyle(fontSize: 16, color: Colors.white), // 白色文字
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${question.type}\n\n${question.question}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              '第${_currentQuestionIndex + 1}题/共${_examQuestions.length}题',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: question.options.entries.map((entry) {
                  final isSelected = _selectedOptions.contains(entry.key);
                  
                  return Card(
                    child: RadioListTile<String>(
                      title: Text('${entry.key}. ${entry.value}'),
                      value: entry.key,
                      groupValues: question.type != '多选题' 
                          ? _selectedOptions.isNotEmpty 
                              ? _selectedOptions.first 
                              : null
                          : null, // 多选题不使用单选按钮
                      onChanged: question.type != '多选题'
                          ? (value) {
                              _selectOption(entry.key);
                            }
                          : null,
                      selected: isSelected,
                      tileColor: isSelected ? Colors.orange.shade100 : null, // 温暖的橙色选择状态
                      controlAffinity: ListTileControlAffinity.platform,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentQuestionIndex > 0 ? _prevQuestion : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade300, // 按钮背景色
                      foregroundColor: Colors.white, // 按钮文字色
                    ),
                    child: const Text('上一题'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700, // 提交按钮背景色
                      foregroundColor: Colors.white, // 按钮文字色
                    ),
                    child: const Text('提交考试'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentQuestionIndex < _examQuestions.length - 1 ? _nextQuestion : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade300, // 按钮背景色
                      foregroundColor: Colors.white, // 按钮文字色
                    ),
                    child: const Text('下一题'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}