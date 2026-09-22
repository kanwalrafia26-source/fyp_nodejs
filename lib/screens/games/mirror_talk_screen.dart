import 'dart:math';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'mirror_talk_result_screen.dart';
import 'mirror_talk_fail_screen.dart';
import '../../core/app_nav.dart';
import '../../services/api_service.dart';

class MirrorTalkScreen extends StatefulWidget {
  const MirrorTalkScreen({super.key});

  @override
  State<MirrorTalkScreen> createState() => _MirrorTalkScreenState();
}

class _MirrorTalkScreenState extends State<MirrorTalkScreen>
    with TickerProviderStateMixin {
  int _round       = 1;
  static const int _totalRounds = 5;
  int _navIndex    = 1;

  // ── Real audio pipeline ───────────────────────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording    = false;
  bool _isAnalyzing    = false;
  bool _hasPermission  = false;

  // Per-round results — collected as we go, passed to result screens at end.
  // Each entry: { emotion, expressionScore (0–100), fluencyScore, wpm, anxietyScore }
  final List<Map<String, dynamic>> _roundResults = [];

  late AnimationController _waveCtrl;
  late AnimationController _pulseCtrl;

  // ── Colours ────────────────────────────────────────────────────────────────
  static const Color kBg        = Color(0xFF350065);
  static const Color kHeaderBg  = Color(0xFF1E0040);
  static const Color kCardBg    = Color(0xFF5300AC);
  static const Color kDarkCard  = Color(0xFF220046);
  static const Color kYellow    = Color(0xFFD9E366);
  static const Color kYellowDark= Color(0xFF1A2000);
  static const Color kSubtitle  = Color(0xFF7A50A0);
  static const Color kNavActive = Color(0xFFD9E366);
  static const Color kNavInact  = Color(0xFF5A3A70);
  static const Color kAvatarBg  = Color(0xFF5300AC);
  static const Color kGreen     = Color(0xFF5A9040);

  static const List<String> _prompts = [
    '"Tell me about your best\nday ever."',
    '"Describe your favourite\nplace in the world."',
    '"What makes you feel\nmost confident?"',
    '"Talk about a challenge\nyou overcame."',
    '"Share something that\nmakes you laugh."',
  ];

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
    if (_isRecording) _recorder.stop();
    _recorder.dispose();
    super.dispose();
  }

  // ── Start recording for current round ──────────────────────────────────────
  Future<void> _startRecording() async {
    if (!_hasPermission) {
      await _checkPermission();
      if (!_hasPermission) return;
    }
    try {
      final dir  = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/mirror_r${_round}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      if (mounted) setState(() => _isRecording = true);
    } catch (_) {}
  }

  // ── Stop recording, analyse, then advance or finish ─────────────────────────
  Future<void> _stopAndAnalyse() async {
    setState(() { _isRecording = false; _isAnalyzing = true; });

    Map<String, dynamic>? analysis;
    try {
      final path = await _recorder.stop();
      if (path != null) {
        analysis = await ApiService.transcribeAudio(path);
      }
    } catch (_) {}

    // Build a result entry for this round.
    final emotion = analysis?['emotionLabel'] as String? ?? '—';
    // Use anxiety score to derive an "expression" score: higher anxiety → more
    // expressive detection. Scale it as (100 – anxiety)*0.4 + fluency*0.6 so
    // the score rewards both fluency and some emotional presence.
    final fluency  = (analysis?['fluencyScore']  as num?)?.toInt() ?? 0;
    final anxiety  = (analysis?['anxietyScore']  as num?)?.toInt() ?? 0;
    final wpm      = (analysis?['wpm']           as num?)?.toInt() ?? 0;
    final pitchCV  = (analysis?['pitchVariability'] as num?)?.toDouble() ?? 0.0;

    // Expression score: blend of fluency and emotional variability (pitch CV
    // scaled 0–1 capped at 0.3 cv → full credit).
    final expressionScore = analysis == null
        ? 0
        : ((fluency * 0.6) + (pitchCV / 0.3).clamp(0.0, 1.0) * 40)
            .round()
            .clamp(0, 100);

    _roundResults.add({
      'emotion':         emotion,
      'expressionScore': expressionScore,
      'fluencyScore':    fluency,
      'anxietyScore':    anxiety,
      'wpm':             wpm,
      'hasRealData':     analysis != null,
    });

    if (mounted) setState(() => _isAnalyzing = false);

    if (_round < _totalRounds) {
      if (mounted) setState(() => _round++);
    } else {
      _finish();
    }
  }

  void _finish() {
    final avgExpression = _roundResults.isEmpty
        ? 0
        : _roundResults
                .map((r) => r['expressionScore'] as int)
                .fold<int>(0, (a, b) => a + b) ~/
            _roundResults.length;

    final hasReal =
        _roundResults.any((r) => r['hasRealData'] == true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => avgExpression >= 50
            ? MirrorTalkResultScreen(
                roundResults: _roundResults,
                overallScore: avgExpression,
                hasRealData: hasReal,
              )
            : MirrorTalkFailScreen(
                roundResults: _roundResults,
                overallScore: avgExpression,
                hasRealData: hasReal,
              ),
      ),
    );
  }

  // Current round result (if analysed)
  Map<String, dynamic>? get _currentResult =>
      _roundResults.length >= _round ? _roundResults[_round - 1] : null;

  String get _detectedEmotion =>
      _currentResult?['emotion'] as String? ?? '—';
  int get _expressionPct =>
      _currentResult?['expressionScore'] as int? ?? 0;

  @override
  Widget build(BuildContext context) {
    final progress = _round / _totalRounds;
    final roundDone = _roundResults.length >= _round;

    return Scaffold(
      backgroundColor: kBg,
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ───────────────────────────────────────
                  Container(
                    width: double.infinity,
                    color: kHeaderBg,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Game 1 · Mirror Talk',
                                style: TextStyle(
                                    fontSize: 12, color: kSubtitle)),
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: kYellow.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: kYellow.withOpacity(0.25),
                                    width: 1.5),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('$_round',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: kYellow,
                                        height: 1.0,
                                      )),
                                  const Text('of 5',
                                      style: TextStyle(
                                          fontSize: 10, color: kSubtitle)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text('Speak it.',
                            style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.48)),
                        const Text('Feel it.',
                            style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.48)),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor:
                                Colors.white.withOpacity(0.08),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(kYellow),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Prompt card ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                      decoration: BoxDecoration(
                        color: kCardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFE6BEF0).withOpacity(0.4),
                            width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOUR PROMPT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: kSubtitle,
                                letterSpacing: 1.0,
                              )),
                          const SizedBox(height: 6),
                          Text(_prompts[_round - 1],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.5,
                              )),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Emotion / waveform card ────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: kDarkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFE6BEF0).withOpacity(0.1),
                            width: 1),
                      ),
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (_, __) => Transform.scale(
                              scale: 1.0 +
                                  0.04 * sin(_pulseCtrl.value * pi),
                              child: _buildAvatar(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text('Detected emotion',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: kSubtitle)),
                                  const SizedBox(height: 2),
                                  Text(
                                    roundDone
                                        ? _detectedEmotion
                                        : (_isRecording
                                            ? 'Listening...'
                                            : 'Waiting...'),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    roundDone
                                        ? '$_expressionPct%'
                                        : '—',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: kYellow,
                                      height: 1.0,
                                    ),
                                  ),
                                  const Text('expression',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: kSubtitle)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: LinearProgressIndicator(
                              value: roundDone
                                  ? _expressionPct / 100
                                  : 0.0,
                              minHeight: 7,
                              backgroundColor:
                                  Colors.white.withOpacity(0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  kYellow.withOpacity(0.85)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          AnimatedBuilder(
                            animation: _waveCtrl,
                            builder: (_, __) => CustomPaint(
                              size: Size(
                                  MediaQuery.of(context).size.width - 80,
                                  48),
                              painter: _WaveformPainter(
                                progress: _waveCtrl.value,
                                color: kYellow,
                                active: _isRecording,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Stars + XP ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        ...List.generate(5, (i) {
                          final filled = roundDone
                              ? i < _starsForScore(_expressionPct)
                              : false;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              filled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: filled
                                  ? kYellow
                                  : kYellow.withOpacity(0.25),
                              size: 26,
                            ),
                          );
                        }),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: kYellow.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: kYellow.withOpacity(0.25),
                                width: 1.5),
                          ),
                          child: const Text('+30 XP',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kYellow,
                              )),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Record / Next button ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isAnalyzing
                            ? null
                            : (roundDone
                                ? (_round < _totalRounds
                                    ? () => setState(() {})
                                    : _finish)
                                : (_isRecording
                                    ? _stopAndAnalyse
                                    : _startRecording)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isRecording ? Colors.redAccent : kYellow,
                          foregroundColor: kYellowDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _isAnalyzing
                              ? 'Analysing...'
                              : (roundDone
                                  ? (_round < _totalRounds
                                      ? 'Next round →'
                                      : 'Finish  ✓')
                                  : (_isRecording
                                      ? '⏹  Stop & analyse'
                                      : (_hasPermission
                                          ? '🎙  Start speaking'
                                          : 'Grant mic permission'))),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Analysing overlay ─────────────────────────────────────
            if (_isAnalyzing)
              Container(
                color: Colors.black.withOpacity(0.55),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: kYellow),
                      SizedBox(height: 14),
                      Text('Analysing round...',
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

  int _starsForScore(int score) {
    if (score >= 80) return 5;
    if (score >= 65) return 4;
    if (score >= 50) return 3;
    if (score >= 35) return 2;
    if (score > 0)   return 1;
    return 0;
  }

  Widget _buildAvatar() {
    return SizedBox(
      width: 100, height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: kYellow.withOpacity(0.12), width: 1.5)),
          ),
          Container(
            width: 84, height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: kYellow.withOpacity(0.06), width: 1)),
          ),
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(
                color: kAvatarBg, shape: BoxShape.circle),
            child: const Icon(Icons.face_rounded,
                color: Color(0xFFE6BEF0), size: 36),
          ),
          Positioned(
            bottom: 14, right: 14,
            child: Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                color: _isRecording
                    ? const Color(0xFFD05050)
                    : kGreen,
                shape: BoxShape.circle,
                border: Border.all(color: kDarkCard, width: 2),
              ),
            ),
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
        color: Colors.black,
        border: Border(
          top: BorderSide(
              color: const Color(0xFFE6BEF0).withOpacity(0.08), width: 1)),
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
    0.28, 0.45, 0.65, 0.80, 0.55, 0.90, 0.70, 0.45,
    0.85, 0.60, 0.38, 0.75, 0.50, 0.35, 0.62, 0.42,
    0.72, 0.30, 0.55, 0.80, 0.40, 0.68, 0.28,
  ];

  const _WaveformPainter(
      {required this.progress, required this.color, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final count = _h.length;
    final barW  = (size.width * 0.032).clamp(3.0, 8.0);
    final gap   = (size.width - count * barW) / (count - 1);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < count; i++) {
      final phase = active ? (progress + i / count) % 1.0 : 0.5;
      final anim  = active
          ? 0.65 + 0.35 * sin(phase * 2 * pi)
          : 0.3;
      final h       = _h[i] * size.height * anim;
      final x       = i * (barW + gap);
      final y       = (size.height - h) / 2;
      final opacity = 0.28 + 0.72 * sin(i / (count - 1) * pi);
      paint.color =
          color.withOpacity((active ? opacity : 0.25).clamp(0.0, 1.0));
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
