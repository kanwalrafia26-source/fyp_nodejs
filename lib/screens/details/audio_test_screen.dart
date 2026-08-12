import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/api_service.dart';

/// Standalone test screen for Modules 1–3 (Audio Input, Speech-to-Text,
/// Fluency Analysis).
///
/// Flow: record → stop → transcription starts automatically → transcript +
/// fluency results appear below the (still-visible) playback/retry controls.
class AudioTestScreen extends StatefulWidget {
  const AudioTestScreen({super.key});

  @override
  State<AudioTestScreen> createState() => _AudioTestScreenState();
}

enum _RecState { idle, recording, recorded, playing }

class _AudioTestScreenState extends State<AudioTestScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  _RecState _state = _RecState.idle;
  String? _filePath;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  late final AnimationController _pulseCtrl;

  bool _isTranscribing = false;
  String? _transcript;
  int? _wordCount;
  int? _wpm;
  int? _longPauseCount;
  double? _totalPauseSeconds;
  int? _fillerWordCount;
  String? _paceStability;
  int? _fluencyScore;
  String? _uploadError;

  static const Color kBg       = Color(0xFF1A0535);
  static const Color kCardBg   = Color(0xFF2D0A52);
  static const Color kPrimary  = Color(0xFF5300AC);
  static const Color kYellow   = Color(0xFFCDCC58);
  static const Color kSubtitle = Color(0xFFC097D8);
  static const Color kStopBg   = Color(0xFF6B1A2A);
  static const Color kStopText = Color(0xFFFF6B6B);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseCtrl.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required.')),
        );
      }
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/speakora_test_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: path);

    setState(() {
      _state = _RecState.recording;
      _filePath = path;
      _elapsed = Duration.zero;
      _transcript = null;
      _uploadError = null;
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _stopRecording() async {
    _ticker?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _state = _RecState.recorded;
      _filePath = path ?? _filePath;
    });
    _uploadForAnalysis();
  }

  Future<void> _playRecording() async {
    if (_filePath == null) return;
    setState(() => _state = _RecState.playing);
    await _player.play(DeviceFileSource(_filePath!));
    _player.onPlayerComplete.first.then((_) {
      if (mounted) setState(() => _state = _RecState.recorded);
    });
  }

  void _resetRecording() {
    setState(() {
      _state = _RecState.idle;
      _filePath = null;
      _elapsed = Duration.zero;
      _isTranscribing = false;
      _transcript = null;
      _wordCount = null;
      _wpm = null;
      _longPauseCount = null;
      _totalPauseSeconds = null;
      _fillerWordCount = null;
      _paceStability = null;
      _fluencyScore = null;
      _uploadError = null;
    });
  }

  Future<void> _uploadForAnalysis() async {
    if (_filePath == null) return;
    setState(() {
      _isTranscribing = true;
      _uploadError = null;
    });

    try {
      final result = await ApiService.transcribeAudio(_filePath!);
      if (!mounted) return;
      setState(() {
        _transcript = result['transcript'] as String? ?? '';
        _wordCount = result['wordCount'] as int?;
        _wpm = result['wpm'] as int?;
        _longPauseCount = result['longPauseCount'] as int?;
        _totalPauseSeconds = (result['totalPauseSeconds'] as num?)?.toDouble();
        _fillerWordCount = result['fillerWordCount'] as int?;
        _paceStability = result['paceStability'] as String?;
        _fluencyScore = result['fluencyScore'] as int?;
        _isTranscribing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadError = e.toString().replaceFirst('Exception: ', '');
        _isTranscribing = false;
      });
    }
  }

  String get _timeLabel {
    final m = _elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final hasRecording =
        _state == _RecState.recorded || _state == _RecState.playing;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: const Text(
          'Audio Pipeline Test',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                'Modules 1–3 — Audio, Transcription & Fluency',
                style: TextStyle(fontSize: 13, color: kSubtitle),
              ),
              const SizedBox(height: 4),
              const Text(
                'Record → auto-transcribe → fluency analysis',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF7A50A0)),
              ),
              const SizedBox(height: 40),

              // ── Mic circle ──────────────────────────────────────
              GestureDetector(
                onTap: _state == _RecState.idle
                    ? _startRecording
                    : _state == _RecState.recording
                        ? _stopRecording
                        : null,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) {
                    final scale = _state == _RecState.recording
                        ? 1.0 + 0.08 * sin(_pulseCtrl.value * pi)
                        : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _state == _RecState.recording
                              ? kStopBg
                              : kPrimary,
                          border: Border.all(
                            color: kYellow.withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _state == _RecState.recording
                              ? Icons.stop_rounded
                              : _state == _RecState.playing
                                  ? Icons.graphic_eq_rounded
                                  : Icons.mic_rounded,
                          color: _state == _RecState.recording
                              ? kStopText
                              : Colors.white,
                          size: 52,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              Text(
                _state == _RecState.idle
                    ? 'Tap to start recording'
                    : _state == _RecState.recording
                        ? _timeLabel
                        : _state == _RecState.playing
                            ? 'Playing...'
                            : 'Recording complete',
                style: TextStyle(
                  fontSize: _state == _RecState.recording ? 32 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              if (hasRecording) ...[
                // File saved card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FILE SAVED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: kSubtitle,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _filePath?.split('/').last ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Play / Retry
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _state == _RecState.playing
                            ? null
                            : _playRecording,
                        icon: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white),
                        label: const Text('Play back',
                            style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: kSubtitle),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetRecording,
                        icon: const Icon(Icons.refresh_rounded,
                            color: kStopText),
                        label: const Text('Retry',
                            style: TextStyle(color: kStopText)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kStopText),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Transcription status / results
                if (_isTranscribing)
                  const Column(
                    children: [
                      CircularProgressIndicator(color: kYellow),
                      SizedBox(height: 12),
                      Text(
                        'Transcribing (local Whisper)...',
                        style: TextStyle(fontSize: 13, color: kSubtitle),
                      ),
                    ],
                  )
                else if (_uploadError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kStopBg.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _uploadError!,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 12, color: kStopText),
                    ),
                  )
                else if (_transcript != null)
                  Column(
                    children: [
                      if (_fluencyScore != null) ...[
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: kCardBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$_fluencyScore',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: _fluencyScore! >= 70
                                      ? const Color(0xFF61EF8E)
                                      : _fluencyScore! >= 45
                                          ? kYellow
                                          : kStopText,
                                ),
                              ),
                              const Text(
                                'Fluency score',
                                style: TextStyle(
                                    fontSize: 11, color: kSubtitle),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kCardBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TRANSCRIPT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: kSubtitle,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _transcript!.isNotEmpty
                                  ? _transcript!
                                  : '(no speech detected)',
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  height: 1.5),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _StatPill(
                                    label: 'Words',
                                    value: '${_wordCount ?? 0}'),
                                const SizedBox(width: 8),
                                _StatPill(
                                    label: 'WPM',
                                    value: '${_wpm ?? 0}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _StatPill(
                                    label: 'Long pauses',
                                    value: '${_longPauseCount ?? 0}'),
                                const SizedBox(width: 8),
                                _StatPill(
                                    label: 'Fillers',
                                    value: '${_fillerWordCount ?? 0}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _StatPill(
                                    label: 'Silence (s)',
                                    value: _totalPauseSeconds
                                            ?.toStringAsFixed(1) ??
                                        '0'),
                                const SizedBox(width: 8),
                                _StatPill(
                                    label: 'Pace',
                                    value: _paceStability ?? '—'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFFCDCC58),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFFC097D8)),
            ),
          ],
        ),
      ),
    );
  }
}
