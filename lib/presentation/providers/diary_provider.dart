import 'package:flutter/material.dart';
import '../../data/database/db_helper.dart';
import '../../data/models/diary_entry.dart';
import '../../data/models/attachment.dart';
import '../../core/utils/app_logger.dart';

class DiaryProvider with ChangeNotifier {
  List<DiaryEntry> _entries = [];
  bool _isLoading = false;
  String _searchQuery = "";
  String? _selectedSearchMood;
  DateTime? _selectedSearchDate;

  List<DiaryEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedSearchMood => _selectedSearchMood;
  DateTime? get selectedSearchDate => _selectedSearchDate;

  // Filtered entries based on search criteria
  List<DiaryEntry> get filteredEntries {
    return _entries.where((entry) {
      // Keyword search (title or content)
      final matchesKeyword = _searchQuery.isEmpty ||
          entry.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          entry.content.toLowerCase().contains(_searchQuery.toLowerCase());

      // Mood search
      final matchesMood = _selectedSearchMood == null || entry.mood == _selectedSearchMood;

      // Date search
      final matchesDate = _selectedSearchDate == null ||
          (entry.entryDate.year == _selectedSearchDate!.year &&
              entry.entryDate.month == _selectedSearchDate!.month &&
              entry.entryDate.day == _selectedSearchDate!.day);

      return matchesKeyword && matchesMood && matchesDate;
    }).toList();
  }

  // Load all entries from active database
  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      _entries = await DBHelper.instance.getAllEntries();
    } catch (e) {
      AppLogger.error("Error loading entries: $e", exception: e);
      _entries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new diary entry
  Future<void> addEntry({
    required String title,
    required String content,
    required String mood,
    required DateTime entryDate,
    required List<Attachment> attachments,
  }) async {
    final entry = DiaryEntry(
      title: title,
      content: content,
      mood: mood,
      entryDate: entryDate,
      createdAt: DateTime.now(),
      attachments: attachments,
    );

    await DBHelper.instance.insertEntry(entry);
    await loadEntries();
  }

  // Update existing diary entry
  Future<void> updateEntry(DiaryEntry entry) async {
    await DBHelper.instance.updateEntry(entry);
    await loadEntries();
  }

  // Delete diary entry
  Future<void> deleteEntry(int id) async {
    await DBHelper.instance.deleteEntry(id);
    await loadEntries();
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

  // Check if a specific date has any diary entries (for Calendar highlighting)
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

  // === Mood Analytics Helpers ===

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
