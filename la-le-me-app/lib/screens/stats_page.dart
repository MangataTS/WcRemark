import 'package:flutter/material.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据统计')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard(
            context,
            icon: '📊',
            title: '本周肠道周报',
            subtitle: '查看本周详细统计',
            onTap: () => Navigator.pushNamed(context, '/stats/weekly'),
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            icon: '📅',
            title: '月度统计',
            subtitle: '日历热力图与趋势',
            onTap: () => Navigator.pushNamed(context, '/stats/monthly'),
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            icon: '📈',
            title: '年度报告',
            subtitle: '年度关键词与健康报告',
            onTap: () => Navigator.pushNamed(context, '/stats/yearly'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 28)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF999999))),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}