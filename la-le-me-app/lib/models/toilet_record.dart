enum RecordType { small, big }

class ToiletRecord {
  final String id;
  final RecordType type;
  final int timestamp;
  final int? duration;
  final int? bristolType;
  final int? color;
  final int? smoothness;
  final bool isWorkHours;
  final bool isPaidPoop;
  final String? locationHash;
  final String? note;
  final String? mood;
  final int createdAt;
  final int updatedAt;
  final bool isSynced;
  final String? syncUuid;

  const ToiletRecord({
    required this.id,
    required this.type,
    required this.timestamp,
    this.duration,
    this.bristolType,
    this.color,
    this.smoothness,
    this.isWorkHours = false,
    this.isPaidPoop = false,
    this.locationHash,
    this.note,
    this.mood,
    this.createdAt = 0,
    this.updatedAt = 0,
    this.isSynced = false,
    this.syncUuid,
  });

  ToiletRecord copyWith({
    String? id,
    RecordType? type,
    int? timestamp,
    int? duration,
    int? bristolType,
    int? color,
    int? smoothness,
    bool? isWorkHours,
    bool? isPaidPoop,
    String? locationHash,
    String? note,
    String? mood,
    bool? isSynced,
    String? syncUuid,
  }) {
    return ToiletRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
      bristolType: bristolType ?? this.bristolType,
      color: color ?? this.color,
      smoothness: smoothness ?? this.smoothness,
      isWorkHours: isWorkHours ?? this.isWorkHours,
      isPaidPoop: isPaidPoop ?? this.isPaidPoop,
      locationHash: locationHash ?? this.locationHash,
      note: note ?? this.note,
      mood: mood ?? this.mood,
      isSynced: isSynced ?? this.isSynced,
      syncUuid: syncUuid ?? this.syncUuid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'timestamp': timestamp,
      'duration': duration,
      'bristol_type': bristolType,
      'color': color,
      'smoothness': smoothness,
      'is_work_hours': isWorkHours ? 1 : 0,
      'is_paid_poop': isPaidPoop ? 1 : 0,
      'location_hash': locationHash,
      'note': note,
      'mood': mood,
      'is_synced': isSynced ? 1 : 0,
      'sync_uuid': syncUuid,
    };
  }

  factory ToiletRecord.fromMap(Map<String, dynamic> map) {
    return ToiletRecord(
      id: map['id'] as String,
      type: RecordType.values[map['type'] as int],
      timestamp: map['timestamp'] as int,
      duration: map['duration'] as int?,
      bristolType: map['bristol_type'] as int?,
      color: map['color'] as int?,
      smoothness: map['smoothness'] as int?,
      isWorkHours: (map['is_work_hours'] as int?) == 1,
      isPaidPoop: (map['is_paid_poop'] as int?) == 1,
      locationHash: map['location_hash'] as String?,
      note: map['note'] as String?,
      mood: map['mood'] as String?,
      createdAt: map['created_at'] as int? ?? 0,
      updatedAt: map['updated_at'] as int? ?? 0,
      isSynced: (map['is_synced'] as int?) == 1,
      syncUuid: map['sync_uuid'] as String?,
    );
  }

  @override
  String toString() => 'ToiletRecord(id: $id, type: $type, timestamp: $timestamp)';
}
