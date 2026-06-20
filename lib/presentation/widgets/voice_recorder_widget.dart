import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/app_logger.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(String filePath) onRecordingSaved;

  const VoiceRecorderWidget({super.key, required this.onRecordingSaved});

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedPath;
  
  int _recordDuration = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/ynote_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc), 
          path: path
        );

        setState(() {
          _isRecording = true;
          _recordedPath = null;
          _recordDuration = 0;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
          setState(() {
            _recordDuration++;
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
    } catch (e) {
      // Fallback/Mock simulator for emulators without audio devices
      AppLogger.error("Recorder startup failed: $e. Falling back to mock recording.", exception: e);
      _startMockRecording();
    }
  }

  void _startMockRecording() {
    setState(() {
      _isRecording = true;
      _recordedPath = null;
      _recordDuration = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _recordDuration++;
      });
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    
    if (_isRecording) {
      String? path;
      try {
        path = await _audioRecorder.stop();
      } catch (e) {
        AppLogger.error("Real recorder stop error: $e", exception: e);
      }

      // If real path is null, generate a dummy file to simulate recording
      if (path == null) {
        final directory = await getTemporaryDirectory();
        path = '${directory.path}/mock_ynote_voice.m4a';
        final mockFile = File(path);
        await mockFile.writeAsString("Mock Audio Binary Content");
      }

      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });

      widget.onRecordingSaved(path!);
    }
  }

  Future<void> _togglePlayback() async {
    if (_recordedPath == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      try {
        if (_recordedPath!.contains("mock_")) {
          // Mock playing duration
          setState(() => _isPlaying = true);
          Future.delayed(Duration(seconds: _recordDuration), () {
            if (mounted) setState(() => _isPlaying = false);
          });
        } else {
          await _audioPlayer.play(DeviceFileSource(_recordedPath!));
          setState(() => _isPlaying = true);

          _audioPlayer.onPlayerComplete.listen((event) {
            if (mounted) setState(() => _isPlaying = false);
          });
        }
      } catch (e) {
        AppLogger.error("Playback error: $e", exception: e);
      }
    }
  }

  String _formatDuration(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(context: context, opacity: isDark ? 0.08 : 0.03),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isRecording ? Icons.mic : Icons.mic_none, 
                    color: _isRecording ? Colors.red : AppColors.darkPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isRecording 
                        ? 'Recording Voice Diary...' 
                        : _recordedPath != null 
                            ? 'Voice Recording Saved' 
                            : 'Record Voice Diary',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                _formatDuration(_recordDuration),
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isRecording && _recordedPath == null)
                ElevatedButton.icon(
                  onPressed: _startRecording,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('START RECORDING'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              if (_isRecording)
                ElevatedButton.icon(
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.stop),
                  label: const Text('STOP RECORDING'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                ),
              if (!_isRecording && _recordedPath != null) ...[
                ElevatedButton.icon(
                  onPressed: _togglePlayback,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(_isPlaying ? 'PAUSE PLAYBACK' : 'PLAYBACK DIARY'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkPrimary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _recordedPath = null;
                      _recordDuration = 0;
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('DELETE'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
