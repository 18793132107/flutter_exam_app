import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../services/exam_service.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({Key? key}) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int _currentQuestionIndex = 0;
  String? _selectedOption;
  List<String> _selectedMultiOptions = [];
  int _correctCount = 0;
  List<Question> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final examService = Provider.of<ExamService>(context, listen: false);
    await examService.loadQuestions();
    
    // 从设置中获取练习题目数量
    final questionCount = await _getSetting('question_count', 50);
    
    // 限制题目数量
    setState(() {
      _questions = examService.questions.length > questionCount
          ? examService.questions.take(questionCount).toList()
          : examService.questions;
      _isLoading = false;
    });
  }

  Future<int> _getSetting(String key, int defaultValue) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? defaultValue;
  }

  void _selectOption(String option) {
    final question = _questions[_currentQuestionIndex];
    
    if (question.type == '多选题') {
      setState(() {
        if (_selectedMultiOptions.contains(option)) {
          _selectedMultiOptions.remove(option);
        } else {
          _selectedMultiOptions.add(option);
        }
        _selectedOption = null; // 清除单选题的选项
      });
    } else {
      setState(() {
        _selectedOption = option;
        _selectedMultiOptions.clear(); // 清除多选题的选项
      });
    }
  }

  void _submitAnswer() {
    final question = _questions[_currentQuestionIndex];
    String userAnswer;
    
    if (question.type == '多选题') {
      userAnswer = _selectedMultiOptions.join('');
    } else {
      userAnswer = _selectedOption ?? '';
    }
    
    if (userAnswer.isEmpty) {
      _showMessage('请先选择一个答案');
      return;
    }

    final isCorrect = question.isCorrect(userAnswer);

    if (isCorrect) {
      setState(() {
        _correctCount++;
      });
    }

    // 记录答题情况
    final examService = Provider.of<ExamService>(context, listen: false);
    examService.recordAnswer(question, userAnswer, isCorrect);

    // 显示结果
    _showAnswerResult(isCorrect, userAnswer, question);
  }

  void _showAnswerResult(bool isCorrect, String userAnswer, Question question) {
    // 获取自动跳转延迟设置
    _getSetting('auto_next_delay', 3).then((delaySeconds) {
      // 显示对话框
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(isCorrect ? '✅ 回答正确！' : '❌ 回答错误'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('正确答案: ${_formatAnswer(question.correctAnswer, question.type)}'),
                const SizedBox(height: 10),
                Text('你的答案: ${_formatAnswer(userAnswer, question.type)}'),
                if (question.analysis.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('解析: ${question.analysis}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _nextQuestion();
                },
                child: Text('下一题 (${delaySeconds}s)'),
              ),
            ],
          );
        },
      ).then((_) {
        // 如果用户没有手动点击下一题，自动跳转
        Future.delayed(Duration(seconds: delaySeconds), () {
          if (mounted) {
            _nextQuestion();
          }
        });
      });
    });
  }

  String _formatAnswer(String answer, String type) {
    if (type == '多选题') {
      return answer.split('').join('、');
    }
    return answer;
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
        _selectedMultiOptions.clear();
      });
    } else {
      _showFinalResult();
    }
  }

  void _showFinalResult() {
    final accuracy = _questions.isNotEmpty 
        ? (_correctCount / _questions.length * 100).toStringAsFixed(1) 
        : '0.0';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('练习完成！'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('总题数: ${_questions.length} 道'),
              Text('答对题数: $_correctCount 道'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('练习模式'),
          backgroundColor: Colors.orange.shade400, // 温暖的橙色
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentQuestionIndex >= _questions.length) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('练习模式'),
          backgroundColor: Colors.orange.shade400, // 温暖的橙色
        ),
        body: const Center(child: Text('没有更多题目了')),
      );
    }

    final question = _questions[_currentQuestionIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('练习模式'),
        backgroundColor: Colors.orange.shade400, // 温暖的橙色
        foregroundColor: Colors.white,
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
              '第${_currentQuestionIndex + 1}题/共${_questions.length}题',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: question.options.entries.map((entry) {
                  final isMultiSelect = question.type == '多选题';
                  final isSelected = isMultiSelect 
                      ? _selectedMultiOptions.contains(entry.key)
                      : _selectedOption == entry.key;
                  
                  return Card(
                    child: isMultiSelect
                        ? CheckboxListTile(
                            title: Text('${entry.key}. ${entry.value}'),
                            value: isSelected,
                            onChanged: (bool? value) {
                              _selectOption(entry.key);
                            },
                            tileColor: isSelected ? Colors.orange.shade100 : null, // 温暖的橙色选择状态
                          )
                        : RadioListTile<String>(
                            title: Text('${entry.key}. ${entry.value}'),
                            value: entry.key,
                            groupValue: _selectedOption,
                            onChanged: (String? value) {
                              if (value != null) {
                                _selectOption(value);
                              }
                            },
                            tileColor: isSelected ? Colors.orange.shade100 : null, // 温暖的橙色选择状态
                            controlAffinity: ListTileControlAffinity.platform,
                          ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade400, // 按钮背景色
                  foregroundColor: Colors.white, // 按钮文字色
                ),
                child: const Text('提交答案', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}