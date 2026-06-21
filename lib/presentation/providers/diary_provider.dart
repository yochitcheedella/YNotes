import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart' as crypto;
import '../../core/utils/app_logger.dart';
import '../../core/security/encryption_service.dart';
import '../../data/models/diary_entry.dart';
import '../../data/models/attachment.dart';
import '../../data/models/pending_sync.dart';
import '../../data/database/db_helper.dart';

class DiaryProvider with ChangeNotifier, WidgetsBindingObserver {
  List<DiaryEntry> _entries = [];
  bool _isLoading = false;
  String _searchQuery = "";
  String? _selectedSearchMood;
  DateTime? _selectedSearchDate;
  bool _isSyncingQueue = false;
  Timer? _syncTimer;

  List<DiaryEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedSearchMood => _selectedSearchMood;
  DateTime? get selectedSearchDate => _selectedSearchDate;

  DiaryProvider() {
    WidgetsBinding.instance.addObserver(this);
    _startPeriodicSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      processSyncQueue();
      loadEntries();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      processSyncQueue();
      loadEntries();
    }
  }

  // Filtered entries based on search criteria
  List<DiaryEntry> get filteredEntries {
    return _entries.where((entry) {
      final matchesKeyword = _searchQuery.isEmpty ||
          entry.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          entry.content.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesMood = _selectedSearchMood == null || entry.mood == _selectedSearchMood;

      final matchesDate = _selectedSearchDate == null ||
          (entry.entryDate.year == _selectedSearchDate!.year &&
              entry.entryDate.month == _selectedSearchDate!.month &&
              entry.entryDate.day == _selectedSearchDate!.day);

      return matchesKeyword && matchesMood && matchesDate;
    }).toList();
  }

  Future<String> _getPassphrase() async {
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    return await secureStorage.read(key: 'secure_vault_key') ?? '';
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('ynote_device_id');
    if (deviceId == null) {
      deviceId = _generateUUIDv4();
      await prefs.setString('ynote_device_id', deviceId);
      AppLogger.info("Generated new Device ID: $deviceId");
    }
    return deviceId;
  }

  String _generateUUIDv4() {
    final random = Random.secure();
    final chars = '0123456789abcdef';
    final buffer = StringBuffer();
    for (int i = 0; i < 36; i++) {
      if (i == 8 || i == 13 || i == 18 || i == 23) {
        buffer.write('-');
      } else if (i == 14) {
        buffer.write('4');
      } else if (i == 19) {
        buffer.write(chars[(random.nextInt(4) + 8)]);
      } else {
        buffer.write(chars[random.nextInt(16)]);
      }
    }
    return buffer.toString();
  }

  String _calculateSyncHash(String content, DateTime updatedAt, String deviceId) {
    final input = '$content|${updatedAt.toIso8601String()}|$deviceId';
    return crypto.sha256.convert(utf8.encode(input)).toString();
  }

  Future<void> _queueSyncAction({
    required String action,
    int? entryId,
    String? supabaseId,
    DiaryEntry? payload,
  }) async {
    final pending = PendingSync(
      entryId: entryId,
      supabaseId: supabaseId,
      action: action,
      payload: payload != null ? jsonEncode(payload.toMap()) : null,
      createdAt: DateTime.now(),
      status: 'PENDING',
    );
    await DBHelper.instance.pushToQueue(pending);
  }

  // Load all entries from local DB, sync with Supabase, and reload
  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load from local database first
      final localEntries = await DBHelper.instance.getAllEntries();
      _entries = localEntries;
      _isLoading = false;
      notifyListeners();

      // 2. Perform background sync if authenticated and online
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser != null) {
        final passphrase = await _getPassphrase();
        if (passphrase.isEmpty) return;

        final deviceId = await _getOrCreateDeviceId();

        try {
          final response = await supabase
              .from('journal_entries')
              .select()
              .eq('user_id', supabase.auth.currentUser!.id);

          final List<Map<String, dynamic>> remoteRows = List<Map<String, dynamic>>.from(response);
          final List<DiaryEntry> remoteEntries = [];

          for (final row in remoteRows) {
            final String encryptedTitle = row['title'] ?? '';
            final String encryptedContent = row['content'] ?? '';
            
            final String decryptedTitle = EncryptionService.decryptCryptoJS(encryptedTitle, passphrase);
            final String decryptedContent = EncryptionService.decryptCryptoJS(encryptedContent, passphrase);

            final DateTime entryDate = row['entry_date'] != null 
                ? DateTime.parse(row['entry_date']) 
                : DateTime.parse(row['created_at']);
            final DateTime createdAt = DateTime.parse(row['created_at']);
            final DateTime updatedAt = row['updated_at'] != null 
                ? DateTime.parse(row['updated_at']) 
                : createdAt;

            final remoteEntry = DiaryEntry(
              userId: 1, // default local UserID
              title: decryptedTitle,
              content: decryptedContent,
              mood: row['mood'] ?? 'Neutral',
              entryDate: entryDate,
              createdAt: createdAt,
              updatedAt: updatedAt,
              supabaseId: row['id'],
              lastUpdatedBy: row['last_updated_by'],
              syncHash: row['sync_hash'],
              isConflict: row['is_conflict'] == true,
              parentSupabaseId: row['parent_supabase_id'],
              conflictDeviceId: row['conflict_device_id'],
              syncId: row['sync_id'],
            );
            remoteEntries.add(remoteEntry);
          }

          final currentLocalEntries = await DBHelper.instance.getAllEntries();
          final localMap = {for (var e in currentLocalEntries) if (e.supabaseId != null) e.supabaseId!: e};
          final remoteMap = {for (var e in remoteEntries) e.supabaseId!: e};

          for (final remoteEntry in remoteEntries) {
            final sbId = remoteEntry.supabaseId!;
            final localEntry = localMap[sbId];

            if (localEntry != null) {
              if (localEntry.syncHash == remoteEntry.syncHash) {
                continue;
              }

              if (remoteEntry.lastUpdatedBy == deviceId) {
                if (remoteEntry.updatedAt != null && localEntry.updatedAt != null) {
                  if (remoteEntry.updatedAt!.isAfter(localEntry.updatedAt!)) {
                    final updatedLocal = localEntry.copyWith(
                      title: remoteEntry.title,
                      content: remoteEntry.content,
                      mood: remoteEntry.mood,
                      entryDate: remoteEntry.entryDate,
                      updatedAt: remoteEntry.updatedAt,
                      syncHash: remoteEntry.syncHash,
                      lastUpdatedBy: remoteEntry.lastUpdatedBy,
                      syncId: remoteEntry.syncId,
                    );
                    await DBHelper.instance.updateEntry(updatedLocal);
                  } else if (localEntry.updatedAt!.isAfter(remoteEntry.updatedAt!)) {
                    await _queueSyncAction(
                      action: 'UPDATE',
                      entryId: localEntry.id,
                      supabaseId: sbId,
                      payload: localEntry,
                    );
                  }
                }
              } else {
                if (localEntry.updatedAt != remoteEntry.updatedAt) {
                  // Fork conflict
                  final forkEntry = localEntry.copyWith(
                    id: null,
                    title: '${localEntry.title} (Conflict Copy - Mobile)',
                    isConflict: true,
                    parentSupabaseId: sbId,
                    conflictDeviceId: deviceId,
                    supabaseId: null,
                    updatedAt: DateTime.now(),
                  );
                  final forkId = await DBHelper.instance.insertEntry(forkEntry);
                  final savedFork = forkEntry.copyWith(id: forkId);

                  await _queueSyncAction(
                    action: 'INSERT',
                    entryId: forkId,
                    payload: savedFork,
                  );

                  // Update main to remote
                  final updatedMain = localEntry.copyWith(
                    title: remoteEntry.title,
                    content: remoteEntry.content,
                    mood: remoteEntry.mood,
                    entryDate: remoteEntry.entryDate,
                    updatedAt: remoteEntry.updatedAt,
                    syncHash: remoteEntry.syncHash,
                    lastUpdatedBy: remoteEntry.lastUpdatedBy,
                    syncId: remoteEntry.syncId,
                  );
                  await DBHelper.instance.updateEntry(updatedMain);
                  AppLogger.info("Conflict resolved: Forked local changes for entry $sbId");
                }
              }
            } else {
              final unsyncedIndex = currentLocalEntries.indexWhere((e) => 
                e.supabaseId == null && 
                e.title == remoteEntry.title && 
                e.entryDate.day == remoteEntry.entryDate.day && 
                e.entryDate.month == remoteEntry.entryDate.month &&
                e.entryDate.year == remoteEntry.entryDate.year
              );

              if (unsyncedIndex != -1) {
                final linkedEntry = currentLocalEntries[unsyncedIndex].copyWith(
                  supabaseId: sbId,
                  syncHash: remoteEntry.syncHash,
                  lastUpdatedBy: remoteEntry.lastUpdatedBy,
                  syncId: remoteEntry.syncId,
                );
                await DBHelper.instance.updateEntry(linkedEntry);
              } else {
                await DBHelper.instance.insertEntry(remoteEntry);
              }
            }
          }

          for (final localEntry in currentLocalEntries) {
            if (localEntry.supabaseId != null && !remoteMap.containsKey(localEntry.supabaseId)) {
              final pendingQueue = await DBHelper.instance.getPendingQueue();
              final hasPendingDelete = pendingQueue.any((item) => 
                item.supabaseId == localEntry.supabaseId && item.action == 'DELETE'
              );

              if (!hasPendingDelete) {
                await DBHelper.instance.deleteEntry(localEntry.id!);
                AppLogger.info("Deleted entry ${localEntry.id} locally because it was deleted on remote");
              }
            }
          }

          // Safety net: check for unsynced local entries that are not in queue
          final pendingQueue = await DBHelper.instance.getPendingQueue();
          for (final localEntry in currentLocalEntries) {
            if (localEntry.supabaseId == null) {
              final isQueued = pendingQueue.any((item) => item.entryId == localEntry.id && item.action == 'INSERT');
              if (!isQueued) {
                await _queueSyncAction(
                  action: 'INSERT',
                  entryId: localEntry.id,
                  payload: localEntry,
                );
                AppLogger.info("Queued unsynced local entry ${localEntry.id} (safety net)");
              }
            }
          }

          final syncedEntries = await DBHelper.instance.getAllEntries();
          _entries = syncedEntries;
        } catch (e) {
          AppLogger.warning("Supabase sync failed (offline mode): $e");
        }
      }
    } catch (e) {
      AppLogger.error("Error loading entries: $e", exception: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    unawaited(processSyncQueue());
  }

  // Add new diary entry
  Future<void> addEntry({
    required String title,
    required String content,
    required String mood,
    required DateTime entryDate,
    required List<Attachment> attachments,
  }) async {
    final now = DateTime.now();
    final deviceId = await _getOrCreateDeviceId();
    final syncHash = _calculateSyncHash(content, now, deviceId);

    final localEntry = DiaryEntry(
      title: title,
      content: content,
      mood: mood,
      entryDate: entryDate,
      createdAt: now,
      updatedAt: now,
      attachments: attachments,
      lastUpdatedBy: deviceId,
      syncHash: syncHash,
    );

    final localId = await DBHelper.instance.insertEntry(localEntry);
    
    // Generate syncId now that we have localId
    final syncId = '${deviceId}_${localId}_${syncHash.substring(0, 8)}';
    final savedLocalEntry = localEntry.copyWith(id: localId, syncId: syncId);
    
    // Save syncId to DB
    await DBHelper.instance.updateEntry(savedLocalEntry);

    _entries.insert(0, savedLocalEntry);
    notifyListeners();

    await _queueSyncAction(
      action: 'INSERT',
      entryId: localId,
      payload: savedLocalEntry,
    );

    unawaited(processSyncQueue());
  }

  // Update existing diary entry
  Future<void> updateEntry(DiaryEntry entry) async {
    final now = DateTime.now();
    final deviceId = await _getOrCreateDeviceId();
    final syncHash = _calculateSyncHash(entry.content, now, deviceId);
    final syncId = '${deviceId}_${entry.id}_${syncHash.substring(0, 8)}';

    final updatedLocal = entry.copyWith(
      updatedAt: now,
      lastUpdatedBy: deviceId,
      syncHash: syncHash,
      syncId: syncId,
    );

    await DBHelper.instance.updateEntry(updatedLocal);

    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      _entries[idx] = updatedLocal;
      notifyListeners();
    }

    await _queueSyncAction(
      action: 'UPDATE',
      entryId: entry.id,
      supabaseId: entry.supabaseId,
      payload: updatedLocal,
    );

    unawaited(processSyncQueue());
  }

  // Delete diary entry
  Future<void> deleteEntry(int id) async {
    final entryIndex = _entries.indexWhere((e) => e.id == id);
    if (entryIndex == -1) return;
    final entry = _entries[entryIndex];

    await DBHelper.instance.deleteEntry(id);

    _entries.removeAt(entryIndex);
    notifyListeners();

    if (entry.supabaseId != null) {
      await _queueSyncAction(
        action: 'DELETE',
        entryId: id,
        supabaseId: entry.supabaseId,
        payload: entry,
      );
    }

    unawaited(processSyncQueue());
  }

  Future<void> processSyncQueue() async {
    if (_isSyncingQueue) return;
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) return;

    final passphrase = await _getPassphrase();
    if (passphrase.isEmpty) return;

    _isSyncingQueue = true;
    try {
      final deviceId = await _getOrCreateDeviceId();
      final queue = await DBHelper.instance.getPendingQueue();

      for (final item in queue) {
        if (item.nextRetry != null && DateTime.now().isBefore(item.nextRetry!)) {
          continue;
        }

        final processingItem = PendingSync(
          queueId: item.queueId,
          entryId: item.entryId,
          supabaseId: item.supabaseId,
          action: item.action,
          payload: item.payload,
          createdAt: item.createdAt,
          attempts: item.attempts,
          priority: item.priority,
          lastError: item.lastError,
          status: 'PROCESSING',
          nextRetry: item.nextRetry,
        );
        await DBHelper.instance.updateQueueItem(processingItem);

        try {
          await _syncItem(processingItem, passphrase, deviceId);
          await DBHelper.instance.deleteQueueItem(item.queueId!);
        } catch (e) {
          final newAttempts = item.attempts + 1;
          final secondsDelay = min(300, pow(2, newAttempts) * 10).toInt();
          final nextRetry = DateTime.now().add(Duration(seconds: secondsDelay));

          final failedItem = PendingSync(
            queueId: item.queueId,
            entryId: item.entryId,
            supabaseId: item.supabaseId,
            action: item.action,
            payload: item.payload,
            createdAt: item.createdAt,
            attempts: newAttempts,
            priority: item.priority,
            lastError: e.toString(),
            status: 'FAILED',
            nextRetry: nextRetry,
          );
          await DBHelper.instance.updateQueueItem(failedItem);
          AppLogger.warning("Failed to sync queue item ${item.queueId}: $e. Retrying in $secondsDelay seconds.");
        }
      }
    } catch (e) {
      AppLogger.error("Error in processSyncQueue: $e");
    } finally {
      _isSyncingQueue = false;
    }
  }

  Future<void> _syncItem(PendingSync item, String passphrase, String deviceId) async {
    final supabase = Supabase.instance.client;

    if (item.action == 'INSERT' || item.action == 'UPDATE') {
      DiaryEntry? localEntry;
      if (item.entryId != null) {
        final allEntries = await DBHelper.instance.getAllEntries();
        final index = allEntries.indexWhere((e) => e.id == item.entryId);
        if (index != -1) {
          localEntry = allEntries[index];
        }
      }

      if (localEntry == null) {
        AppLogger.warning("Sync item ${item.queueId} entry not found locally. Skipping.");
        return;
      }

      final encryptedTitle = EncryptionService.encryptCryptoJS(localEntry.title, passphrase);
      final encryptedContent = EncryptionService.encryptCryptoJS(localEntry.content, passphrase);
      final syncHash = _calculateSyncHash(localEntry.content, localEntry.updatedAt ?? DateTime.now(), deviceId);

      final Map<String, dynamic> data = {
        'user_id': supabase.auth.currentUser!.id,
        'title': encryptedTitle,
        'content': encryptedContent,
        'mood': localEntry.mood,
        'entry_date': localEntry.entryDate.toIso8601String(),
        'created_at': localEntry.createdAt.toIso8601String(),
        'updated_at': (localEntry.updatedAt ?? DateTime.now()).toIso8601String(),
        'last_updated_by': deviceId,
        'sync_hash': syncHash,
        'is_conflict': localEntry.isConflict,
        'parent_supabase_id': localEntry.parentSupabaseId,
        'conflict_device_id': localEntry.conflictDeviceId,
        'sync_id': localEntry.syncId,
      };

      if (item.action == 'INSERT' && localEntry.supabaseId == null) {
        try {
          final response = await supabase
              .from('journal_entries')
              .insert(data)
              .select('id')
              .single();

          if (response != null && response['id'] != null) {
            final String newSbId = response['id'];
            final updated = localEntry.copyWith(
              supabaseId: newSbId,
              lastUpdatedBy: deviceId,
              syncHash: syncHash,
            );
            await DBHelper.instance.updateEntry(updated);
          }
        } on PostgrestException catch (e) {
          if (e.code == '23505' && localEntry.syncId != null) {
            // Unique constraint violation - idempotent retry!
            AppLogger.info("Idempotent retry detected for insert (sync_id ${localEntry.syncId}). Fetching existing ID.");
            final existing = await supabase
                .from('journal_entries')
                .select('id')
                .eq('sync_id', localEntry.syncId!)
                .maybeSingle();
            
            if (existing != null && existing['id'] != null) {
              final String existingSbId = existing['id'];
              final updated = localEntry.copyWith(
                supabaseId: existingSbId,
                lastUpdatedBy: deviceId,
                syncHash: syncHash,
              );
              await DBHelper.instance.updateEntry(updated);
            }
          } else {
            rethrow;
          }
        }
      } else {
        final sbId = localEntry.supabaseId ?? item.supabaseId;
        if (sbId != null) {
          await supabase
              .from('journal_entries')
              .upsert({
                'id': sbId,
                ...data,
              });

          final updated = localEntry.copyWith(
            lastUpdatedBy: deviceId,
            syncHash: syncHash,
          );
          await DBHelper.instance.updateEntry(updated);
        } else {
          throw Exception("Missing Supabase ID for sync update");
        }
      }
    } else if (item.action == 'DELETE') {
      final sbId = item.supabaseId;
      if (sbId != null) {
        await supabase
            .from('journal_entries')
            .delete()
            .eq('id', sbId);
      }
    }
  }

  // Handle conflict resolution
  Future<void> resolveConflict(DiaryEntry original, DiaryEntry conflict, String resolution) async {
    if (resolution == 'KEEP_ORIGINAL') {
      if (conflict.id != null) {
        await deleteEntry(conflict.id!);
      }
    } else if (resolution == 'KEEP_CONFLICT') {
      final merged = original.copyWith(
        title: conflict.title.replaceAll(' (Conflict Copy - Mobile)', ''),
        content: conflict.content,
        mood: conflict.mood,
        attachments: conflict.attachments,
        updatedAt: DateTime.now(),
      );
      await updateEntry(merged);
      if (conflict.id != null) {
        await deleteEntry(conflict.id!);
      }
    } else if (resolution == 'KEEP_BOTH') {
      final detached = DiaryEntry(
        id: conflict.id,
        userId: conflict.userId,
        entryDate: conflict.entryDate,
        title: conflict.title.replaceAll(' (Conflict Copy - Mobile)', ''),
        content: conflict.content,
        mood: conflict.mood,
        createdAt: conflict.createdAt,
        updatedAt: DateTime.now(),
        attachments: conflict.attachments,
        supabaseId: conflict.supabaseId,
        lastUpdatedBy: conflict.lastUpdatedBy,
        syncHash: conflict.syncHash,
        isConflict: false,
        parentSupabaseId: null, // Detach from parent
        conflictDeviceId: null,
        syncId: conflict.syncId,
      );
      await updateEntry(detached);
    }
  }

  // Set Search Query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Set Search Mood
  void setSearchMood(String? mood) {
    _selectedSearchMood = mood;
    notifyListeners();
  }

  // Set Search Date
  void setSearchDate(DateTime? date) {
    _selectedSearchDate = date;
    notifyListeners();
  }

  // Clear search filters
  void clearSearchFilters() {
    _searchQuery = "";
    _selectedSearchMood = null;
    _selectedSearchDate = null;
    notifyListeners();
  }

  // Check if a specific date has any diary entries
  bool hasEntryOnDate(DateTime date) {
    return _entries.any((entry) =>
        entry.entryDate.year == date.year &&
        entry.entryDate.month == date.month &&
        entry.entryDate.day == date.day);
  }

  // Get entries for a specific date
  List<DiaryEntry> getEntriesForDate(DateTime date) {
    return _entries
        .where((entry) =>
            entry.entryDate.year == date.year &&
            entry.entryDate.month == date.month &&
            entry.entryDate.day == date.day)
        .toList();
  }

  // Get mood distribution count for current month
  Map<String, int> getMoodStatisticsForMonth(int month, int year) {
    final stats = {'Happy': 0, 'Excited': 0, 'Neutral': 0, 'Sad': 0, 'Angry': 0};

    final monthlyEntries = _entries.where((entry) =>
        entry.entryDate.month == month && entry.entryDate.year == year);

    for (var entry in monthlyEntries) {
      if (stats.containsKey(entry.mood)) {
        stats[entry.mood] = stats[entry.mood]! + 1;
      }
    }
    return stats;
  }
}
