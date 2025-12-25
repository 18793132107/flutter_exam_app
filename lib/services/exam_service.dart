import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/question.dart';
import '../models/user_data.dart';
import '../utils/database_helper.dart';
import '../utils/excel_to_sqlite_converter.dart';

class ExamService with ChangeNotifier {
  List<Question> questions = [];
  Map<String, UserData> userProgress = {};

  Future<void> loadQuestions() async {
    try {
      // 尝试从SQLite数据库加载试题（最高优先级）
      final questionsFromDB = await _loadQuestionsFromDatabase();
      
      if (questionsFromDB.isNotEmpty) {
        questions = questionsFromDB;
      } else {
        // 尝试从应用资源加载试题
        final questionsFromAssets = await _loadQuestionsFromAssets();
        
        if (questionsFromAssets.isNotEmpty) {
          questions = questionsFromAssets;
          // 将资源中的题目导入到数据库，以便后续快速访问
          await _importQuestionsToDatabase(questionsFromAssets);
        } else {
          // 如果从资源加载失败，尝试从外部文件加载
          final directory = await getApplicationDocumentsDirectory();
          final questionBankPath = Directory('${directory.path}/题库');
          
          if (await questionBankPath.exists()) {
            // 获取所有Excel文件
            final excelFiles = await questionBankPath
                .list()
                .where((file) => file.path.toLowerCase().endsWith('.xlsx') ||
                            file.path.toLowerCase().endsWith('.xls'))
                .toList();

            final allQuestions = <Question>[];

            for (final file in excelFiles) {
              if (file is File) {
                try {
                  final excelQuestions = await _loadExcelFile(file);
                  allQuestions.addAll(excelQuestions);
                } catch (e) {
                  print('处理Excel文件失败: $e');
                }
              }
            }

            // 过滤有效题目
            questions = allQuestions
                .where((q) => q.type.isNotEmpty &&
                            q.question.isNotEmpty &&
                            q.correctAnswer.isNotEmpty &&
                            ['单选题', '多选题', '判断题'].contains(q.type))
                .toList();
                
            // 将加载的题目导入到数据库
            if (questions.isNotEmpty) {
              await _importQuestionsToDatabase(questions);
            }
          } else {
            // 如果都没有，使用模拟数据
            questions = _generateMockQuestions();
          }
        }
      }

      // 初始化用户数据
      await _loadUserProgress();
    } catch (e) {
      print('加载题目失败: $e');
      // 如果加载失败，使用模拟数据
      questions = _generateMockQuestions();
      await _loadUserProgress();
    }
  }

  Future<List<Question>> _loadQuestionsFromDatabase() async {
    try {
      final dbHelper = DatabaseHelper();
      return await dbHelper.getAllQuestions();
    } catch (e) {
      print('从数据库加载试题失败: $e');
      return [];
    }
  }

  Future<void> _importQuestionsToDatabase(List<Question> questions) async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.insertQuestions(questions);
    } catch (e) {
      print('导入试题到数据库失败: $e');
    }
  }

  Future<List<Question>> _loadQuestionsFromAssets() async {
    try {
      // 从应用资源中加载试题
      final String response = await rootBundle.loadString('assets/questions.json');
      final data = json.decode(response);
      
      if (data['questions'] != null) {
        final List<dynamic> questionList = data['questions'];
        
        return questionList.map((json) => Question.fromJson(json)).toList();
      }
    } catch (e) {
      print('从资源加载试题失败: $e');
    }
    
    return [];
  }

  Future<List<Question>> _loadExcelFile(File file) async {
    // 使用Excel到SQLite转换工具直接将Excel内容导入数据库
    bool success = await ExcelToSqliteConverter.convertExcelToDatabase(file.path);
    if (success) {
      // 如果导入成功，从数据库获取题目
      final questions = await _loadQuestionsFromDatabase();
      print('成功从Excel文件加载 ${questions.length} 道题目: ${file.path}');
      return questions;
    } else {
      // 如果导入失败，返回空列表并打印错误信息
      print('从Excel文件导入题目失败: ${file.path}');
      return [];
    }
  }



  List<Question> _generateMockQuestions() {
    final questions = <Question>[];
    
    // 添加一些模拟题目
    questions.add(Question(
      id: 'mock_single_001',
      type: '单选题',
      question: 'Flutter是使用哪种编程语言开发的？',
      options: {
        'A': 'Java',
        'B': 'Kotlin',
        'C': 'Dart',
        'D': 'Swift',
      },
      correctAnswer: 'C',
      analysis: 'Flutter框架由Google开发，使用Dart语言作为其编程语言。',
      sourceFile: 'mock_data',
    ));
    
    questions.add(Question(
      id: 'mock_single_002',
      type: '单选题',
      question: '在Dart中，以下哪个关键字用于定义一个常量？',
      options: {
        'A': 'var',
        'B': 'let',
        'C': 'const',
        'D': 'dynamic',
      },
      correctAnswer: 'C',
      analysis: '在Dart中，const关键字用于定义编译时常量。',
      sourceFile: 'mock_data',
    ));
    
    questions.add(Question(
      id: 'mock_multi_001',
      type: '多选题',
      question: '以下哪些是Flutter中的布局组件？',
      options: {
        'A': 'Column',
        'B': 'Row',
        'C': 'Stack',
        'D': 'View',
      },
      correctAnswer: 'ABC',
      analysis: 'Column、Row和Stack都是Flutter中的布局组件，而View不是。',
      sourceFile: 'mock_data',
    ));
    
    questions.add(Question(
      id: 'mock_judge_001',
      type: '判断题',
      question: 'Dart是一种面向对象的编程语言。',
      options: {
        'A': '正确',
        'B': '错误',
      },
      correctAnswer: 'A',
      analysis: 'Dart是一种面向对象的编程语言，支持类和基于mixin的继承。',
      sourceFile: 'mock_data',
    ));
    
    return questions;
  }

  Future<void> _loadUserProgress() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/user_data.json');
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        final jsonData = json.decode(contents);
        
        userProgress = Map<String, UserData>.from(
          jsonData.map((key, value) => MapEntry(key, UserData.fromJson(value))),
        );
      }
    } catch (e) {
      print('加载用户进度失败: $e');
    }
  }

  Future<void> saveUserProgress() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/user_data.json');
      
      final jsonData = userProgress.map((key, value) => MapEntry(key, value.toJson()));
      await file.writeAsString(json.encode(jsonData));
    } catch (e) {
      print('保存用户进度失败: $e');
    }
  }

  void recordAnswer(Question question, String userAnswer, bool isCorrect) {
    final userData = userProgress[question.id] ?? UserData();
    
    userProgress[question.id] = UserData(
      totalCount: userData.totalCount + 1,
      correctCount: isCorrect ? userData.correctCount + 1 : userData.correctCount,
      wrongCount: isCorrect ? userData.wrongCount : userData.wrongCount + 1,
      lastAnswer: userAnswer,
      isWrong: !isCorrect,
    );
  }

  List<Question> getWrongQuestions() {
    return questions.where((q) => userProgress[q.id]?.isWrong == true).toList();
  }
}