import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/app_flushbar.dart';
import '../home/home_screen.dart';
import '../details/coach_detail_screen.dart';
import '../details/therapist_detail_screen.dart';
import 'simulation_screen.dart';

class SimulationReportScreen extends StatefulWidget {
  final String roleName;
  final String scenarioName;
  final String difficulty;
  final int    selectedAI;     // 0=Coach, 1=Therapist, 2=Both
  final int    durationSeconds;

  // ── Real analysis results (all nullable — falls back gracefully) ──────────
  final String?        realTranscript;
  final int?           realFluencyScore;
  final int?           realFillerWordCount;
  final int?           realLongPauseCount;
  final int?           realWpm;
  final String?        realPaceStability;
  final String?        realEmotionLabel;
  final int?           realAnxietyScore;
  final int?           realPronunciationScore;
  final double?        realPitchVariability;
  final double?        realJitterPercent;
  final double?        realShimmerPercent;
  final double?        realPitchMeanHz;
  final double?        realEnergyDb;
  final List<String>?  realFeedbackMessages;
  final List<String>?  realTherapySuggestions;
  final String?        realConfidenceTip;
  final Map<String,int>? realFillerBreakdown;
  final List<String>?  realLowConfidenceWords;

  const SimulationReportScreen({
    super.key,
    this.roleName        = 'Senior Web Developer',
    this.scenarioName    = 'Internship Interview',
    this.difficulty      = 'Medium',
    this.selectedAI      = 2,
    this.durationSeconds = 0,
    this.realTranscript,
    this.realFluencyScore,
    this.realFillerWordCount,
    this.realLongPauseCount,
    this.realWpm,
    this.realPaceStability,
    this.realEmotionLabel,
    this.realAnxietyScore,
    this.realPronunciationScore,
    this.realPitchVariability,
    this.realJitterPercent,
    this.realShimmerPercent,
    this.realPitchMeanHz,
    this.realEnergyDb,
    this.realFeedbackMessages,
    this.realTherapySuggestions,
    this.realConfidenceTip,
    this.realFillerBreakdown,
    this.realLowConfidenceWords,
  });

  bool get hasRealData => realFluencyScore != null;

  @override
  State<SimulationReportScreen> createState() =>
      _SimulationReportScreenState();
}

