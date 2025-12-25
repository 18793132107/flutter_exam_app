import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../services/exam_service.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({Key? key}) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _currentQuestionIndex = 0;
  List<String> _selectedOptions = [];
  List<Question> _wrongQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadWrongQuestions();
  }

  void _loadWrongQuestions() {
    final examService = Provider.of<ExamService>(context, listen: false);
    setState(() {
      _wrongQuestions = examService.getWrongQuestions();
    });
  }

  void _selectOption(String option) {
    final question = _wrongQuestions[_currentQuestionIndex];
    
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

  void _checkAnswer() {
    if (_selectedOptions.isEmpty) {
      _showMessage('请先选择一个答案');
      return;
    }

    final question = _wrongQuestions[_currentQuestionIndex];
    final userAnswer = _selectedOptions.join('');
    final isCorrect = question.isCorrect(userAnswer);

    // 显示答题结果
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
                child: Text('继续下一题 (${delaySeconds}s)'),
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

  Future<int> _getSetting(String key, int defaultValue) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? defaultValue;
  }

  String _formatAnswer(String answer, String type) {
    if (type == '多选题') {
      return answer.split('').join('、');
    }
    return answer;
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _wrongQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptions = [];
      });
    } else {
      _showCompleteMessage();
    }
  }

  void _showCompleteMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('错题复习完成！'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_wrongQuestions.isNotEmpty)
                Text('本次共复习了 ${_wrongQuestions.length} 道错题')
              else
                const Text('暂无错题需要复习'),
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
    if (_wrongQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('错题复习'),
          backgroundColor: Colors.orange.shade400, // 温暖的橙色
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '目前没有错题需要复习\n请先进行练习以生成错题记录',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }

    final question = _wrongQuestions[_currentQuestionIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('错题复习'),
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
            Text(
              '${question.type}\n\n${question.question}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              '错题复习 第${_currentQuestionIndex + 1}题/共${_wrongQuestions.length}题',
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
            if (question.analysis.isNotEmpty) ...[
              const SizedBox(height: 10),
              Card(
                color: Colors.orange.shade50, // 温暖的背景色
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '解析:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange, // 温暖的橙色
                        ),
                      ),
                      Text(question.analysis),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _checkAnswer,
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