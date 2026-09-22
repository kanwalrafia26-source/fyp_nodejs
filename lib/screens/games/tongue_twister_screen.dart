import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'tongue_twister_result_screen.dart';
import 'tongue_twister_fail_screen.dart';
import '../../core/app_nav.dart';
import '../../services/api_service.dart';

class TongueTwisterScreen extends StatefulWidget {
  const TongueTwisterScreen({super.key});

  @override
  State<TongueTwisterScreen> createState() => _TongueTwisterScreenState();
}

class _TongueTwisterScreenState extends State<TongueTwisterScreen>
    with TickerProviderStateMixin {
  int  _attempt   = 0; // 0-based
  int  _navIndex  = 1;
  bool _isRecording  = false;
  bool _isAnalyzing  = false;
  bool _hasPermission = false;
  int  _timerSecs = 8;
  Timer? _countdownTimer;

  late AnimationController _waveCtrl;
  late AnimationController _pulseCtrl;

  final AudioRecorder _recorder = AudioRecorder();

  // Per-attempt results (up to 3).
  // Each entry: { score (0–100), lowConfidenceWords: List<String>, hasRealData }
  final List<Map<String, dynamic>> _attempts = [];

  static const Color kBg       = Color(0xFF290451);
  static const Color kCardBg   = Color(0xFF3D0870);
  static const Color kDarkCard = Color(0xFF1E0340);
  static const Color kPrimary  = Color(0xFF5300AC);
  static const Color kYellow   = Color(0xFFD9E366);
  static const Color kYellowDk = Color(0xFF2F0A56);
  static const Color kSubtitle = Color(0xFF9A70B0);
  static const Color kNavActive= Color(0xFFD9E366);
  static const Color kNavInact = Color(0xFF7A50A0);

  static const List<String> _twisters = [
    '"Red lorry,\nyellow lorry."',
    '"She sells seashells\nby the seashore."',
    '"How much wood would\na woodchuck chuck."',
  ];
  int _twisterIndex = 0;

  static const int _maxAttempts = 3;
  static const int _passMark    = 65; // % to pass

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final ok = await _recorder.hasPermission();
      if (mounted) setState(() => _hasPermission = ok);
    } catch (_) {}
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _pulseCtrl.dispose();
    _countdownTimer?.cancel();
    if (_isRecording) _recorder.stop();
    _recorder.dispose();
    super.dispose();
  }

  // ── Start one attempt ──────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    if (!_hasPermission) {
      await _checkPermission();
      if (!_hasPermission) return;
    }
    try {
      final dir  = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/tt_a${_attempt}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      setState(() {
        _isRecording = true;
        _timerSecs   = 8;
      });
      // Auto-stop after 8 seconds
      _countdownTimer =
          Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        if (_timerSecs > 1) {
          setState(() => _timerSecs--);
        } else {
          t.cancel();
          _stopAndAnalyse();
        }
      });
    } catch (_) {}
  }

  // ── Stop, analyse, decide ──────────────────────────────────────────────────
  Future<void> _stopAndAnalyse() async {
    _countdownTimer?.cancel();
    setState(() { _isRecording = false; _isAnalyzing = true; });

    Map<String, dynamic>? analysis;
    try {
      final path = await _recorder.stop();
      if (path != null) {
        analysis = await ApiService.transcribeAudio(path);
      }
    } catch (_) {}

    final score = (analysis?['pronunciationScore'] as num?)?.toInt() ?? 0;
    final lowWords = (analysis?['lowConfidenceWords'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    _attempts.add({
      'score':             score,
      'lowConfidenceWords': lowWords,
      'hasRealData':       analysis != null,
    });

    if (mounted) setState(() => _isAnalyzing = false);

    if (_attempt < _maxAttempts - 1) {
      // More attempts available
      setState(() => _attempt++);
    } else {
      _finish();
    }
  }

  void _finish() {
    final hasReal = _attempts.any((a) => a['hasRealData'] == true);
    final best    = _attempts.isEmpty
        ? 0
        : _attempts
            .map((a) => a['score'] as int)
            .fold(0, (a, b) => a > b ? a : b);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => best >= _passMark
            ? TongueTwisterResultScreen(
                attempts: _attempts,
                bestScore: best,
                hasRealData: hasReal,
              )
            : TongueTwisterFailScreen(
                attempts: _attempts,
                bestScore: best,
                hasRealData: hasReal,
              ),
      ),
    );
  }

  int? _scoreForAttempt(int i) =>
      i < _attempts.length ? _attempts[i]['score'] as int? : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  // ── Header ─────────────────────────────────────────
                  _buildHeader(),

                  const SizedBox(height: 16),

                  // ── Twister card ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        color: kCardBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _twisters[_twisterIndex],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Dot indicators ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => Container(
                      width: i == _twisterIndex ? 10 : 8,
                      height: i == _twisterIndex ? 10 : 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _twisterIndex
                            ? kYellow
                            : Colors.white.withOpacity(0.25),
                      ),
                    )),
                  ),

                  const SizedBox(height: 24),

                  // ── Record button ──────────────────────────────────
                  Column(
                    children: [
                      SizedBox(
                        width: 130, height: 130,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseCtrl,
                              builder: (_, __) {
                                final s = _isRecording
                                    ? 1.0 + 0.08 * sin(_pulseCtrl.value * pi)
                                    : 1.0;
                                return Transform.scale(
                                  scale: s,
                                  child: Container(
                                    width: 120, height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: kYellow.withOpacity(0.6),
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            GestureDetector(
                              onTap: (_isAnalyzing || _attempt >= _maxAttempts)
                                  ? null
                                  : (_isRecording
                                      ? _stopAndAnalyse
                                      : _startRecording),
                              child: Container(
                                width: 88, height: 88,
                                decoration: BoxDecoration(
                                  color: _isRecording
                                      ? Colors.redAccent
                                      : kPrimary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isRecording
                                      ? Icons.stop_rounded
                                      : Icons.mic_rounded,
                                  color: const Color(0xFFE6BEF0),
                                  size: 38,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isAnalyzing
                            ? 'Analysing...'
                            : (_isRecording
                                ? 'Tap to stop'
                                : (_hasPermission
                                    ? 'Tap to record'
                                    : 'Grant mic permission')),
                        style: const TextStyle(
                            fontSize: 12, color: kSubtitle),
                      ),
                      const SizedBox(height: 14),
                      AnimatedBuilder(
                        animation: _waveCtrl,
                        builder: (_, __) => CustomPaint(
                          size: Size(
                              MediaQuery.of(context).size.width * 0.55,
                              44),
                          painter: _WaveformPainter(
                            progress: _waveCtrl.value,
                            color: kYellow,
                            active: _isRecording,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Attempts card ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: kDarkCard,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ATTEMPT ${_attempt + 1} OF $_maxAttempts',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: kYellow,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: List.generate(3, (i) {
                              final score = _scoreForAttempt(i);
                              final done  = score != null;
                              return Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(
                                      right: i < 2 ? 10 : 0),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  decoration: BoxDecoration(
                                    color: done
                                        ? kPrimary
                                        : Colors.white
                                            .withOpacity(0.06),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        done ? '$score%' : '—',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: done
                                              ? kYellow
                                              : Colors.white
                                                  .withOpacity(0.2),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        done
                                            ? 'Accuracy'
                                            : 'Attempt ${i + 1}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: done
                                              ? const Color(
                                                  0xFFE6BEF0)
                                              : kSubtitle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ── Analysing overlay ──────────────────────────────────────
            if (_isAnalyzing)
              Container(
                color: Colors.black.withOpacity(0.55),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: kYellow),
                      SizedBox(height: 14),
                      Text('Scoring attempt...',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Level 3 · Intermediate',
                    style: TextStyle(
                        fontSize: 13, color: kSubtitle)),
                SizedBox(height: 2),
                Text('Tongue Twister',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: kDarkCard,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              children: [
                Text(
                  _isRecording
                      ? _timerSecs.toString().padLeft(2, '0')
                      : '08',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: kYellow,
                    height: 1.0,
                  ),
                ),
                const Text('seconds',
                    style: TextStyle(
                        fontSize: 10, color: kSubtitle)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: kYellow,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Text('Level 1',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kYellowDk,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      (Icons.home_outlined,          'Home'),
      (Icons.show_chart_rounded,     'Progress'),
      (Icons.headset_mic_outlined,   'Support'),
      (Icons.person_outline_rounded, 'Profile'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: kDarkCard,
        border: Border(
          top: BorderSide(
              color: Colors.white.withOpacity(0.08), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = _navIndex == i;
          final color  = active ? kNavActive : kNavInact;
          return GestureDetector(
            onTap: () => navigateTo(context, i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(items[i].$1, color: color, size: 22),
                const SizedBox(height: 3),
                Text(items[i].$2,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w400,
                      color: color,
                    )),
                if (active) ...[
                  const SizedBox(height: 2),
                  Container(
                    width: 4, height: 4,
                    decoration: const BoxDecoration(
                        color: kNavActive, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool active;

  static const List<double> _h = [
    0.3, 0.5, 0.7, 0.9, 0.6, 1.0, 0.75, 0.5,
    0.85, 0.6, 0.4, 0.7, 0.5, 0.35, 0.65, 0.45,
  ];

  const _WaveformPainter(
      {required this.progress, required this.color, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final count = _h.length;
    final barW  = (size.width * 0.038).clamp(3.0, 8.0);
    final gap   = (size.width - count * barW) / (count - 1);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < count; i++) {
      final phase   = active ? (progress + i / count) % 1.0 : 0.5;
      final anim    = active ? 0.65 + 0.35 * sin(phase * 2 * pi) : 0.3;
      final h       = _h[i] * size.height * anim;
      final x       = i * (barW + gap);
      final y       = (size.height - h) / 2;
      final opacity = 0.3 + 0.7 * sin(i / (count - 1) * pi);
      paint.color =
          color.withOpacity((active ? opacity : 0.3).clamp(0.0, 1.0));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, barW, h), const Radius.circular(3)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.active != active;
}
