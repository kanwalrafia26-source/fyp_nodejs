import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/app_nav.dart';
import '../../services/api_service.dart';
import 'simulation_report_screen.dart';

class SimulationActiveScreen extends StatefulWidget {
  final String roleName;
  final String scenarioName;
  final String difficulty;
  final int selectedAI; // 0=Coach, 1=Therapist, 2=Both

  const SimulationActiveScreen({
    super.key,
    this.roleName     = 'Senior Web Developer',
    this.scenarioName = 'Internship Interview',
    this.difficulty   = 'Medium',
    this.selectedAI   = 2,
  });

  @override
  State<SimulationActiveScreen> createState() =>
      _SimulationActiveScreenState();
}

class _SimulationActiveScreenState extends State<SimulationActiveScreen>
    with TickerProviderStateMixin {
  // ── Timer ─────────────────────────────────────────────────────────────────
  int _seconds = 0;
  Timer? _timer;
  bool _running = true;
  int _navIndex = 1;

  // ── Animation controllers ─────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;

  // ── Real audio pipeline ───────────────────────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();
  String? _filePath;
  bool _isRecordingReal = false;
  bool _isAnalyzing     = false;

  // ── Colours ───────────────────────────────────────────────────────────────
  static const Color kBg       = Color(0xFF1C0E4E);
  static const Color kCard     = Color(0xFF3D2490);
  static const Color kPrimary  = Color(0xFF5B2DD9);
  static const Color kYellow   = Color(0xFFC8F55A);
  static const Color kYellowDk = Color(0xFF1C0E4E);
  static const Color kSubtitle = Color(0xFFB9A8E8);
  static const Color kMuted    = Color(0xFF7B6AB5);
  static const Color kOrange   = Color(0xFFE8860A);
  static const Color kStop     = Color(0xFFFF4A6E);
  static const Color kNavBg    = Color(0xFF290451);
  static const Color kNavActive= Color(0xFFD9E366);
  static const Color kNavInact = Color(0xFF7A50A0);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_running) setState(() => _seconds++);
    });
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _startRealRecording();
  }

  /// Starts recording audio. Fails silently — if mic isn't available the
  /// session still runs and the report falls back to placeholder data,
  /// exactly the same pattern as the regular session screen.
  Future<void> _startRealRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return;
      final dir  = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/sim_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      _filePath         = path;
      _isRecordingReal  = true;
    } catch (_) {
      _isRecordingReal = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    if (_isRecordingReal) _recorder.stop();
    _recorder.dispose();
    super.dispose();
  }

  String get _timeLabel {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _handleStop() async {
    setState(() { _running = false; });
    _timer?.cancel();
    _waveCtrl.stop();
    _pulseCtrl.stop();

    Map<String, dynamic>? analysis;

    if (_isRecordingReal && _filePath != null) {
      try {
        final path = await _recorder.stop();
        if (path != null && mounted) {
          setState(() => _isAnalyzing = true);
          analysis = await ApiService.transcribeAudio(path);
        }
      } catch (_) {
        analysis = null;
      }
    }

    if (!mounted) return;
    setState(() => _isAnalyzing = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SimulationReportScreen(
          roleName:     widget.roleName,
          scenarioName: widget.scenarioName,
          difficulty:   widget.difficulty,
          selectedAI:   widget.selectedAI,
          durationSeconds: _seconds,
          // Pass all real analysis fields — same keys as the regular session.
          realTranscript:        analysis?['transcript']        as String?,
          realFluencyScore:      analysis?['fluencyScore']      as int?,
          realFillerWordCount:   analysis?['fillerWordCount']   as int?,
          realLongPauseCount:    analysis?['longPauseCount']    as int?,
          realWpm:               analysis?['wpm']               as int?,
          realPaceStability:     analysis?['paceStability']     as String?,
          realEmotionLabel:      analysis?['emotionLabel']      as String?,
          realAnxietyScore:      analysis?['anxietyScore']      as int?,
          realPronunciationScore:analysis?['pronunciationScore']as int?,
          realPitchVariability:  (analysis?['pitchVariability'] as num?)?.toDouble(),
          realJitterPercent:     (analysis?['jitterPercent']    as num?)?.toDouble(),
          realShimmerPercent:    (analysis?['shimmerPercent']   as num?)?.toDouble(),
          realPitchMeanHz:       (analysis?['pitchMeanHz']      as num?)?.toDouble(),
          realEnergyDb:          (analysis?['energyDb']         as num?)?.toDouble(),
          realFeedbackMessages:  (analysis?['feedbackMessages'] as List?)
              ?.map((e) => e.toString()).toList(),
          realTherapySuggestions:(analysis?['therapySuggestions'] as List?)
              ?.map((e) => e.toString()).toList(),
          realConfidenceTip:     analysis?['confidenceTip']     as String?,
          realFillerBreakdown:   (analysis?['fillerBreakdown']  as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v as int)),
          realLowConfidenceWords:(analysis?['lowConfidenceWords'] as List?)
              ?.map((e) => e.toString()).toList(),
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
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Timer + Stop ─────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('In progress',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.55))),
                          AnimatedBuilder(
                            animation: _waveCtrl,
                            builder: (_, __) => Text(
                              _timeLabel,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _isAnalyzing ? null : _handleStop,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: kStop,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Stop',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Context bar ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Text('💼',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(widget.roleName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, color: kSubtitle)),
                        ),
                        Container(
                          width: 1, height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: kPrimary,
                        ),
                        Flexible(
                          child: Text(widget.scenarioName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, color: kSubtitle)),
                        ),
                        Container(
                          width: 1, height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: kPrimary,
                        ),
                        Text(widget.difficulty,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: kYellow,
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── AI avatar ────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) {
                            final scale =
                                1.0 + 0.05 * sin(_pulseCtrl.value * pi);
                            return Transform.scale(
                              scale: scale,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 110, height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: kYellow.withOpacity(0.12),
                                        width: 0.6,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 96, height: 96,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: kYellow.withOpacity(0.25),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 80, height: 80,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE6BEF0),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('AI',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: kYellow)),
                                        Container(
                                          width: 28, height: 10,
                                          decoration: BoxDecoration(
                                            color: kPrimary,
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 48, height: 8,
                          decoration: BoxDecoration(
                              color: kYellow,
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRecordingReal
                              ? 'ARIA · Listening & analysing...'
                              : 'ARIA · No mic — visual mode',
                          style: TextStyle(fontSize: 11, color: kSubtitle),
                        ),
                        const SizedBox(height: 12),
                        AnimatedBuilder(
                          animation: _waveCtrl,
                          builder: (_, __) => CustomPaint(
                            size: Size(
                                MediaQuery.of(context).size.width * 0.7, 40),
                            painter: _WaveformPainter(
                              progress: _waveCtrl.value,
                              color: kYellow,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── AI question card ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kPrimary, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('"',
                                style: TextStyle(
                                    fontSize: 22, color: kYellow)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _sampleQuestion(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const Text('"',
                                style: TextStyle(
                                    fontSize: 22, color: kYellow)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ARIA · ${widget.roleName}',
                            style: const TextStyle(
                                fontSize: 10, color: kYellow),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Live hint card ───────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _isRecordingReal
                          ? '"Speak naturally — your answer is being recorded and analysed in real time."'
                          : '"No microphone detected — grant mic permission and restart to get real analysis."',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Analysing overlay ────────────────────────────────────
            if (_isAnalyzing)
              Container(
                color: Colors.black.withOpacity(0.65),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: kYellow),
                      SizedBox(height: 16),
                      Text(
                        'Analysing your speech...',
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

  /// Returns a context-appropriate sample question based on the scenario.
  String _sampleQuestion() {
    final s = widget.scenarioName.toLowerCase();
    if (s.contains('interview'))   return 'Tell me about a challenging project you worked on — what was your role and what did you learn?';
    if (s.contains('negotiation')) return 'What rate are you looking for, and how did you arrive at that number?';
    if (s.contains('discovery'))   return 'Walk me through your most relevant experience for this project.';
    if (s.contains('pitch'))       return 'What makes your approach different from others in the market?';
    if (s.contains('presentation'))return 'Summarise your main argument in one sentence for the audience.';
    return 'Tell me more about your experience and how it applies here.';
  }

  // ── Bottom nav ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      (Icons.home_outlined,          'Home'),
      (Icons.show_chart_rounded,     'Progress'),
      (Icons.headset_mic_outlined,   'Support'),
      (Icons.person_outline_rounded, 'Profile'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: kNavBg,
        border: Border(
            top: BorderSide(color: Color(0xFF3D2A7A), width: 1)),
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

// ── Waveform painter ───────────────────────────────────────────────────────────
class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;

  static const List<double> _h = [
    0.3, 0.5, 0.4, 0.8, 0.6, 1.0, 0.9, 0.7, 1.0, 0.8,
    0.6, 0.9, 0.7, 0.5, 0.8, 0.6, 0.4, 0.7, 0.5, 0.3,
    0.2, 0.15, 0.1,
  ];

  const _WaveformPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final count = _h.length;
    final barW  = (size.width * 0.032).clamp(3.0, 7.0);
    final gap   = (size.width - count * barW) / (count - 1);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < count; i++) {
      final phase   = (progress + i / count) % 1.0;
      final anim    = 0.65 + 0.35 * sin(phase * 2 * pi);
      final h       = _h[i] * size.height * anim;
      final x       = i * (barW + gap);
      final y       = (size.height - h) / 2;
      final opacity =
          (0.2 + 0.8 * sin(i / (count - 1) * pi)).clamp(0.0, 1.0);
      paint.color = color.withOpacity(opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, barW, h), const Radius.circular(3)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.progress != progress;
}
