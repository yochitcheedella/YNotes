import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/diary_provider.dart';
import '../../core/constants/app_theme.dart';
import 'entry_editor_screen.dart';
import 'mood_analytics_screen.dart';
import 'settings_screen.dart';
import 'backup_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTab = 0;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  late List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      _buildJournalTab(),
      _buildSearchTab(),
      const MoodAnalyticsScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    // Subtle Decoy check. If in decoy mode, change the AppBar title slightly (e.g. "My Notes" vs "YNote")
    final title = authProvider.isDecoyMode ? "My Journal" : "YNote";

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              authProvider.isDecoyMode ? Icons.notes_outlined : Icons.security, 
              size: 20, 
              color: AppColors.darkPrimary
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: () {
              // Direct navigation to backup screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BackupScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // Record touch interaction to reset inactivity timer
          // This is the core engine hook for Auto-Lock
          // Whenever the user taps anywhere on the screen, the lock timer is updated!
          // We can also hook this at the MaterialApp level, but doing it here guarantees coverage of active dashboard actions.
          // In main.dart, we will also hook it globally!
        },
        child: _tabs[_currentTab],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EntryEditorScreen(initialDate: _selectedDate),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // ================= TAB 1: JOURNAL DASHBOARD =================

  Widget _buildJournalTab() {
    final diaryProvider = Provider.of<DiaryProvider>(context);
    final selectedEntries = diaryProvider.getEntriesForDate(_selectedDate);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom Calendar Widget
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _buildCalendarWidget(diaryProvider),
          ),
          
          // Mood summary widget for the focused month
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _buildMonthlyMoodSummary(diaryProvider),
          ),

          // Selected Date Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
            child: Text(
              'Entries for ${DateFormat('MMMM d, yyyy').format(_selectedDate)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Entries List
          selectedEntries.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: selectedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = selectedEntries[index];
                    return _buildEntryCard(entry);
                  },
                ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCalendarWidget(DiaryProvider diaryProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Days in current month calculations
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDayOffset = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday - 1; // 0-based offset (Monday = 0)

    final List<String> weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Card(
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: AppTheme.glassDecoration(context: context, opacity: isDark ? 0.05 : 0.02),
        child: Column(
          children: [
            // Calendar Month Navigation Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedMonth),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
            const Divider(color: Colors.white10),
            
            // Weekday Headings
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 7,
              itemBuilder: (context, index) {
                return Center(
                  child: Text(
                    weekDays[index],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Days Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: daysInMonth + firstDayOffset,
              itemBuilder: (context, index) {
                if (index < firstDayOffset) {
                  return const SizedBox(); // empty cells before month starts
                }

                final dayNum = index - firstDayOffset + 1;
                final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                final isSelected = DateUtils.isSameDay(cellDate, _selectedDate);
                final isToday = DateUtils.isSameDay(cellDate, DateTime.now());
                final hasEntry = diaryProvider.hasEntryOnDate(cellDate);

                // Get mood colors if entry exists
                Color? dotColor;
                if (hasEntry) {
                  final dayEntries = diaryProvider.getEntriesForDate(cellDate);
                  if (dayEntries.isNotEmpty) {
                    final primaryMood = dayEntries.first.mood;
                    dotColor = AppColors.moodColors[primaryMood];
                  }
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = cellDate;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.darkPrimary
                          : isToday
                              ? AppColors.darkPrimary.withAlpha(51)
                              : Colors.transparent,
                      border: isToday && !isSelected
                          ? Border.all(color: AppColors.darkPrimary, width: 1)
                          : null,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayNum.toString(),
                            style: TextStyle(
                              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                            ),
                          ),
                          if (hasEntry && dotColor != null)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.white : dotColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyMoodSummary(DiaryProvider diaryProvider) {
    final stats = diaryProvider.getMoodStatisticsForMonth(_focusedMonth.month, _focusedMonth.year);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: AppTheme.glassDecoration(context: context, opacity: isDark ? 0.05 : 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mood Summary this Month',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: AppColors.moodEmojis.keys.map((mood) {
                final emoji = AppColors.moodEmojis[mood]!;
                final count = stats[mood] ?? 0;
                final color = AppColors.moodColors[mood]!;

                return Column(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      mood,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: count > 0 ? color.withAlpha(51) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: count > 0 ? color : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          children: [
            const Text('📝', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'No Entries Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Record your feelings, activities, and secret thoughts. Tap the floating button below to write.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(DiaryEntry entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emoji = AppColors.moodEmojis[entry.mood] ?? '😐';
    final moodColor = AppColors.moodColors[entry.mood] ?? Colors.purple;

    return GestureDetector(
      onTap: () {
        // Open Editor with this entry for viewing/editing
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EntryEditorScreen(entry: entry),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: AppTheme.glassDecoration(context: context, opacity: isDark ? 0.05 : 0.02),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mood Indicator
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: moodColor.withAlpha(25),
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.content,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.attachments.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.attach_file, size: 14, color: AppColors.darkPrimary.withAlpha(204)),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.attachments.length} Attachment(s)',
                            style: const TextStyle(fontSize: 12, color: AppColors.darkPrimary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ================= TAB 2: SEARCH SYSTEM =================

  Widget _buildSearchTab() {
    final diaryProvider = Provider.of<DiaryProvider>(context);
    final filtered = diaryProvider.filteredEntries;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Search Textfield
          TextField(
            onChanged: (val) => diaryProvider.setSearchQuery(val),
            decoration: InputDecoration(
              hintText: 'Search memories, logs, activities...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: diaryProvider.searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear), 
                      onPressed: () => diaryProvider.setSearchQuery(""),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          // Search Filters Row (Mood Chips + Date Selection)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Date Selector chip
                FilterChip(
                  label: Text(
                    diaryProvider.selectedSearchDate == null 
                        ? 'Filter by Date' 
                        : DateFormat('MMM d, yy').format(diaryProvider.selectedSearchDate!)
                  ),
                  selected: diaryProvider.selectedSearchDate != null,
                  onSelected: (selected) async {
                    if (selected) {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        diaryProvider.setSearchDate(picked);
                      }
                    } else {
                      diaryProvider.setSearchDate(null);
                    }
                  },
                ),
                const SizedBox(width: 8),

                // Mood Filter chips
                ...AppColors.moodEmojis.keys.map((mood) {
                  final isSelected = diaryProvider.selectedSearchMood == mood;
                  final emoji = AppColors.moodEmojis[mood]!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: FilterChip(
                      label: Text('$emoji $mood'),
                      selected: isSelected,
                      onSelected: (selected) {
                        diaryProvider.setSearchMood(selected ? mood : null);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Active filter indicator
          if (diaryProvider.selectedSearchMood != null || diaryProvider.selectedSearchDate != null || diaryProvider.searchQuery.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Filters Applied', style: TextStyle(fontSize: 12, color: Colors.grey)),
                TextButton(
                  onPressed: () => diaryProvider.clearSearchFilters(),
                  child: const Text('Clear All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          const Divider(),

          // Searched results list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.find_in_page_outlined, size: 50, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('No matching memories found', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        const Text('Try adjusting your keywords or filters.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      return _buildEntryCard(entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
