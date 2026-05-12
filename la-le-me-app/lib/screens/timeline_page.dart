import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/toilet_record.dart';
import '../services/database_service.dart';
import '../providers/record_provider.dart';

final allRecordsProvider = FutureProvider<List<ToiletRecord>>((ref) async {
  ref.watch(refreshTriggerProvider);
  return await DatabaseService.getRecords(limit: 500);
});

class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(allRecordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('记录时间轴')),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('加载失败', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(allRecordsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('暂无记录', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('开始记录你的如厕数据吧～',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                ],
              ),
            );
          }

          final grouped = _groupByDate(records);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final entry = grouped[index];
              return _buildDateGroup(context, ref, entry);
            },
          );
        },
      ),
    );
  }

  List<_DateGroup> _groupByDate(List<ToiletRecord> records) {
    final Map<String, List<ToiletRecord>> map = {};
    final dateFmt = DateFormat('yyyy-MM-dd');

    for (final r in records) {
      final dateStr = dateFmt.format(
        DateTime.fromMillisecondsSinceEpoch(r.timestamp),
      );
      map.putIfAbsent(dateStr, () => []).add(r);
    }

    final grouped = map.entries.map((e) {
      final d = DateTime.parse(e.key);
      return _DateGroup(
        date: d,
        dateLabel: _formatDateLabel(d),
        records: e.value,
      );
    }).toList();

    grouped.sort((a, b) => b.date.compareTo(a.date));
    return grouped;
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    final dateStr = DateFormat('MM月dd日').format(date);
    final weekDay = DateFormat('EEEE', 'zh_CN').format(date);

    if (diff == 0) return '今天 · $weekDay';
    if (diff == 1) return '昨天 · $weekDay';
    if (diff == 2) return '前天 · $weekDay';
    return '$dateStr · $weekDay';
  }

  Widget _buildDateGroup(
    BuildContext context,
    WidgetRef ref,
    _DateGroup group,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFEFEBE9),
                ),
                child: const Center(
                  child: Text('📅', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                group.dateLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5D4037),
                ),
              ),
              const Spacer(),
              Text(
                '${group.records.length} 次',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
        ...List.generate(group.records.length, (i) {
          final isLast = i == group.records.length - 1;
          return _buildTimelineItem(context, ref, group.records[i], isLast);
        }),
      ],
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    WidgetRef ref,
    ToiletRecord record,
    bool isLast,
  ) {
    final timeStr = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(record.timestamp),
    );

    final bristolLabels = {
      1: '硬球状',
      2: '腊肠块',
      3: '裂纹状',
      4: '光滑软便',
      5: '软团块',
      6: '糊状',
      7: '水样',
    };

    final durationLabels = {
      30: '<1分钟',
      120: '1-3分钟',
      330: '3-8分钟',
      690: '8-15分钟',
      1200: '>15分钟',
    };

    String durationText = '--';
    if (record.duration != null) {
      durationText = durationLabels[record.duration] ??
          '${(record.duration! / 60).toStringAsFixed(0)}分钟';
    }

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这条记录吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await DatabaseService.deleteRecord(record.id);
        ref.read(refreshTriggerProvider.notifier).state++;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('记录已删除'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: record.type == RecordType.big
                            ? const Color(0xFFD4A574)
                            : const Color(0xFF64B5F6),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: (record.type == RecordType.big
                                    ? const Color(0xFFD4A574)
                                    : const Color(0xFF64B5F6))
                                .withValues(alpha: 0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: const Color(0xFFE0E0E0),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFFAFAFA),
                    border: Border.all(
                      color: const Color(0xFFEEEEEE),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            record.type == RecordType.big ? '💩 大号' : '💧 小号',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildTag(durationText, Icons.timer_outlined),
                          if (record.type == RecordType.big &&
                              record.bristolType != null)
                            _buildTag(
                              '${record.bristolType}型 ${bristolLabels[record.bristolType] ?? ''}',
                              Icons.science_outlined,
                            ),
                          if (record.smoothness != null)
                            _buildTag(
                              _smoothnessLabel(record.smoothness!),
                              Icons.waves,
                            ),
                          if (record.mood != null)
                            _buildTag(record.mood!, Icons.emoji_emotions_outlined),
                          if (record.isPaidPoop)
                            _buildTag('💰 带薪', Icons.monetization_on_outlined),
                        ],
                      ),
                      if (record.note != null && record.note!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          record.note!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _smoothnessLabel(int value) {
    switch (value) {
      case 1:
        return '很费劲';
      case 2:
        return '略费劲';
      case 3:
        return '正常';
      case 4:
        return '通畅';
      case 5:
        return '一泻千里';
      default:
        return '--';
    }
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: const Color(0xFFF0F0F0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF999999)),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateGroup {
  final DateTime date;
  final String dateLabel;
  final List<ToiletRecord> records;

  _DateGroup({
    required this.date,
    required this.dateLabel,
    required this.records,
  });
}