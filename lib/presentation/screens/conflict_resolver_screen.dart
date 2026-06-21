import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_theme.dart';
import '../../data/models/diary_entry.dart';
import '../providers/diary_provider.dart';

class ConflictResolverScreen extends StatelessWidget {
  final DiaryEntry original;
  final DiaryEntry conflict;

  const ConflictResolverScreen({
    super.key,
    required this.original,
    required this.conflict,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolve Conflict'),
        backgroundColor: Colors.orange.shade800,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.orange.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Two versions of this entry exist. Please select how you want to resolve this conflict.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildVersionCard(
                  context: context,
                  title: 'Original Version',
                  entry: original,
                  color: Colors.blue.shade100,
                  icon: Icons.cloud_done_outlined,
                  onSelect: () => _resolve(context, 'KEEP_ORIGINAL'),
                ),
                const SizedBox(height: 16),
                _buildVersionCard(
                  context: context,
                  title: 'Conflict Version',
                  entry: conflict,
                  color: Colors.orange.shade100,
                  icon: Icons.sync_problem,
                  onSelect: () => _resolve(context, 'KEEP_CONFLICT'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _resolve(context, 'KEEP_BOTH'),
              icon: const Icon(Icons.call_split),
              label: const Text('Keep Both as Separate Entries'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionCard({
    required BuildContext context,
    required String title,
    required DiaryEntry entry,
    required Color color,
    required IconData icon,
    required VoidCallback onSelect,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d, h:mm a').format(entry.updatedAt ?? entry.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Divider(),
            Text(
              entry.title.replaceAll(' (Conflict Copy - Mobile)', ''),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              entry.content,
              style: const TextStyle(fontSize: 14),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSelect,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : Colors.black,
                  side: BorderSide(color: isDark ? Colors.white54 : Colors.black54),
                ),
                child: const Text('Keep This Version'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resolve(BuildContext context, String resolution) async {
    final provider = Provider.of<DiaryProvider>(context, listen: false);
    await provider.resolveConflict(original, conflict, resolution);
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conflict resolved successfully.')),
      );
    }
  }
}
