import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, int> _settings = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _settings['question_count'] = prefs.getInt('question_count') ?? 50;
      _settings['auto_next_delay'] = prefs.getInt('auto_next_delay') ?? 3;
      _settings['exam_single_count'] = prefs.getInt('exam_single_count') ?? 20;
      _settings['exam_multi_count'] = prefs.getInt('exam_multi_count') ?? 20;
      _settings['exam_judgment_count'] = prefs.getInt('exam_judgment_count') ?? 10;
      _settings['font_size'] = prefs.getInt('font_size') ?? 16;
    });

    // 初始化控制器
    _controllers['question_count'] = TextEditingController(
      text: _settings['question_count'].toString(),
    );
    _controllers['auto_next_delay'] = TextEditingController(
      text: _settings['auto_next_delay'].toString(),
    );
    _controllers['exam_single_count'] = TextEditingController(
      text: _settings['exam_single_count'].toString(),
    );
    _controllers['exam_multi_count'] = TextEditingController(
      text: _settings['exam_multi_count'].toString(),
    );
    _controllers['exam_judgment_count'] = TextEditingController(
      text: _settings['exam_judgment_count'].toString(),
    );
    _controllers['font_size'] = TextEditingController(
      text: _settings['font_size'].toString(),
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt('question_count', int.tryParse(_controllers['question_count']!.text) ?? 50);
    await prefs.setInt('auto_next_delay', int.tryParse(_controllers['auto_next_delay']!.text) ?? 3);
    await prefs.setInt('exam_single_count', int.tryParse(_controllers['exam_single_count']!.text) ?? 20);
    await prefs.setInt('exam_multi_count', int.tryParse(_controllers['exam_multi_count']!.text) ?? 20);
    await prefs.setInt('exam_judgment_count', int.tryParse(_controllers['exam_judgment_count']!.text) ?? 10);
    await prefs.setInt('font_size', int.tryParse(_controllers['font_size']!.text) ?? 16);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('设置已保存！'),
          backgroundColor: Colors.orange.shade400, // 温暖的背景色
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controllers.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('系统设置'),
          backgroundColor: Colors.orange.shade400, // 温暖的橙色
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('系统设置'),
        backgroundColor: Colors.orange.shade400, // 温暖的橙色
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              '保存',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              '练习设置',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildSettingItem('每次练习题目数量', 'question_count'),
            _buildSettingItem('自动下一题延迟(秒)', 'auto_next_delay'),
            const SizedBox(height: 20),
            const Text(
              '考试设置',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildSettingItem('单选题数量', 'exam_single_count'),
            _buildSettingItem('多选题数量', 'exam_multi_count'),
            _buildSettingItem('判断题数量', 'exam_judgment_count'),
            const SizedBox(height: 20),
            const Text(
              '界面设置',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildSettingItem('字体大小', 'font_size'),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String label, String key) {
    return Card(
      color: Colors.orange.shade50, // 温暖的背景色
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w500,
                color: Colors.orange.shade800, // 温暖的橙色文字
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controllers[key],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: '请输入数值',
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange.shade400), // 温暖的边框色
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}