import 'attachment.dart';

class DiaryEntry {
  final int? id;
  final int? userId;
  final DateTime entryDate;
  final String title;
  final String content;
  final String mood; // 'Happy', 'Excited', 'Neutral', 'Sad', 'Angry'
  final DateTime createdAt;
  final DateTime? updatedAt; // NEW: track last modification time
  final List<Attachment> attachments;
  final DateTime? expiresAt;
  final int? maxViews;
  final int viewsCount;
  final String? supabaseId;
  final String? lastUpdatedBy;
  final String? syncHash;
  final bool isConflict;
  final String? parentSupabaseId;
  final String? conflictDeviceId;
  final String? syncId; // Idempotency key for network retries

  DiaryEntry({
    this.id,
    this.userId,
    required this.entryDate,
    required this.title,
    required this.content,
    required this.mood,
    required this.createdAt,
    this.updatedAt,
    this.attachments = const [],
    this.expiresAt,
    this.maxViews,
    this.viewsCount = 0,
    this.supabaseId,
    this.lastUpdatedBy,
    this.syncHash,
    this.isConflict = false,
    this.parentSupabaseId,
    this.conflictDeviceId,
    this.syncId,
  });

  /// Serialize to SQLite-compatible map.
  /// EntryID is omitted when null so SQLite auto-increments it correctly.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'UserID': userId,
      'EntryDate': entryDate.toIso8601String(),
      'Title': title,
      'Content': content,
      'Mood': mood,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
      'ExpiresAt': expiresAt?.toIso8601String(),
      'MaxViews': maxViews,
      'ViewsCount': viewsCount,
      'SupabaseID': supabaseId,
      'LastUpdatedBy': lastUpdatedBy,
      'SyncHash': syncHash,
      'IsConflict': isConflict ? 1 : 0,
      'ParentSupabaseID': parentSupabaseId,
      'ConflictDeviceID': conflictDeviceId,
      'SyncID': syncId,
    };
    // Only include EntryID if it exists (prevents SQLite insertion issues)
    if (id != null) map['EntryID'] = id;
    return map;
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map, {List<Attachment> attachments = const []}) {
    return DiaryEntry(
      id: map['EntryID'] as int?,
      userId: map['UserID'] as int?,
      entryDate: DateTime.parse(map['EntryDate'] as String),
      title: map['Title'] as String? ?? '',
      content: map['Content'] as String? ?? '',
      mood: map['Mood'] as String? ?? 'Neutral',
      createdAt: DateTime.parse(map['CreatedAt'] as String),
      updatedAt: map['UpdatedAt'] != null ? DateTime.tryParse(map['UpdatedAt'] as String) : null,
      attachments: attachments,
      expiresAt: map['ExpiresAt'] != null ? DateTime.tryParse(map['ExpiresAt'] as String) : null,
      maxViews: map['MaxViews'] as int?,
      viewsCount: map['ViewsCount'] as int? ?? 0,
      supabaseId: map['SupabaseID'] as String?,
      lastUpdatedBy: map['LastUpdatedBy'] as String?,
      syncHash: map['SyncHash'] as String?,
      isConflict: (map['IsConflict'] as int? ?? 0) == 1,
      parentSupabaseId: map['ParentSupabaseID'] as String?,
      conflictDeviceId: map['ConflictDeviceID'] as String?,
      syncId: map['SyncID'] as String?,
    );
  }

  /// Creates a copy with optional field overrides.
  /// All parameters are nullable — fixes the Dart null-safety violation in v1.
  DiaryEntry copyWith({
    int? id,
    int? userId,
    DateTime? entryDate,
    String? title,
    String? content,
    String? mood,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Attachment>? attachments, // FIX: was non-nullable causing compile error
    DateTime? expiresAt,
    int? maxViews,
    int? viewsCount,
    String? supabaseId,
    String? lastUpdatedBy,
    String? syncHash,
    bool? isConflict,
    String? parentSupabaseId,
    String? conflictDeviceId,
    String? syncId,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entryDate: entryDate ?? this.entryDate,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      attachments: attachments ?? this.attachments,
      expiresAt: expiresAt ?? this.expiresAt,
      maxViews: maxViews ?? this.maxViews,
      viewsCount: viewsCount ?? this.viewsCount,
      supabaseId: supabaseId ?? this.supabaseId,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      syncHash: syncHash ?? this.syncHash,
      isConflict: isConflict ?? this.isConflict,
      parentSupabaseId: parentSupabaseId ?? this.parentSupabaseId,
      conflictDeviceId: conflictDeviceId ?? this.conflictDeviceId,
      syncId: syncId ?? this.syncId,
    );
  }
}
