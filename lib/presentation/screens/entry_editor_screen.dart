import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/diary_entry.dart';
import '../../data/models/attachment.dart';
import '../providers/diary_provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/input_validator.dart';
import '../widgets/voice_recorder_widget.dart';

class EntryEditorScreen extends StatefulWidget {
  final DiaryEntry? entry; // Null if creating a new entry
  final DateTime? initialDate;

  const EntryEditorScreen({super.key, this.entry, this.initialDate});

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late DateTime _entryDate;
  String _selectedMood = 'Neutral';
  List<Attachment> _attachments = [];
  bool _isSaving = false;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _entryDate = widget.initialDate ?? widget.entry?.entryDate ?? DateTime.now();

    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _selectedMood = widget.entry!.mood;
      _attachments = List.from(widget.entry!.attachments);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // AI Feature: Analyze text contents for emotional sentiment and suggest a mood
  void _detectMoodFromText() {
    final text = _contentController.text.toLowerCase();
    String suggestedMood = 'Neutral';
    String explanation = "The text feels balanced and calm.";

    if (text.contains('happy') || text.contains('great') || text.contains('wonderful') || text.contains('love') || text.contains('awesome') || text.contains('good')) {
      suggestedMood = 'Happy';
      explanation = "We detected positive keywords indicating happiness! 😊";
    } else if (text.contains('excited') || text.contains('thrilled') || text.contains('amazing') || text.contains('party') || text.contains('celebrate')) {
      suggestedMood = 'Excited';
      explanation = "You seem high energy and thrilled about today! 😍";
    } else if (text.contains('sad') || text.contains('cry') || text.contains('lonely') || text.contains('hurt') || text.contains('miss') || text.contains('bad')) {
      suggestedMood = 'Sad';
      explanation = "The content reflects a somber, emotional state. 😔";
    } else if (text.contains('angry') || text.contains('mad') || text.contains('hate') || text.contains('annoyed') || text.contains('furious')) {
      suggestedMood = 'Angry';
      explanation = "We detected frustration or irritation in your words. 😡";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: AppColors.darkPrimary),
            SizedBox(width: 8),
            Text('AI Mood Detector'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(explanation),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    AppColors.moodEmojis[suggestedMood]!,
                    style: const TextStyle(fontSize: 48),
                  ),
                  Text(
                    'Suggested: $suggestedMood',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DISMISS'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedMood = suggestedMood;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkPrimary, foregroundColor: Colors.white),
            child: const Text('APPLY MOOD'),
          ),
        ],
      ),
    );
  }

  // Pick image attachment
  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _attachments.add(Attachment(
          filePath: image.path,
          fileType: 'image',
        ));
      });
    }
  }

  // Pick Document attachment
  Future<void> _pickDocument() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _attachments.add(Attachment(
          filePath: result.files.single.path!,
          fileType: 'document',
        ));
      });
    }
  }

  // Voice recording saved callback
  void _onVoiceRecordingSaved(String filePath) {
    setState(() {
      _attachments.add(Attachment(
        filePath: filePath,
        fileType: 'audio',
      ));
    });

    // AI Feature: Speech to Text Mock
    // Add transcription block to text content
    _simulateSpeechToText();
  }

  void _simulateSpeechToText() {
    // Appends a mock text transcript block of the voice recording into the diary
    final timestamp = DateFormat('jm').format(DateTime.now());
    const mockTranscript = "\n\n*🎤 Speech-to-Text Transcription ($timestamp):*\n\"Wrote about my day today, logging my secure thoughts into YNote. Ensuring everything remains private on this encrypted database. Feeling accomplished and ready for tomorrow.\"";
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mic, color: AppColors.darkPrimary),
            SizedBox(width: 8),
            Text('Speech to Text AI'),
          ],
        ),
        content: const Text(
          'Your voice diary has been parsed. Would you like to append the automated transcript to your journal content?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('SKIP'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _contentController.text += mockTranscript;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkPrimary, colorScheme: const ColorScheme.dark(primary: AppColors.darkPrimary)),
            child: const Text('APPEND'),
          ),
        ],
      ),
    );
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);

    try {
      if (widget.entry == null) {
        // Create new
        await diaryProvider.addEntry(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          mood: _selectedMood,
          entryDate: _entryDate,
          attachments: _attachments,
        );
      } else {
        // Update existing
        final updated = widget.entry!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          mood: _selectedMood,
          entryDate: _entryDate,
          attachments: _attachments,
        );
        await diaryProvider.updateEntry(updated);
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save journal: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.entry == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Journal'),
        content: const Text('Are you sure you want to permanently delete this diary entry? This action is irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isSaving = true);
      await Provider.of<DiaryProvider>(context, listen: false).deleteEntry(widget.entry!.id!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'New Thought' : 'Edit Journal'),
        actions: [
          if (widget.entry != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _isSaving ? null : _delete,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: SafeArea(
        child: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Entry Date & Mood row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Date picker trigger
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _entryDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  _entryDate = picked;
                                });
                              }
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, color: AppColors.darkPrimary),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('EEEE, MMMM d, yyyy').format(_entryDate),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          
                          // AI Mood detection button
                          IconButton(
                            icon: const Icon(Icons.psychology, color: AppColors.darkPrimary),
                            tooltip: 'Detect mood from text using AI',
                            onPressed: _detectMoodFromText,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Mood Selector Grid
                      const Text(
                        'How are you feeling?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: AppColors.moodEmojis.keys.map((mood) {
                          final emoji = AppColors.moodEmojis[mood]!;
                          final isSelected = _selectedMood == mood;
                          final color = AppColors.moodColors[mood]!;

                          return GestureDetector(
                            onTap: () => setState(() => _selectedMood = mood),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? color.withAlpha(51) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected 
                                    ? Border.all(color: color, width: 2)
                                    : Border.all(color: Colors.transparent, width: 2),
                              ),
                              child: Column(
                                children: [
                                  Text(emoji, style: const TextStyle(fontSize: 28)),
                                  const SizedBox(height: 4),
                                  Text(
                                    mood,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? color : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Journal Title
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87),
                        validator: InputValidator.entryTitle,
                        decoration: InputDecoration(
                          hintText: 'Give your entry a title...',
                          hintStyle: const TextStyle(fontSize: 18, color: Colors.grey),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                      const Divider(),

                      // Journal Text Box
                      TextFormField(
                        controller: _contentController,
                        maxLines: null,
                        minLines: 8,
                        style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
                        validator: InputValidator.entryContent,
                        decoration: const InputDecoration(
                          hintText: 'Share your thoughts, secrets, goals...',
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Voice Recording Module
                      VoiceRecorderWidget(onRecordingSaved: _onVoiceRecordingSaved),
                      const SizedBox(height: 20),

                      // Attached items row
                      if (_attachments.isNotEmpty) ...[
                        const Text('Attachments', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_attachments.length, (index) {
                            final att = _attachments[index];
                            IconData icon;
                            Color color;

                            if (att.fileType == 'image') {
                              icon = Icons.image_outlined;
                              color = Colors.blue;
                            } else if (att.fileType == 'audio') {
                              icon = Icons.mic_none;
                              color = Colors.red;
                            } else {
                              icon = Icons.description_outlined;
                              color = Colors.green;
                            }

                            return Chip(
                              avatar: Icon(icon, color: color, size: 18),
                              label: Text(
                                att.filePath.split('/').last,
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onDeleted: () => _removeAttachment(index),
                            );
                          }),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Attachment add buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('Add Photo'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickDocument,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Attach File'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
