import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/diary_provider.dart';
import '../../core/constants/app_theme.dart';

class MoodAnalyticsScreen extends StatefulWidget {
  const MoodAnalyticsScreen({super.key});

  @override
  State<MoodAnalyticsScreen> createState() => _MoodAnalyticsScreenState();
}

class _MoodAnalyticsScreenState extends State<MoodAnalyticsScreen> {
  int _focusedYear = DateTime.now().year;
  int _focusedMonth = DateTime.now().month;
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final diaryProvider = Provider.of<DiaryProvider>(context);
    final stats = diaryProvider.getMoodStatisticsForMonth(_focusedMonth, _focusedYear);
    final totalEntries = stats.values.fold(0, (sum, val) => sum + val);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine the most common mood
    String dominantMood = "None";
    int maxCount = 0;
    stats.forEach((key, value) {
      if (value > maxCount) {
        maxCount = value;
        dominantMood = key;
      }
    });

    final String dominantEmoji = AppColors.moodEmojis[dominantMood] ?? '📝';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month navigation selector card
          _buildMonthSelector(),
          const SizedBox(height: 16),

          // Chart Card
          totalEntries == 0
              ? _buildEmptyState()
              : Card(
                  elevation: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassDecoration(context: context, opacity: isDark ? 0.05 : 0.02),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mood Breakdown',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        // Pie Chart Layout
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 4,
                              centerSpaceRadius: 40,
                              sections: _generateChartSections(stats, totalEntries),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Legend List
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: stats.keys.where((k) => stats[k]! > 0).map((mood) {
                            final count = stats[mood]!;
                            final pct = ((count / totalEntries) * 100).toStringAsFixed(1);
                            final color = AppColors.moodColors[mood]!;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                                ),
                                const SizedBox(width: 4),
                                Text('$mood ($pct%)', style: const TextStyle(fontSize: 12)),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 16),

          // Sentiment Insights Card
          if (totalEntries > 0)
            Card(
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassDecoration(context: context, opacity: isDark ? 0.05 : 0.02),
                child: Row(
                  children: [
                    Text(dominantEmoji, style: const TextStyle(fontSize: 40)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Sentiment Summary',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dominantMood == "None" 
                                ? 'No entries recorded for this month.'
                                : 'You recorded $totalEntries memories. Your dominant emotional tone was $dominantMood ($maxCount log(s)). Keep expressing yourself in Diaro!',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Mood History Timeline list
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              'Timeline History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 12),
          _buildMoodTimeline(diaryProvider),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final date = DateTime(_focusedYear, _focusedMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () {
            setState(() {
              if (_focusedMonth == 1) {
                _focusedMonth = 12;
                _focusedYear--;
              } else {
                _focusedMonth--;
              }
            });
          },
        ),
        Text(
          DateFormat('MMMM yyyy').format(date),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            setState(() {
              if (_focusedMonth == 12) {
                _focusedMonth = 1;
                _focusedYear++;
              } else {
                _focusedMonth++;
              }
            });
          },
        ),
      ],
    );
  }

  List<PieChartSectionData> _generateChartSections(Map<String, int> stats, int total) {
    int index = 0;
    List<PieChartSectionData> sections = [];
    
    stats.forEach((mood, count) {
      if (count > 0) {
        final isTouched = index == _touchedIndex;
        final fontSize = isTouched ? 18.0 : 12.0;
        final radius = isTouched ? 60.0 : 50.0;
        final color = AppColors.moodColors[mood]!;
        final emoji = AppColors.moodEmojis[mood]!;

        sections.add(
          PieChartSectionData(
            color: color,
            value: count.toDouble(),
            title: emoji,
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
      index++;
    });

    return sections;
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: const Column(
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No Data Available', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Log entries with moods to build your analytics charts!', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodTimeline(DiaryProvider diaryProvider) {
    final monthlyEntries = diaryProvider.entries.where((entry) =>
        entry.entryDate.month == _focusedMonth && entry.entryDate.year == _focusedYear).toList();

    if (monthlyEntries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No timeline entries for this month.', style: TextStyle(color: Colors.grey))),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: monthlyEntries.length,
      itemBuilder: (context, index) {
        final entry = monthlyEntries[index];
        final emoji = AppColors.moodEmojis[entry.mood] ?? '😐';
        final color = AppColors.moodColors[entry.mood] ?? Colors.purple;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line & node
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                if (index < monthlyEntries.length - 1)
                  Container(
                    width: 2,
                    height: 50,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Timeline content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('E, MMM d').format(entry.entryDate),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$emoji ${entry.title}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