class _SimulationReportScreenState
    extends State<SimulationReportScreen> {
  bool _coachExpanded     = true;
  bool _therapistExpanded = true;
  bool _isSaving          = false;

  // ── Colours ────────────────────────────────────────────────────────────────
  static const Color kBg        = Color(0xFFFFFEF6);
  static const Color kHeader    = Color(0xFF2F0A56);
  static const Color kPrimary   = Color(0xFF5300AC);
  static const Color kYellow    = Color(0xFFD9E366);
  static const Color kSubtitle  = Color(0xFFC097D8);
  static const Color kCardBg    = Color(0x33E6BEF0);
  static const Color kCardBdr   = Color(0x66F0D4FF);
  static const Color kOrange    = Color(0xFFFFA060);
  static const Color kBarPurple = Color(0xFF5300AC);
  static const Color kNavBg     = Color(0xFFE6C6F7);
  static const Color kGreen     = Color(0xFF2D7A40);
  static const Color kBtnYellow = Color(0xFFD9E366);
  static const Color kBtnDk     = Color(0xFF2A3D00);

  int get _score => widget.realFluencyScore ?? 74;

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _handleSave() async {
    if (!widget.hasRealData) {
      showFlushbar(context,
          'Nothing to save — this report used placeholder data.');
      return;
    }
    setState(() => _isSaving = true);

    final error = await ApiService.saveSession({
      'sessionType':  'simulation',
      'scenarioName': widget.scenarioName,
      'roleName':     widget.roleName,
      'difficulty':   widget.difficulty,
      'selectedAI':   widget.selectedAI,
      'durationSeconds': widget.durationSeconds,
      'transcript':   widget.realTranscript ?? '',
      'wpm':               widget.realWpm,
      'longPauseCount':    widget.realLongPauseCount,
      'fillerWordCount':   widget.realFillerWordCount,
      'paceStability':     widget.realPaceStability,
      'fluencyScore':      widget.realFluencyScore,
      'pronunciationScore':widget.realPronunciationScore,
      'emotionLabel':      widget.realEmotionLabel,
      'anxietyScore':      widget.realAnxietyScore,
      'feedbackMessages':  widget.realFeedbackMessages  ?? [],
      'therapySuggestions':widget.realTherapySuggestions ?? [],
      'confidenceTip':     widget.realConfidenceTip,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      showFlushbar(context, error);
    } else {
      showFlushbar(context, '✅ Simulation saved to your history.',
          isError: false);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SimulationScreen()),
        );
      }
    }
  }

  // ── Retry ──────────────────────────────────────────────────────────────────
  void _handleRetry() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SimulationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            _buildHeader(),

            // ── Live transcript (only with real data) ────────────────
            if (widget.hasRealData &&
                widget.realTranscript != null &&
                widget.realTranscript!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kCardBdr, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                                color: kGreen, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Text('YOUR ANSWER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: kSubtitle,
                                letterSpacing: 1.0,
                              )),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(widget.realTranscript!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: kHeader,
                              height: 1.4)),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Coach card ───────────────────────────────────────────
            if (widget.selectedAI == 0 || widget.selectedAI == 2)
              _buildExpandableCard(
                title: 'Coach',
                expanded: _coachExpanded,
                onToggle: () =>
                    setState(() => _coachExpanded = !_coachExpanded),
                onDetailTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CoachDetailScreen(
                      realFluencyScore:      widget.realFluencyScore,
                      realPronunciationScore:widget.realPronunciationScore,
                      realFillerWordCount:   widget.realFillerWordCount,
                      realLongPauseCount:    widget.realLongPauseCount,
                      realPaceStability:     widget.realPaceStability,
                      realFillerBreakdown:   widget.realFillerBreakdown,
                      realLowConfidenceWords:widget.realLowConfidenceWords,
                    ),
                  ),
                ),
                child: _buildCoachContent(),
              ),

            if (widget.selectedAI == 0 || widget.selectedAI == 2)
              const SizedBox(height: 12),

            // ── Therapist card ───────────────────────────────────────
            if (widget.selectedAI == 1 || widget.selectedAI == 2)
              _buildExpandableCard(
                title: 'Therapist',
                expanded: _therapistExpanded,
                onToggle: () => setState(
                    () => _therapistExpanded = !_therapistExpanded),
                onDetailTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TherapistDetailScreen(
                      realEmotionLabel:   widget.realEmotionLabel,
                      realAnxietyScore:   widget.realAnxietyScore,
                      realPitchVariability: widget.realPitchVariability,
                      realJitterPercent:  widget.realJitterPercent,
                      realShimmerPercent: widget.realShimmerPercent,
                    ),
                  ),
                ),
                child: _buildTherapistContent(),
              ),

            if (widget.selectedAI == 1 || widget.selectedAI == 2)
              const SizedBox(height: 16),

            // ── AI says card ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6BEF0),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: kPrimary.withOpacity(0.07), width: 4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI says',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: kHeader,
                          letterSpacing: -0.68,
                        )),
                    const SizedBox(height: 8),
                    if (widget.realFeedbackMessages != null &&
                        widget.realFeedbackMessages!.isNotEmpty) ...[
                      ...widget.realFeedbackMessages!
                          .map((msg) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 6),
                                child: Text('• $msg',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: kHeader,
                                        height: 1.4)),
                              )),
                      if (widget.realTherapySuggestions != null &&
                          widget.realTherapySuggestions!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        const Text('TRY THIS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: kHeader,
                              letterSpacing: 1.0,
                            )),
                        const SizedBox(height: 4),
                        ...widget.realTherapySuggestions!
                            .map((tip) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 6),
                                  child: Text('→ $tip',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: kHeader,
                                        height: 1.4,
                                      )),
                                )),
                      ],
                      if (widget.realConfidenceTip != null) ...[
                        const SizedBox(height: 4),
                        Text(widget.realConfidenceTip!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kHeader,
                              height: 1.4,
                            )),
                      ],
                    ] else ...[
                      const Text(
                        'Complete a session with real audio to get AI coaching feedback here.',
                        style: TextStyle(
                          fontSize: 14,
                          color: kHeader,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Retry / Save buttons ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _handleRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBtnYellow,
                          foregroundColor: kBtnDk,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Retry',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kHeader,
                          side: const BorderSide(
                              color: kHeader, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: kHeader),
                              )
                            : const Text('Save',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final mins = widget.durationSeconds ~/ 60;
    final secs = widget.durationSeconds % 60;
    final dur  = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';

    return Container(
      width: double.infinity,
      color: kHeader,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Simulation complete',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: kSubtitle,
                  letterSpacing: -0.68)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 96, height: 96,
                child: CustomPaint(
                  painter: _ScoreRingPainter(score: _score),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$_score',
                            style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.0)),
                        Text('/100',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                color: kSubtitle)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your report',
                        style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.4)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: kYellow,
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Text(
                        widget.hasRealData
                            ? 'Live pipeline result'
                            : 'No mic — placeholder',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4C5414)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Duration: $dur · Role: ${widget.roleName}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Expandable card wrapper ────────────────────────────────────────────────
  Widget _buildExpandableCard({
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
    VoidCallback? onDetailTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kCardBdr, width: 1),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6C6F7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: kPrimary,
                              letterSpacing: -0.68)),
                    ),
                    const Spacer(),
                    if (onDetailTap != null)
                      GestureDetector(
                        onTap: onDetailTap,
                        child: Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(
                              color: kNavBg, shape: BoxShape.circle),
                          child: const Icon(Icons.chevron_right_rounded,
                              color: kHeader, size: 14),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: onToggle,
                        child: Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(
                              color: kNavBg, shape: BoxShape.circle),
                          child: Icon(
                            expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: kHeader, size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: child,
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  // ── Coach content ──────────────────────────────────────────────────────────
  Widget _buildCoachContent() {
    final fluency      = widget.realFluencyScore;
    final fillers      = widget.realFillerWordCount;
    final pace         = widget.realPaceStability;
    final pronunciation = widget.realPronunciationScore;

    return Column(children: [
      _BarMetric(
        label: 'Pronunciation',
        value: pronunciation != null ? '$pronunciation%' : '80%',
        fill:  (pronunciation ?? 80) / 100,
        color: kBarPurple,
      ),
      const SizedBox(height: 10),
      _BarMetric(
        label: 'Fluency',
        value: fluency != null ? '$fluency%' : '68%',
        fill:  (fluency ?? 68) / 100,
        color: kBarPurple,
      ),
      const SizedBox(height: 10),
      _BarMetric(
        label: 'Pacing',
        value: pace ?? '80%',
        fill:  pace != null ? (pace == 'Stable' ? 0.85 : 0.45) : 0.80,
        color: kBarPurple,
      ),
      const SizedBox(height: 10),
      _BarMetric(
        label: 'Filler words',
        value: fillers != null ? '$fillers words' : '68%',
        fill:  fillers != null
            ? (1 - min(fillers, 10) / 10).clamp(0.0, 1.0)
            : 0.66,
        color: kBarPurple,
      ),
    ]);
  }

  // ── Therapist content ──────────────────────────────────────────────────────
  Widget _buildTherapistContent() {
    final emotion = widget.realEmotionLabel;
    final anxiety = widget.realAnxietyScore;

    if (emotion == null || anxiety == null) {
      return Column(children: [
        _DotMetric(label: 'Anxiety',             value: 'Mild', dotColor: kOrange),
        const SizedBox(height: 8),
        _DotMetric(label: 'Stress',              value: 'Mild', dotColor: kOrange),
        const SizedBox(height: 8),
        _DotMetric(label: 'Fear',                value: 'No',   dotColor: const Color(0xFF61EF8E)),
        const SizedBox(height: 8),
        _DotMetric(label: 'Confidence',          value: 'High', dotColor: const Color(0xFFCC3333)),
        const SizedBox(height: 8),
        _DotMetric(label: 'Emotional Stability', value: 'Low',  dotColor: kOrange),
      ]);
    }

    final anxietyLevel = anxiety >= 65 ? 'High' : anxiety >= 35 ? 'Mild' : 'Low';
    final anxietyColor = anxiety >= 35 ? kOrange : const Color(0xFF61EF8E);

    return Column(children: [
      _DotMetric(label: 'Detected emotion', value: emotion,        dotColor: kPrimary),
      const SizedBox(height: 8),
      _DotMetric(label: 'Anxiety level',    value: anxietyLevel,   dotColor: anxietyColor),
      const SizedBox(height: 8),
      _DotMetric(label: 'Anxiety score',    value: '$anxiety/100', dotColor: anxietyColor),
    ]);
  }
}

// ── Score ring ─────────────────────────────────────────────────────────────────
class _ScoreRingPainter extends CustomPainter {
  final int score;
  const _ScoreRingPainter({required this.score});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2, r = size.width / 2 - 6;
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()
          ..color = const Color(0xFF543C6E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -pi / 2, 2 * pi * score / 100, false,
      Paint()
        ..color = const Color(0xFFD9E366)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
  }
  @override
  bool shouldRepaint(_ScoreRingPainter old) => old.score != score;
}

// ── Bar metric ─────────────────────────────────────────────────────────────────
class _BarMetric extends StatelessWidget {
  final String label, value;
  final double fill;
  final Color color;
  const _BarMetric({
    required this.label, required this.value,
    required this.fill,  required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFC097D8), letterSpacing: -0.56)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2F0A56), letterSpacing: -0.56)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: LinearProgressIndicator(
          value: fill, minHeight: 9,
          backgroundColor: const Color(0xFFEFDAFF),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ]);
  }
}

// ── Dot metric ─────────────────────────────────────────────────────────────────
class _DotMetric extends StatelessWidget {
  final String label, value;
  final Color dotColor;
  const _DotMetric({
    required this.label, required this.value, required this.dotColor,
  });
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFC097D8), letterSpacing: -0.56)),
      Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: dotColor, letterSpacing: -0.56)),
      ]),
    ]);
  }
}
