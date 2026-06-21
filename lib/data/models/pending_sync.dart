class PendingSync {
  final int? queueId;
  final int? entryId;
  final String? supabaseId;
  final String action; // 'INSERT', 'UPDATE', 'DELETE'
  final String? payload; // JSON representation of data
  final DateTime createdAt;
  final int attempts;
  final int priority;
  final String? lastError;
  final String status; // 'PENDING', 'PROCESSING', 'FAILED'
  final DateTime? nextRetry;

  PendingSync({
    this.queueId,
    this.entryId,
    this.supabaseId,
    required this.action,
    this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.priority = 1,
    this.lastError,
    this.status = 'PENDING',
    this.nextRetry,
  });

  Map<String, dynamic> toMap() {
    return {
      'EntryID': entryId,
      'SupabaseID': supabaseId,
      'Action': action,
      'Payload': payload,
      'CreatedAt': createdAt.toIso8601String(),
      'Attempts': attempts,
      'Priority': priority,
      'LastError': lastError,
      'Status': status,
      'NextRetry': nextRetry?.toIso8601String(),
    };
  }

  factory PendingSync.fromMap(Map<String, dynamic> map) {
    return PendingSync(
      queueId: map['QueueID'] as int?,
      entryId: map['EntryID'] as int?,
      supabaseId: map['SupabaseID'] as String?,
      action: map['Action'] as String,
      payload: map['Payload'] as String?,
      createdAt: DateTime.parse(map['CreatedAt'] as String),
      attempts: map['Attempts'] as int? ?? 0,
      priority: map['Priority'] as int? ?? 1,
      lastError: map['LastError'] as String?,
      status: map['Status'] as String? ?? 'PENDING',
      nextRetry: map['NextRetry'] != null ? DateTime.tryParse(map['NextRetry'] as String) : null,
    );
  }
}
