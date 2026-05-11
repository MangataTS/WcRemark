import 'package:flutter/material.dart';

class RecordDetailPage extends StatefulWidget {
  const RecordDetailPage({super.key});

  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  int _selectedType = 1; // 0: small, 1: big
  int? _selectedDuration;
  int? _selectedBristolType;
  int _smoothness = 3;
  bool _isWorkHours = false;
  bool _isPaidPoop = false;
  final _noteController = TextEditingController();
  String _selectedMood = '😊';

  final List<String> _moodOptions = ['😊', '😌', '😤', '😩', '🤢', '😄', '😎'];

  final List<Map<String, dynamic>> _durationOptions = [
    {'label': '<1分钟', 'seconds': 30},
    {'label': '1-3分钟', 'seconds': 120},
    {'label': '3-8分钟', 'seconds': 330},
    {'label': '8-15分钟', 'seconds': 690},
    {'label': '>15分钟', 'seconds': 1200},
  ];

  @override
  void initState() {
    super.initState();
    _isWorkHours = _checkWorkHours();
    _isPaidPoop = _isWorkHours;
  }

  bool _checkWorkHours() {
    int hour = DateTime.now().hour;
    int weekday = DateTime.now().weekday;
    return weekday <= 5 && hour >= 9 && hour < 18;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('详细记录'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存', style: TextStyle(fontSize: 16, color: Colors.black)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 24),
            if (_selectedType == 1) ...[
              _buildDurationSelector(),
              const SizedBox(height: 24),
              _buildBristolSelector(),
              const SizedBox(height: 24),
            ],
            _buildSmoothnessSlider(),
            const SizedBox(height: 24),
            _buildPaidPoopSwitch(),
            const SizedBox(height: 24),
            _buildMoodSelector(),
            const SizedBox(height: 24),
            _buildNoteField(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF795548),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: const Text('提交记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('类型', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('💧 小号', style: TextStyle(color: Colors.black)),
                selected: _selectedType == 0,
                onSelected: (_) => setState(() => _selectedType = 0),
                selectedColor: Colors.blue.shade100,
                backgroundColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Text('💩 大号', style: TextStyle(color: Colors.black)),
                selected: _selectedType == 1,
                onSelected: (_) => setState(() => _selectedType = 1),
                selectedColor: Colors.brown.shade100,
                backgroundColor: Colors.grey.shade100,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('时长', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _durationOptions.map((opt) {
            int index = _durationOptions.indexOf(opt);
            return ChoiceChip(
              label: Text(opt['label'] as String, style: const TextStyle(color: Colors.black)),
              selected: _selectedDuration == index,
              onSelected: (_) => setState(() => _selectedDuration = index),
              selectedColor: const Color(0xFFD4A574).withValues(alpha: 0.3),
              backgroundColor: Colors.grey.shade100,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBristolSelector() {
    final bristolLabels = {
      1: '1型: 硬球状',
      2: '2型: 腊肠状块',
      3: '3型: 腊肠裂纹',
      4: '4型: 光滑软便',
      5: '5型: 软团块',
      6: '6型: 糊状',
      7: '7型: 水样',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('布里斯托分型', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: bristolLabels.entries.map((e) {
            return ChoiceChip(
              label: Text(e.value, style: const TextStyle(fontSize: 12, color: Colors.black)),
              selected: _selectedBristolType == e.key,
              onSelected: (_) => setState(() => _selectedBristolType = e.key),
              selectedColor: const Color(0xFFD4A574).withValues(alpha: 0.3),
              backgroundColor: Colors.grey.shade100,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSmoothnessSlider() {
    const labels = ['很费劲', '略费劲', '正常', '通畅', '一泻千里'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('顺畅度', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels.map((l) => Text(l, style: const TextStyle(fontSize: 10, color: Color(0xFF999999)))).toList(),
        ),
        Slider(
          value: _smoothness.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          activeColor: const Color(0xFF795548),
          onChanged: (v) => setState(() => _smoothness = v.toInt()),
        ),
      ],
    );
  }

  Widget _buildPaidPoopSwitch() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('工作时间'),
              value: _isWorkHours,
              onChanged: (v) => setState(() {
                _isWorkHours = v;
                if (!v) _isPaidPoop = false;
              }),
              activeThumbColor: const Color(0xFF795548),
              activeTrackColor: const Color(0xFF795548).withValues(alpha: 0.5),
            ),
            SwitchListTile(
              title: const Text('💰 带薪'),
              subtitle: const Text('摸鱼也是生产力'),
              value: _isPaidPoop,
              onChanged: _isWorkHours
                  ? (v) => setState(() => _isPaidPoop = v)
                  : null,
              activeThumbColor: const Color(0xFF795548),
              activeTrackColor: const Color(0xFF795548).withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('心情', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _moodOptions.map((mood) {
            return GestureDetector(
              onTap: () => setState(() => _selectedMood = mood),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _selectedMood == mood
                      ? const Color(0xFFD4A574).withValues(alpha: 0.3)
                      : Colors.transparent,
                  border: _selectedMood == mood
                      ? Border.all(color: const Color(0xFF795548), width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(mood, style: const TextStyle(fontSize: 24)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('备注（选填）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: '记录更多细节...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
          ),
        ),
      ],
    );
  }

  void _save() {
    final record = <String, dynamic>{
      'type': _selectedType,
      'duration': _selectedDuration != null ? _durationOptions[_selectedDuration!]['seconds'] : null,
      'bristol_type': _selectedBristolType,
      'smoothness': _smoothness,
      'is_work_hours': _isWorkHours,
      'is_paid_poop': _isPaidPoop,
      'mood': _selectedMood,
      'note': _noteController.text.isNotEmpty ? _noteController.text : null,
    };

    Navigator.pop(context, record);
  }
}