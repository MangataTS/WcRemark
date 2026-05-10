import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/record_provider.dart';

class WeeklyStatsPage extends ConsumerWidget {
  const WeeklyStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(weeklyStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('本周肠道周报')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('暂无数据', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('记录如厕数据后即可查看周报', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            ],
          ),
        ),
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(stats),
              const SizedBox(height: 16),
              _buildWeekOverview(stats),
              const SizedBox(height: 16),
              _buildBristolDistribution(stats),
              const SizedBox(height: 16),
              _buildStatsCards(stats),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(WeeklyStatsData stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF795548), Color(0xFFA1887F)],
        ),
      ),
      child: Column(
        children: [
          const Text('本周规律指数', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('${stats.regularityScore}',
              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
          const Text('分', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text('${stats.healthTitle} 🎉', style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildWeekOverview(WeeklyStatsData stats) {
    final days = ['一', '二', '三', '四', '五', '六', '日'];
    final counts = stats.dailyBigCounts;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('7日趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final height = (counts[i] * 30.0).clamp(4.0, 90.0);
                final hasData = counts[i] > 0;
                return Column(
                  children: [
                    Text('${counts[i]}',
                        style: TextStyle(fontSize: 10, color: hasData ? const Color(0xFF795548) : const Color(0xFF999999))),
                    const SizedBox(height: 2),
                    Container(
                      width: 28,
                      height: height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: hasData ? const Color(0xFFD4A574) : const Color(0xFFE0E0E0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('周${days[i]}', style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBristolDistribution(WeeklyStatsData stats) {
    if (stats.bristolDist.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('布里斯托分型分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              Text('暂无布里斯托数据', style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
            ],
          ),
        ),
      );
    }

    final totalBr = stats.bristolDist.values.fold(0, (a, b) => a + b);
    final sortedEntries = stats.bristolDist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final bristolLabels = {
      1: '1型-硬球状',
      2: '2型-腊肠块',
      3: '3型-裂纹状',
      4: '4型-光滑软便',
      5: '5型-软团块',
      6: '6型-糊状',
      7: '7型-水样',
    };

    final colors = {
      1: Colors.red.shade300,
      2: Colors.orange.shade300,
      3: Colors.green.shade300,
      4: Colors.green.shade400,
      5: Colors.yellow.shade300,
      6: Colors.orange.shade400,
      7: Colors.red.shade400,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('布里斯托分型分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...sortedEntries.map((e) {
              final pct = totalBr > 0 ? e.value / totalBr : 0.0;
              return _buildBristolRow(e.key, bristolLabels[e.key] ?? '${e.key}型', pct, colors[e.key] ?? Colors.brown);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBristolRow(int type, String label, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade200,
              color: color,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text('${(percentage * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: Color(0xFF999999)), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(WeeklyStatsData stats) {
    final avgDuration = stats.avgBigDuration > 0 ? stats.avgBigDuration.toStringAsFixed(1) : '--';
    final bigPct = stats.totalCount > 0 ? (stats.bigRatio * 100).toInt().toString() : '--';

    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildMiniCard('总次数', stats.totalCount.toString(), '次', ''),
          _buildMiniCard('大号占比', bigPct, '%', ''),
          _buildMiniCard('平均时长', avgDuration, '分钟', ''),
          _buildMiniCard('规律指数', stats.regularityScore.toString(), '分', ''),
          _buildMiniCard('带薪收益', stats.paidHours.toStringAsFixed(1), '小时', ''),
        ],
      ),
    );
  }

  Widget _buildMiniCard(String title, String value, String unit, String delta) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF7F7F7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
              Text(unit, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
            ],
          ),
          if (delta.isNotEmpty)
            Text(delta, style: const TextStyle(fontSize: 11, color: Colors.green)),
        ],
      ),
    );
  }
}

class MonthlyStatsPage extends ConsumerWidget {
  const MonthlyStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(monthlyStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('月度统计')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('暂无数据', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('持续记录即可查看月报', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            ],
          ),
        ),
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGradeCard(stats),
              const SizedBox(height: 16),
              _buildCalendarView(stats),
              const SizedBox(height: 16),
              _buildPeriodDistribution(stats),
              const SizedBox(height: 16),
              _buildStatsSummary(stats),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeCard(MonthlyStatsData stats) {
    final gradeColors = {'A': const Color(0xFF4CAF50), 'B': const Color(0xFF2196F3), 'C': const Color(0xFFFF9800), 'D': const Color(0xFFF44336)};
    final gradeColor = gradeColors[stats.healthGrade] ?? Colors.grey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [gradeColor, gradeColor.withValues(alpha: 0.7)],
        ),
      ),
      child: Column(
        children: [
          const Text('月度健康评级', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          Text(stats.healthGrade,
              style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(stats.healthTitle,
              style: const TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGradeScore('频率', stats.healthBreakdown['frequency'] ?? 0),
              _buildGradeScore('规律', stats.healthBreakdown['regularity'] ?? 0),
              _buildGradeScore('布里斯托', stats.healthBreakdown['bristol'] ?? 0),
              _buildGradeScore('时长', stats.healthBreakdown['duration'] ?? 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradeScore(String label, int score) {
    return Column(
      children: [
        Text('$score', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildCalendarView(MonthlyStatsData stats) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${now.month}月出库日历', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['一', '二', '三', '四', '五', '六', '日'].map((d) =>
                SizedBox(width: 36, child: Center(child: Text(d, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))))),
              ).toList(),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 0,
              runSpacing: 2,
              children: List.generate(firstWeekday - 1, (_) => const SizedBox(width: 36, height: 36))
                ..addAll(List.generate(daysInMonth, (i) {
                  final day = i + 1;
                  final count = stats.dailyBigCounts[day] ?? 0;
                  return SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: Container(
                        width: count > 0 ? 28 : 20,
                        height: count > 0 ? 28 : 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(count > 0 ? 8 : 10),
                          color: count > 0
                            ? Color(0xFFD4A574).withValues(alpha: count > 2 ? 1.0 : count / 2.0 * 0.8 + 0.2)
                            : const Color(0xFFF0F0F0),
                        ),
                        child: Center(
                          child: Text('$day',
                            style: TextStyle(
                              fontSize: 11,
                              color: count > 0 ? Colors.white : const Color(0xFF999999),
                              fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                })),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodDistribution(MonthlyStatsData stats) {
    if (stats.periodDist.values.every((v) => v == 0)) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('时段分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...stats.periodDist.entries.map((e) {
              final maxVal = stats.periodDist.values.reduce((a, b) => a > b ? a : b);
              final pct = maxVal > 0 ? e.value / maxVal : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(width: 40, child: Text('${e.key}时', style: const TextStyle(fontSize: 12))),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFFD4A574),
                      ),
                    ),
                    SizedBox(width: 30, child: Text('${e.value}', style: const TextStyle(fontSize: 12, color: Color(0xFF999999)), textAlign: TextAlign.right)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary(MonthlyStatsData stats) {
    return Row(
      children: [
        Expanded(child: _buildSummaryItem('大号', '${stats.totalBig}', '次')),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryItem('小号', '${stats.totalSmall}', '次')),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryItem('均时长', stats.avgBigDuration > 0 ? stats.avgBigDuration.toStringAsFixed(1) : '--', '分钟')),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF7F7F7),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(unit, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
            ],
          ),
        ],
      ),
    );
  }
}

class YearlyStatsPage extends ConsumerWidget {
  const YearlyStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(yearlyStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('年度报告')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bar_chart, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('暂无数据', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('积累更多数据后即可查看年报', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            ],
          ),
        ),
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKeywordCard(stats),
              const SizedBox(height: 16),
              _buildMonthlyChart(stats),
              const SizedBox(height: 16),
              _buildYearlySummary(stats),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeywordCard(YearlyStatsData stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF795548), Color(0xFFA1887F)],
        ),
      ),
      child: Column(
        children: [
          const Text('年度关键词', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: stats.keywords.map((k) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: Text(k, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(YearlyStatsData stats) {
    final maxCount = stats.monthlyBigCounts.values.fold(0, (a, b) => a > b ? a : b).clamp(1, 999);
    final months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('月度出库趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(12, (i) {
                  final count = stats.monthlyBigCounts[i + 1] ?? 0;
                  final height = maxCount > 0 ? (count / maxCount * 160).clamp(4.0, 160.0) : 4.0;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (count > 0)
                        Text('$count', style: const TextStyle(fontSize: 9, color: Color(0xFF795548))),
                      const SizedBox(height: 2),
                      Container(
                        width: 20,
                        height: height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: count > 0 ? const Color(0xFFD4A574) : const Color(0xFFE0E0E0),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(months[i], style: const TextStyle(fontSize: 8, color: Color(0xFF999999))),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlySummary(YearlyStatsData stats) {
    return Row(
      children: [
        Expanded(child: _buildSummaryItem('总出库', '${stats.totalCount}', '次')),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryItem('大号', '${stats.totalBig}', '次')),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryItem('带薪赚', '¥${stats.paidEarnings.toStringAsFixed(0)}', '')),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF7F7F7),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (unit.isNotEmpty) Text(unit, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
            ],
          ),
        ],
      ),
    );
  }
}