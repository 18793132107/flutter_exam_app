import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/question.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'questions.db');
    
    // 检查是否已有数据库文件，如果没有则创建
    bool exists = await databaseExists(path);
    if (!exists) {
      // 确保目录存在
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (e) {
        print('创建目录失败: $e');
      }
      
      // 创建数据库
      Database db = await openDatabase(path, version: 1, onCreate: _createDatabase);
      
      // 插入示例数据
      await _insertSampleData(db);
      return db;
    } else {
      return await openDatabase(path);
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE questions(
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        question TEXT NOT NULL,
        options TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        analysis TEXT,
        source_file TEXT
      )
    ''');
  }

  Future<void> _insertSampleData(Database db) async {
    // 插入示例题目
    List<Map<String, dynamic>> sampleQuestions = [
      {
        'id': 'db001',
        'type': '单选题',
        'question': 'Flutter是使用哪种编程语言开发的？',
        'options': '{"A":"Java","B":"Kotlin","C":"Dart","D":"Swift"}',
        'correct_answer': 'C',
        'analysis': 'Flutter框架由Google开发，使用Dart语言作为其编程语言。',
        'source_file': 'database'
      },
      {
        'id': 'db002',
        'type': '单选题',
        'question': '在Dart中，以下哪个关键字用于定义一个常量？',
        'options': '{"A":"var","B":"let","C":"const","D":"dynamic"}',
        'correct_answer': 'C',
        'analysis': '在Dart中，const关键字用于定义编译时常量。',
        'source_file': 'database'
      },
      {
        'id': 'db003',
        'type': '多选题',
        'question': '以下哪些是Flutter中的布局组件？',
        'options': '{"A":"Column","B":"Row","C":"Stack","D":"View"}',
        'correct_answer': 'ABC',
        'analysis': 'Column、Row和Stack都是Flutter中的布局组件，而View不是。',
        'source_file': 'database'
      },
      {
        'id': 'db004',
        'type': '判断题',
        'question': 'Dart是一种面向对象的编程语言。',
        'options': '{"A":"正确","B":"错误"}',
        'correct_answer': 'A',
        'analysis': 'Dart是一种面向对象的编程语言，支持类和基于mixin的继承。',
        'source_file': 'database'
      },
      {
        'id': 'db005',
        'type': '单选题',
        'question': '在Flutter中，哪个组件用于垂直排列子组件？',
        'options': '{"A":"Row","B":"Column","C":"Stack","D":"Container"}',
        'correct_answer': 'B',
        'analysis': 'Column组件用于垂直排列子组件，而Row用于水平排列。',
        'source_file': 'database'
      }
    ];

    Batch batch = db.batch();
    for (var question in sampleQuestions) {
      batch.insert('questions', question);
    }
    await batch.commit();
  }

  Future<List<Question>> getAllQuestions() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('questions');

    List<Question> questions = [];
    for (var map in maps) {
      questions.add(Question(
        id: map['id'],
        type: map['type'],
        question: map['question'],
        options: Map<String, String>.from(
          Map<String, dynamic>.from(jsonDecode(map['options']))
        ),
        correctAnswer: map['correct_answer'],
        analysis: map['analysis'] ?? '',
        sourceFile: map['source_file'] ?? 'database',
      ));
    }
    return questions;
  }

  Future<void> insertQuestion(Question question) async {
    Database db = await database;
    await db.insert('questions', {
      'id': question.id,
      'type': question.type,
      'question': question.question,
      'options': jsonEncode(question.options),
      'correct_answer': question.correctAnswer,
      'analysis': question.analysis,
      'source_file': question.sourceFile,
    });
  }

  Future<void> insertQuestions(List<Question> questions) async {
    Database db = await database;
    Batch batch = db.batch();
    for (var question in questions) {
      batch.insert('questions', {
        'id': question.id,
        'type': question.type,
        'question': question.question,
        'options': jsonEncode(question.options),
        'correct_answer': question.correctAnswer,
        'analysis': question.analysis,
        'source_file': question.sourceFile,
      });
    }
    await batch.commit();
  }
}