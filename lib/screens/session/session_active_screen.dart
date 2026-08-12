import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'session_report_screen.dart';
import '../../core/app_nav.dart';
import '../../services/api_service.dart';

class SessionActiveScreen extends StatefulWidget {
  final int selectedAI; // 0=Coach, 1=Therapist, 2=Both
  const SessionActiveScreen({super.key, this.selectedAI = 2});

  @override
  State<SessionActiveScreen> createState() => _SessionActiveScreenState();
}

class _SessionActiveScreenState extends State<SessionActiveScreen>
    with TickerProviderStateMixin {
  // Timer
  int _seconds = 0;
  Timer? _timer;
  bool _running = true;

  // Waveform
  late AnimationController _waveCtrl;

  // Active AI tab
  int _activeAI = 0; // 0=Coach, 1=Therapist

  // ── Real audio pipeline (Modules 1–3) ───────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();
  String? _filePath;
  bool _isRecordingReal = false;
  bool _isAnalyzing = false;

  // ── Colours ──────────────────────────────────────────────────────────────
  static const Color kBg         = Color(0xFF1A0535);
  static const Color kCardBg     = Color(0xFF2D0A52);
  static const Color kPrimary    = Color(0xFF5300AC);
  static const Color kYellow     = Color(0xFFCDCC58);
  static const Color kSubtitle   = Color(0xFFC097D8);
  static const Color kStopBg     = Color(0xFF6B1A2A);
  static const Color kStopText   = Color(0xFFFF6B6B);
  static const Color kFast       = Color(0xFFCDCC58);
  static const Color kNervous    = Color(0xFFCDCC58);
  static const Color kGood       = Color(0xFFCDCC58);

  @override
  void initState() {
    super.initState();
    // Set initial active AI based on selection
    _activeAI = widget.selectedAI == 1 ? 1 : 0;

    // Start timer from 0
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_running) setState(() => _seconds++);
    });

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _startRealRecording();
  }

  /// Starts actually recording audio in the background. If mic permission
  /// isn't available, we silently skip real recording — the session still
  /// runs visually (timer, waveform) and the report screen will fall back
  /// to placeholder numbers instead of failing the whole session.
  Future<void> _startRealRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return;

      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/speakora_session_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      _filePath = path;
      _isRecordingReal = true;
    } catch (_) {
      // Recording is a nice-to-have here, not a hard requirement — fail quiet.
      _isRecordingReal = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveCtrl.dispose();
    if (_isRecordingReal) {
      _recorder.stop();
    }
    _recorder.dispose();
    super.dispose();
  }

  String get _timeLabel {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int _navIndex = 1; // Quest is active by default on this screen

  Future<void> _handleStop() async {
    setState(() => _running = false);
    _timer?.cancel();
    _waveCtrl.stop();

    Map<String, dynamic>? analysis;

    if (_isRecordingReal && _filePath != null) {
      try {
        final path = await _recorder.stop();
        if (path != null && mounted) {
          setState(() => _isAnalyzing = true);
          analysis = await ApiService.transcribeAudio(path);
        }
      } catch (_) {
        // Analysis failed — report screen will just use placeholder data.
        analysis = null;
      }
    }

    if (!mounted) return;
    setState(() => _isAnalyzing = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionReportScreen(
          selectedAI: widget.selectedAI,
          realTranscript: analysis?['transcript'] as String?,
          realFluencyScore: analysis?['fluencyScore'] as int?,
          realFillerWordCount: analysis?['fillerWordCount'] as int?,
          realLongPauseCount: analysis?['longPauseCount'] as int?,
          realWpm: analysis?['wpm'] as int?,
          realPaceStability: analysis?['paceStability'] as String?,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Timer row ───────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'In progress',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.55),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedBuilder(
                            animation: _waveCtrl,
                            builder: (_, __) => Text(
                              _timeLabel,
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Stop button
                      GestureDetector(
                        onTap: _isAnalyzing ? null : _handleStop,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 12),
                          decoration: BoxDecoration(
                            color: kStopBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Stop',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: kStopText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── AI avatars (show based on selection) ────────────────
                  Row(
                    children: [
                      if (widget.selectedAI == 0 || widget.selectedAI == 2) ...[
                        _AIAvatar(
                          icon: Icons.person_rounded,
                          label: 'Coach',
                          active: _activeAI == 0,
                          onTap: () => setState(() => _activeAI = 0),
                        ),
                        if (widget.selectedAI == 2) const SizedBox(width: 20),
                      ],
                      if (widget.selectedAI == 1 || widget.selectedAI == 2)
                        _AIAvatar(
                          icon: Icons.psychology_rounded,
                          label: 'Therapist',
                          active: _activeAI == 1,
                          onTap: () => setState(() => _activeAI = 1),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Waveform ────────────────────────────────────────────
                  Center(
                    child: AnimatedBuilder(
                      animation: _waveCtrl,
                      builder: (_, __) => CustomPaint(
                        size: const Size(260, 56),
                        painter: _WaveformPainter(
                          progress: _waveCtrl.value,
                          color: kYellow,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Metrics card ────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _MetricRow(
                          label: 'Speed',
                          value: 'Fast ↑',
                          valueColor: kFast,
                        ),
                        const _Divider(),
                        _MetricRow(
                          label: 'Emotion',
                          value: 'Nervous',
                          valueColor: kNervous,
                          dot: true,
                        ),
                        const _Divider(),
                        _MetricRow(
                          label: 'Volume',
                          value: 'Good',
                          valueColor: kGood,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── AI tip card ─────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isRecordingReal
                          ? '"Speak naturally — this is being analyzed by the real pipeline."'
                          : '"Slow down a little — you\'re rushing."',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Analyzing overlay ─────────────────────────────────────────
            if (_isAnalyzing)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: kYellow),
                      SizedBox(height: 16),
                      Text(
                        'Analyzing your speech...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    const items = [
      (Icons.home_outlined,       'Home'),
      (Icons.show_chart_rounded,  'Progress'),
      (Icons.headset_mic_outlined,'Support'),
      (Icons.person_outline_rounded,'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A0535),
        border: Border(
          top: BorderSide(color: Color(0xFF3D1080), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = _navIndex == i;
          final color  = active ? kYellow : kSubtitle;
          return GestureDetector(
            onTap: () => navigateTo(context, i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(items[i].$1, color: color, size: 24),
                const SizedBox(height: 3),
                Text(
                  items[i].$2,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: active
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── AI Avatar widget ──────────────────────────────────────────────────────────
class _AIAvatar extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  static const Color kPrimary  = Color(0xFF5300AC);
  static const Color kInactive = Color(0xFF3D1080);
  static const Color kYellow   = Color(0xFFCDCC58);
  static const Color kSubtitle = Color(0xFFC097D8);

  const _AIAvatar({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: active ? kPrimary : kInactive,
              borderRadius: BorderRadius.circular(22),
              border: active
                  ? Border.all(color: kYellow, width: 2.5)
                  : null,
            ),
            child: Icon(
              icon,
              color: active ? Colors.white : kSubtitle,
              size: 38,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: active ? kYellow : kInactive,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? Colors.black87 : kSubtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Metric row ────────────────────────────────────────────────────────────────
class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool dot;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const Spacer(),
          if (dot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: valueColor,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Thin divider ──────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Colors.white.withOpacity(0.08),
      height: 1,
      thickness: 1,
    );
  }
}

// ── Animated waveform painter ─────────────────────────────────────────────────
class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;

  static const List<double> _heights = [
    0.35, 0.60, 0.80, 0.95, 0.70, 1.0, 0.85, 0.55,
    1.0, 0.75, 0.50, 0.88, 0.65, 0.42, 0.72, 0.52,
  ];

  const _WaveformPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final count = _heights.length;
    const barW = 8.0;
    final gap = (size.width - count * barW) / (count - 1);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final phase = (progress + i / count) % 1.0;
      final anim = 0.72 + 0.28 * sin(phase * 2 * pi);
      final h = _heights[i] * size.height * anim;
      final x = i * (barW + gap);
      final y = (size.height - h) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, barW, h), const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.progress != progress;
}
