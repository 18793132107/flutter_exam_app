import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/review_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/exam_screen.dart';
import 'services/exam_service.dart';

void main() {
  runApp(const ExamApp());
}

class ExamApp extends StatelessWidget {
  const ExamApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExamService(),
      child: MaterialApp(
        title: '智能试题练习系统',
        theme: ThemeData(
          primarySwatch: Colors.orange, // 使用温暖的橙色主题
          fontFamily: 'Roboto', // 使用系统默认字体
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange.shade300, // 柔和的橙色种子颜色
            brightness: Brightness.light,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const MainScreen(),
          '/practice': (context) => const PracticeScreen(),
          '/review': (context) => const ReviewScreen(),
          '/stats': (context) => const StatsScreen(),
          '/progress': (context) => const ProgressScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/exam': (context) => const ExamScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}