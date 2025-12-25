import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/exam_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    final examService = Provider.of<ExamService>(context);
    
    // 统计各题型数量
    int totalSingle = 0;
    int totalMulti = 0;
    int totalJudgment = 0;
    
    for (final question in examService.questions) {
      switch (question.type) {
        case '单选题':
          totalSingle++;
          break;
        case '多选题':
          totalMulti++;
          break;
        case '判断题':
          totalJudgment++;
          break;
      }
    }
    
    // 按文件分组统计
    final Map<String, Map<String, int>> fileStats = {};
    for (final question in examService.questions) {
      if (!fileStats.containsKey(question.sourceFile)) {
        fileStats[question.sourceFile] = {
          'total': 0,
          'single': 0,
          'multi': 0,
          'judgment': 0,
        };
      }
      
      fileStats[question.sourceFile]!['total'] = 
          (fileStats[question.sourceFile]!['total'] ?? 0) + 1;
      
      switch (question.type) {
        case '单选题':
          fileStats[question.sourceFile]!['single'] = 
              (fileStats[question.sourceFile]!['single'] ?? 0) + 1;
          break;
        case '多选题':
          fileStats[question.sourceFile]!['multi'] = 
              (fileStats[question.sourceFile]!['multi'] ?? 0) + 1;
          break;
        case '判断题':
          fileStats[question.sourceFile]!['judgment'] = 
              (fileStats[question.sourceFile]!['judgment'] ?? 0) + 1;
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('题库统计'),
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 题库统计信息',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (examService.questions.isEmpty) ...[
                const Text(
                  '暂无题库数据\n请在应用目录下创建\'题库\'文件夹，并将Excel题库文件放入其中。',
                  style: TextStyle(fontSize: 16),
                ),
              ] else ...[
                Card(
                  color: Colors.orange.shade50, // 温暖的背景色
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatItem('总题数', '${examService.questions.length} 道'),
                        _buildStatItem('文件数', '${fileStats.length} 个'),
                        _buildStatItem('单选题', '$totalSingle 道'),
                        _buildStatItem('多选题', '$totalMulti 道'),
                        _buildStatItem('判断题', '$totalJudgment 道'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '📁 文件详情:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...fileStats.entries.map((entry) {
                  final fileName = entry.key;
                  final stats = entry.value;
                  
                  return Card(
                    color: Colors.orange.shade50, // 温暖的背景色
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📄 $fileName',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildStatItem('总题数', '${stats['total']} 道'),
                          _buildStatItem('单选题', '${stats['single']} 道'),
                          _buildStatItem('多选题', '${stats['multi']} 道'),
                          _buildStatItem('判断题', '${stats['judgment']} 道'),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
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