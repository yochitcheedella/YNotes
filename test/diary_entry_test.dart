import 'package:flutter_test/flutter_test.dart';
import 'package:ynote/data/models/diary_entry.dart';
import 'package:ynote/data/models/attachment.dart';

void main() {
  group('DiaryEntry and Attachment Model Tests', () {
    test('Attachment instantiation and serialization', () {
      final attachment = Attachment(
        id: 1,
        entryId: 42,
        filePath: '/path/to/file.jpg',
        fileType: 'image',
      );

      expect(attachment.id, 1);
      expect(attachment.entryId, 42);
      expect(attachment.filePath, '/path/to/file.jpg');
      expect(attachment.fileType, 'image');

      final map = attachment.toMap();
      expect(map['AttachmentID'], 1);
      expect(map['EntryID'], 42);
      expect(map['FilePath'], '/path/to/file.jpg');
      expect(map['FileType'], 'image');

      final deserialized = Attachment.fromMap(map);
      expect(deserialized.id, 1);
      expect(deserialized.entryId, 42);
      expect(deserialized.filePath, '/path/to/file.jpg');
      expect(deserialized.fileType, 'image');
    });

    test('DiaryEntry instantiation and serialization', () {
      final now = DateTime.now();
      final attachments = [
        Attachment(filePath: '/path/1', fileType: 'image'),
        Attachment(filePath: '/path/2', fileType: 'audio'),
      ];

      final entry = DiaryEntry(
        id: 10,
        userId: 1,
        entryDate: now,
        title: 'Title',
        content: 'Content',
        mood: 'Happy',
        createdAt: now,
        updatedAt: now,
        attachments: attachments,
      );

      expect(entry.id, 10);
      expect(entry.userId, 1);
      expect(entry.entryDate, now);
      expect(entry.title, 'Title');
      expect(entry.content, 'Content');
      expect(entry.mood, 'Happy');
      expect(entry.createdAt, now);
      expect(entry.updatedAt, now);
      expect(entry.attachments, attachments);

      final map = entry.toMap();
      expect(map['EntryID'], 10);
      expect(map['UserID'], 1);
      expect(map['EntryDate'], now.toIso8601String());
      expect(map['Title'], 'Title');
      expect(map['Content'], 'Content');
      expect(map['Mood'], 'Happy');
      expect(map['CreatedAt'], now.toIso8601String());
      expect(map['UpdatedAt'], now.toIso8601String());

      final deserialized = DiaryEntry.fromMap(map, attachments: attachments);
      expect(deserialized.id, 10);
      expect(deserialized.userId, 1);
      expect(deserialized.entryDate.toIso8601String(), now.toIso8601String());
      expect(deserialized.title, 'Title');
      expect(deserialized.content, 'Content');
      expect(deserialized.mood, 'Happy');
      expect(deserialized.createdAt.toIso8601String(), now.toIso8601String());
      expect(deserialized.updatedAt?.toIso8601String(), now.toIso8601String());
      expect(deserialized.attachments.length, 2);
    });

    test('DiaryEntry.toMap omits EntryID when null', () {
      final entry = DiaryEntry(
        userId: 1,
        entryDate: DateTime.now(),
        title: 'Title',
        content: 'Content',
        mood: 'Happy',
        createdAt: DateTime.now(),
      );

      final map = entry.toMap();
      expect(map.containsKey('EntryID'), isFalse);
    });

    test('DiaryEntry copyWith Null-Safety overrides', () {
      final entry = DiaryEntry(
        id: 1,
        userId: 1,
        entryDate: DateTime(2026, 1, 1),
        title: 'Original Title',
        content: 'Original Content',
        mood: 'Neutral',
        createdAt: DateTime(2026, 1, 1),
        attachments: [Attachment(filePath: '/p1', fileType: 'image')],
      );

      // Perform a copy override
      final copied = entry.copyWith(
        title: 'New Title',
        mood: 'Excited',
        attachments: [], // Clear attachments
      );

      expect(copied.id, 1);
      expect(copied.userId, 1);
      expect(copied.entryDate, DateTime(2026, 1, 1));
      expect(copied.title, 'New Title');
      expect(copied.content, 'Original Content');
      expect(copied.mood, 'Excited');
      expect(copied.attachments.isEmpty, isTrue);
    });
  });
}
