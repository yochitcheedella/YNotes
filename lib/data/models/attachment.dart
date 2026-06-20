class Attachment {
  final int? id;
  final int? entryId;
  final String filePath;
  final String fileType; // 'image', 'audio', 'document'

  Attachment({
    this.id,
    this.entryId,
    required this.filePath,
    required this.fileType,
  });

  // Convert to a Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'AttachmentID': id,
      'EntryID': entryId,
      'FilePath': filePath,
      'FileType': fileType,
    };
  }

  // Create an Attachment from a Map
  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['AttachmentID'] as int?,
      entryId: map['EntryID'] as int?,
      filePath: map['FilePath'] as String? ?? '',
      fileType: map['FileType'] as String? ?? 'image',
    );
  }

  Attachment copyWith({
    int? id,
    int? entryId,
    String? filePath,
    String? fileType,
  }) {
    return Attachment(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
    );
  }
}
