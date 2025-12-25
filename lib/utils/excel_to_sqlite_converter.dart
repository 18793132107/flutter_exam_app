import 'dart:io';
import 'package:excel/excel.dart';
import 'database_helper.dart';
import '../models/question.dart';

class ExcelToSqliteConverter {
  static Future<bool> convertExcelToDatabase(String excelFilePath) async {
    try {
      // 读取Excel文件
      var bytes = await File(excelFilePath).readAsBytes();
      var excel = Excel.decodeBytes(bytes);

      List<Question> questions = [];

      // 遍历Excel中的所有工作表
      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table]!;
        
        // 假设第一行为标题行，从第二行开始是数据
        for (var row = 1; row < sheet.rows.length; row++) {
          var currentRow = sheet.rows[row];
          
          if (currentRow.length >= 6) { // 确保有足够的列
            try {
              // 读取Excel中的数据
              String id = currentRow[0]?.value?.toString() ?? '';
              String type = currentRow[1]?.value?.toString() ?? '';
              String questionText = currentRow[2]?.value?.toString() ?? '';
              String optionsStr = currentRow[3]?.value?.toString() ?? '';
              String correctAnswer = currentRow[4]?.value?.toString() ?? '';
              String analysis = currentRow[5]?.value?.toString() ?? '';

              // 解析选项字符串
              Map<String, String> options = _parseOptionsString(optionsStr);

              // 创建Question对象
              Question question = Question(
                id: id.isNotEmpty ? id : 'excel_${DateTime.now().millisecondsSinceEpoch}_$row',
                type: type,
                question: questionText,
                options: options,
                correctAnswer: correctAnswer,
                analysis: analysis,
                sourceFile: excelFilePath.split('/').last.split('\\').last,
              );

              // 验证题目是否有效
              if (_isValidQuestion(question)) {
                questions.add(question);
              }
            } catch (e) {
              print('解析Excel行 $row 时出错: $e');
              continue;
            }
          }
        }
      }

      // 将题目插入到数据库
      if (questions.isNotEmpty) {
        final dbHelper = DatabaseHelper();
        await dbHelper.insertQuestions(questions);
        print('成功将 ${questions.length} 道题目从Excel导入到数据库');
        return true;
      } else {
        print('未找到有效的题目数据');
        return false;
      }
    } catch (e) {
      print('转换Excel到数据库时出错: $e');
      return false;
    }
  }

  // 从文件路径获取所有Excel文件
  static Future<List<String>> getExcelFilesFromDirectory(String directoryPath) async {
    List<String> excelFiles = [];
    
    try {
      Directory dir = Directory(directoryPath);
      if (await dir.exists()) {
        List<FileSystemEntity> files = dir.listSync();
        
        for (var file in files) {
          if (file is File) {
            String fileName = file.path.toLowerCase();
            if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
              excelFiles.add(file.path);
            }
          }
        }
      }
    } catch (e) {
      print('读取目录时出错: $e');
    }
    
    return excelFiles;
  }

  // 解析选项字符串，假设格式为 "A:选项A|B:选项B|C:选项C|D:选项D"
  static Map<String, String> _parseOptionsString(String optionsStr) {
    Map<String, String> options = {};

    if (optionsStr.isNotEmpty) {
      // 尝试不同的选项格式
      if (optionsStr.contains('|')) {
        // 格式: "A:选项A|B:选项B|C:选项C|D:选项D"
        List<String> pairs = optionsStr.split('|');
        for (String pair in pairs) {
          if (pair.contains(':')) {
            int colonIndex = pair.indexOf(':');
            String key = pair.substring(0, colonIndex).trim();
            String value = pair.substring(colonIndex + 1).trim();
            options[key] = value;
          }
        }
      } else if (optionsStr.contains('、')) {
        // 格式: "A:选项A、B:选项B、C:选项C、D:选项D"
        List<String> pairs = optionsStr.split('、');
        for (String pair in pairs) {
          if (pair.contains(':')) {
            int colonIndex = pair.indexOf(':');
            String key = pair.substring(0, colonIndex).trim();
            String value = pair.substring(colonIndex + 1).trim();
            options[key] = value;
          }
        }
      } else {
        // 如果是简单的逗号分隔格式，如 "选项A,选项B,选项C,选项D"
        // 我们需要假设有4个选项，按A,B,C,D分配
        if (!optionsStr.contains(':')) {
          List<String> values = optionsStr.split(',');
          List<String> keys = ['A', 'B', 'C', 'D'];
          
          for (int i = 0; i < values.length && i < keys.length; i++) {
            options[keys[i]] = values[i].trim();
          }
        }
      }
    }

    return options;
  }

  // 验证题目是否有效
  static bool _isValidQuestion(Question question) {
    return question.type.isNotEmpty &&
           question.question.isNotEmpty &&
           question.correctAnswer.isNotEmpty &&
           question.options.isNotEmpty &&
           ['单选题', '多选题', '判断题'].contains(question.type);
  }

  // 从Excel文件直接读取题目列表（不保存到数据库）
  static Future<List<Question>> readQuestionsFromExcel(String excelFilePath) async {
    try {
      var bytes = await File(excelFilePath).readAsBytes();
      var excel = Excel.decodeBytes(bytes);

      List<Question> questions = [];

      // 遍历Excel中的所有工作表
      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table]!;
        
        // 假设第一行为标题行，从第二行开始是数据
        for (var row = 1; row < sheet.rows.length; row++) {
          var currentRow = sheet.rows[row];
          
          if (currentRow.length >= 6) { // 确保有足够的列
            try {
              // 读取Excel中的数据
              String id = currentRow[0]?.value?.toString() ?? '';
              String type = currentRow[1]?.value?.toString() ?? '';
              String questionText = currentRow[2]?.value?.toString() ?? '';
              String optionsStr = currentRow[3]?.value?.toString() ?? '';
              String correctAnswer = currentRow[4]?.value?.toString() ?? '';
              String analysis = currentRow[5]?.value?.toString() ?? '';

              // 解析选项字符串
              Map<String, String> options = _parseOptionsString(optionsStr);

              // 创建Question对象
              Question question = Question(
                id: id.isNotEmpty ? id : 'excel_${DateTime.now().millisecondsSinceEpoch}_$row',
                type: type,
                question: questionText,
                options: options,
                correctAnswer: correctAnswer,
                analysis: analysis,
                sourceFile: excelFilePath.split('/').last.split('\\').last,
              );

              // 验证题目是否有效
              if (_isValidQuestion(question)) {
                questions.add(question);
              }
            } catch (e) {
              print('解析Excel行 $row 时出错: $e');
              continue;
            }
          }
        }
      }

      return questions;
    } catch (e) {
      print('从Excel读取题目时出错: $e');
      return [];
    }
  }
}