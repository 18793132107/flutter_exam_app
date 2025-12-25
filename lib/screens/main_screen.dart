import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能试题练习系统'),
        backgroundColor: Colors.orange.shade400, // 温暖的橙色
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange, Colors.deepOrange], // 温暖的渐变色
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.school,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 30),
                const Text(
                  '智能试题练习系统',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 50),
                _buildMainButton(
                  context,
                  '开始练习',
                  Icons.play_arrow,
                  '/practice',
                ),
                const SizedBox(height: 15),
                _buildMainButton(
                  context,
                  '错题复习',
                  Icons.replay,
                  '/review',
                ),
                const SizedBox(height: 15),
                _buildMainButton(
                  context,
                  '题库统计',
                  Icons.bar_chart,
                  '/stats',
                ),
                const SizedBox(height: 15),
                _buildMainButton(
                  context,
                  '学习进度',
                  Icons.trending_up,
                  '/progress',
                ),
                const SizedBox(height: 15),
                // 模拟考试按钮
                _buildMainButton(
                  context,
                  '模拟考试',
                  Icons.quiz,
                  '/exam',
                ),
                const SizedBox(height: 15),
                _buildMainButton(
                  context,
                  '系统设置',
                  Icons.settings,
                  '/settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, route);
        },
        icon: Icon(icon),
        label: Text(
          title,
          style: const TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.orange.shade700, // 深一些的橙色文字
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}