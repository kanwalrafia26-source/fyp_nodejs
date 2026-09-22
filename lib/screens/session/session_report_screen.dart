import 'dart:math';
import 'package:flutter/material.dart';
import 'session_setup_screen.dart';
import 'session_active_screen.dart';
import '../details/coach_detail_screen.dart';
import '../details/therapist_detail_screen.dart';
import '../details/voice_analysis_screen.dart';
import '../../services/api_service.dart';
import '../../core/app_flushbar.dart';

class SessionReportScreen extends StatefulWidget {
  final int selectedAI; // 0=Coach, 1=Therapist, 2=Both

  // Real data from Modules 1–3 (Audio, Speech-to-Text, Fluency Analysis).
  // Null when recording/analysis wasn't available — screen falls back to
  // placeholder numbers in that case instead of breaking.
  final String? realTranscript;
  final int? realFluencyScore;
  final int? realFillerWordCount;
  final int? realLongPauseCount;
  final int? realWpm;
  final int? realDurationSeconds;
  final String? realPaceStability;
  final String? realEmotionLabel;
  final int? realAnxietyScore;
  final int? realPronunciationScore;
  final List<String>? realFeedbackMessages;
  final List<String>? realTherapySuggestions;
  final String? realConfidenceTip;
  final double? realPitchVariability;
  final double? realJitterPercent;
  final double? realShimmerPercent;
  final double? realPitchMeanHz;
  final double? realEnergyDb;
  final Map<String, int>? realFillerBreakdown;
  final List<String>? realLowConfidenceWords;

  const SessionReportScreen({
    super.key,
    this.selectedAI = 2,
    this.realTranscript,
    this.realFluencyScore,
    this.realFillerWordCount,
    this.realLongPauseCount,
    this.realWpm,
    this.realDurationSeconds,
    this.realPaceStability,
    this.realEmotionLabel,
    this.realAnxietyScore,
    this.realPronunciationScore,
    this.realFeedbackMessages,
    this.realTherapySuggestions,
    this.realConfidenceTip,
    this.realPitchVariability,
    this.realJitterPercent,
    this.realShimmerPercent,
    this.realPitchMeanHz,
    this.realEnergyDb,
    this.realFillerBreakdown,
    this.realLowConfidenceWords,
  });

  bool get hasRealData => realFluencyScore != null;

  @override
  State<SessionReportScreen> createState() => _SessionReportScreenState();
}

class _SessionReportScreenState extends State<SessionReportScreen> {
  bool _coachExpanded       = true;
  bool _therapistExpanded   = true;
  bool _voiceExpanded       = true;
  bool _isSaving            = false;

  // ── Colours ────────────────────────────────────────────────────────────────
  static const Color kBg        = Color(0xFFFFFEF6);
  static const Color kHeader    = Color(0xFF2F0A56);
  static const Color kPrimary   = Color(0xFF5300AC);
  static const Color kYellow    = Color(0xFFD9E366);
  static const Color kSubtitle  = Color(0xFFC097D8);
  static const Color kCardBg    = Color(0x33E6BEF0);
  static const Color kCardBdr   = Color(0x66F0D4FF);
  static const Color kAISays    = Color(0xFFE6BEF0);
  static const Color kOrange    = Color(0xFFFFA060);
  static const Color kBarBg     = Color(0xFFEFDAFF);
  static const Color kBarPurple = Color(0xFF5300AC);
  static const Color kBarYellow = Color(0xFFD9E366);
  static const Color kBarOrange = Color(0xFFFFA060);
  static const Color kNavBg     = Color(0xFFE6C6F7);
  static const Color kGreen     = Color(0xFF2D7A40);

  int get _overallScore => widget.realFluencyScore ?? 74;

  Future<void> _handleSave() async {
    if (!widget.hasRealData) {
      showFlushbar(context, 'Nothing to save — this report used placeholder data.');
      return;
    }

    setState(() => _isSaving = true);

    final error = await ApiService.saveSession({
      'selectedAI': widget.selectedAI,
      'durationSeconds': widget.realDurationSeconds ?? 0,
      'transcript': widget.realTranscript ?? '',
      'wpm': widget.realWpm,
      'longPauseCount': widget.realLongPauseCount,
      'fillerWordCount': widget.realFillerWordCount,
      'paceStability': widget.realPaceStability,
      'fluencyScore': widget.realFluencyScore,
      'pronunciationScore': widget.realPronunciationScore,
      'emotionLabel': widget.realEmotionLabel,
      'anxietyScore': widget.realAnxietyScore,
      'feedbackMessages': widget.realFeedbackMessages ?? [],
      'therapySuggestions': widget.realTherapySuggestions ?? [],
      'confidenceTip': widget.realConfidenceTip,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      showFlushbar(context, error);
    } else {
      showFlushbar(context, '✅ Session saved to your history.', isError: false);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SessionSetupScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            _buildHeader(),

            // ── Live transcript preview (only if we have real data) ──────
            if (widget.hasRealData && widget.realTranscript != null) ...[
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
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: kGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE TRANSCRIPT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: kSubtitle,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.realTranscript!.isNotEmpty
                            ? widget.realTranscript!
                            : '(no speech detected)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: kHeader,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Coach card ───────────────────────────────────────────────
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
                            realFluencyScore: widget.realFluencyScore,
                            realPronunciationScore: widget.realPronunciationScore,
                            realFillerWordCount: widget.realFillerWordCount,
                            realLongPauseCount: widget.realLongPauseCount,
                            realPaceStability: widget.realPaceStability,
                            realFillerBreakdown: widget.realFillerBreakdown,
                            realLowConfidenceWords: widget.realLowConfidenceWords,
                          )),
                ),
                child: _buildCoachContent(),
              ),

            if (widget.selectedAI == 0 || widget.selectedAI == 2)
              const SizedBox(height: 12),

            // ── Therapist card ───────────────────────────────────────────
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
                            realEmotionLabel: widget.realEmotionLabel,
                            realAnxietyScore: widget.realAnxietyScore,
                            realPitchVariability: widget.realPitchVariability,
                            realJitterPercent: widget.realJitterPercent,
                            realShimmerPercent: widget.realShimmerPercent,
                          )),
                ),
                child: _buildTherapistContent(),
              ),

            if (widget.selectedAI == 1 || widget.selectedAI == 2)
              const SizedBox(height: 12),

            // ── Voice analysis card ──────────────────────────────────────
            _buildExpandableCard(
              title: 'Voice analysis',
              expanded: _voiceExpanded,
              onToggle: () =>
                  setState(() => _voiceExpanded = !_voiceExpanded),
              onDetailTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => VoiceAnalysisScreen(
                      realWpm:              widget.realWpm,
                      realLongPauseCount:   widget.realLongPauseCount,
                      realFillerWordCount:  widget.realFillerWordCount,
                      realPitchMeanHz:      widget.realPitchMeanHz,
                      realPitchVariability: widget.realPitchVariability,
                      realEnergyDb:         widget.realEnergyDb,
                      realJitterPercent:    widget.realJitterPercent,
                      realShimmerPercent:   widget.realShimmerPercent,
                      realPaceStability:    widget.realPaceStability,
                    )),
              ),
              child: _buildVoiceContent(),
            ),

            const SizedBox(height: 16),

            // ── AI says card ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: kAISays,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: kPrimary.withOpacity(0.07), width: 4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI says',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: kHeader,
                        letterSpacing: -0.68,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.realFeedbackMessages != null &&
                        widget.realFeedbackMessages!.isNotEmpty) ...[
                      // Real Module 5 output: what happened
                      ...widget.realFeedbackMessages!.map((msg) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '• $msg',
                              style: const TextStyle(
                                fontSize: 14,
                                color: kHeader,
                                height: 1.4,
                              ),
                            ),
                          )),
                      if (widget.realTherapySuggestions != null &&
                          widget.realTherapySuggestions!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'TRY THIS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: kHeader,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...widget.realTherapySuggestions!.map((tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '→ $tip',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: kHeader,
                                  height: 1.4,
                                ),
                              ),
                            )),
                      ],
                      if (widget.realConfidenceTip != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.realConfidenceTip!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kHeader,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ] else ...[
                      // No real data — original placeholder line
                      const Text(
                        '"4 min non-stop, thats real growth!',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w300,
                          color: kHeader,
                          letterSpacing: -0.68,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Again / Save buttons ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SessionActiveScreen(
                                selectedAI: widget.selectedAI),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kYellow,
                          foregroundColor: kHeader,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Again',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.88,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kHeader,
                          side: const BorderSide(color: kHeader, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: kHeader),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.88,
                                ),
                              ),
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
            // Header row with toggle
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    // Highlight bar behind title
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6C6F7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                          letterSpacing: -0.68,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Detail view button (navigates to full report)
                    if (onDetailTap != null)
                      GestureDetector(
                        onTap: onDetailTap,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: kNavBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            color: kHeader,
                            size: 14,
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: onToggle,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: kNavBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: kHeader,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Collapsible content
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
    // Real data (Module 3) covers Fluency, Filler words, and Pacing.
    // Pronunciation still needs Module 2's phoneme-mismatch work we haven't
    // built yet, so it stays as a labeled placeholder for now.
    final fluencyScore = widget.realFluencyScore;
    final fillerCount = widget.realFillerWordCount;
    final paceStability = widget.realPaceStability;
    final pronunciationScore = widget.realPronunciationScore;

    return Column(
      children: [
        _BarMetric(
          label: 'Pronounciation',
          value: pronunciationScore != null ? '$pronunciationScore%' : '80%',
          fill: (pronunciationScore ?? 81) / 100,
          color: kBarPurple,
        ),
        const SizedBox(height: 10),
        _BarMetric(
          label: 'Fluency',
          value: fluencyScore != null ? '$fluencyScore%' : '68%',
          fill: (fluencyScore ?? 66) / 100,
          color: kBarPurple,
        ),
        const SizedBox(height: 10),
        _BarMetric(
          label: 'Pacing',
          value: paceStability ?? '80%',
          fill: paceStability != null
              ? (paceStability == 'Stable' ? 0.85 : 0.45)
              : 0.80,
          color: kBarPurple,
        ),
        const SizedBox(height: 10),
        _BarMetric(
          label: 'Filler words',
          value: fillerCount != null ? '$fillerCount words' : '68%',
          fill: fillerCount != null
              ? (1 - min(fillerCount, 10) / 10).clamp(0.0, 1.0)
              : 0.66,
          color: kBarPurple,
        ),
      ],
    );
  }

  // ── Therapist content ──────────────────────────────────────────────────────
  Widget _buildTherapistContent() {
    final emotion = widget.realEmotionLabel;
    final anxiety = widget.realAnxietyScore;

    if (emotion == null || anxiety == null) {
      // No real data — keep the original placeholder rows.
      return Column(
        children: [
          _DotMetric(label: 'Anxiety',            value: 'Mild',  dotColor: kOrange),
          const SizedBox(height: 8),
          _DotMetric(label: 'Stress',             value: 'Mild',  dotColor: kOrange),
          const SizedBox(height: 8),
          _DotMetric(label: 'Fear',               value: 'No',    dotColor: const Color(0xFF61EF8E)),
          const SizedBox(height: 8),
          _DotMetric(label: 'Confidence',         value: 'High',  dotColor: const Color(0xFFCC3333)),
          const SizedBox(height: 8),
          _DotMetric(label: 'Sadness',            value: 'Fast',  dotColor: kOrange),
          const SizedBox(height: 8),
          _DotMetric(label: 'Emotional Stability',value: 'Low',   dotColor: kOrange),
        ],
      );
    }

    // Real, rule-based result (Module 4 — acoustic features, not a trained
    // SER model; see python/transcribe.py for the honesty note on this).
    final anxietyLevel = anxiety >= 65
        ? 'High'
        : anxiety >= 35
            ? 'Mild'
            : 'Low';
    final anxietyColor = anxiety >= 65
        ? kOrange
        : anxiety >= 35
            ? kOrange
            : const Color(0xFF61EF8E);

    return Column(
      children: [
        _DotMetric(label: 'Detected emotion', value: emotion, dotColor: kPrimary),
        const SizedBox(height: 8),
        _DotMetric(label: 'Anxiety level', value: anxietyLevel, dotColor: anxietyColor),
        const SizedBox(height: 8),
        _DotMetric(label: 'Anxiety score', value: '$anxiety/100', dotColor: anxietyColor),
      ],
    );
  }

  // ── Voice analysis content ─────────────────────────────────────────────────
  Widget _buildVoiceContent() {
    final wpm = widget.realWpm;
    final longPauses = widget.realLongPauseCount;
    final pitchHz = widget.realPitchMeanHz;
    final energyDb = widget.realEnergyDb;
    final jitter = widget.realJitterPercent;
    final shimmer = widget.realShimmerPercent;

    return Column(
      children: [
        _BarMetric(
          label: 'Pitch',
          value: pitchHz != null ? '${pitchHz.round()} Hz' : '80%',
          // Rough visual scaling: typical conversational pitch ~80-300Hz
          fill: pitchHz != null ? (pitchHz / 300).clamp(0.0, 1.0) : 0.80,
          color: kBarPurple,
        ),
        const SizedBox(height: 8),
        _BarMetric(
          label: 'Speed',
          value: wpm != null ? '$wpm WPM' : '80%',
          fill: wpm != null ? (wpm / 180).clamp(0.0, 1.0) : 0.80,
          color: kBarYellow,
        ),
        const SizedBox(height: 8),
        _BarMetric(
          label: 'Volume',
          value: energyDb != null ? '${energyDb.round()} dB' : '80%',
          // Rough scaling: typical conversational speech ~50-75dB
          fill: energyDb != null ? ((energyDb - 40) / 40).clamp(0.0, 1.0) : 0.80,
          color: kBarPurple,
        ),
        const SizedBox(height: 8),
        _BarMetric(
          label: 'Pauses',
          value: longPauses != null ? '$longPauses long' : '80%',
          fill: longPauses != null
              ? (1 - min(longPauses, 8) / 8).clamp(0.0, 1.0)
              : 0.80,
          color: kBarOrange,
        ),
        const SizedBox(height: 8),
        _BarMetricSub(
          label: 'Tone',
          sub: 'Jitter',
          value: jitter != null ? '${jitter.toStringAsFixed(2)}%' : '80%',
          // Reference: healthy voice jitter is typically <1.04%
          fill: jitter != null ? (1 - (jitter / 3).clamp(0.0, 1.0)) : 0.80,
          color: kBarOrange,
        ),
        const SizedBox(height: 8),
        _BarMetricSub(
          label: 'Tone',
          sub: 'Strained (shimmer)',
          value: shimmer != null ? '${shimmer.toStringAsFixed(2)}%' : '80%',
          // Reference: healthy voice shimmer is typically <3.81%
          fill: shimmer != null ? (1 - (shimmer / 10).clamp(0.0, 1.0)) : 0.80,
          color: kBarOrange,
        ),
        const SizedBox(height: 8),
        _BarMetric(label: 'Articulation', value: '80%', fill: 0.80, color: kBarOrange),
        if (pitchHz != null) ...[
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Articulation is a placeholder — not yet computed from real audio.',
              style: TextStyle(fontSize: 9, color: kSubtitle),
            ),
          ),
        ],
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: kHeader,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session complete',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: kSubtitle,
              letterSpacing: -0.68,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CustomPaint(
                  painter: _ScoreRingPainter(score: _overallScore),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_overallScore',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: kSubtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your report',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.68,
                    ),
                  ),
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
                          : '+6 vs last session',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4C5414),
                        letterSpacing: -0.56,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Score ring ─────────────────────────────────────────────────────────────────
class _ScoreRingPainter extends CustomPainter {
  final int score;
  const _ScoreRingPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 6;
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()
          ..color = const Color(0xFF543C6E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -pi / 2,
      2 * pi * score / 100,
      false,
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

// ── Bar metric row ─────────────────────────────────────────────────────────────
class _BarMetric extends StatelessWidget {
  final String label;
  final String value;
  final double fill;
  final Color color;

  const _BarMetric(
      {required this.label,
      required this.value,
      required this.fill,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC097D8),
                    letterSpacing: -0.56)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F0A56),
                    letterSpacing: -0.56)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: 9,
            backgroundColor: const Color(0xFFEFDAFF),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ── Bar metric with sub-label ──────────────────────────────────────────────────
class _BarMetricSub extends StatelessWidget {
  final String label;
  final String sub;
  final String value;
  final double fill;
  final Color color;

  const _BarMetricSub(
      {required this.label,
      required this.sub,
      required this.value,
      required this.fill,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC097D8),
                        letterSpacing: -0.56)),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF290451))),
              ],
            ),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F0A56),
                    letterSpacing: -0.56)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: 9,
            backgroundColor: const Color(0xFFEFDAFF),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ── Dot metric row (Therapist) ─────────────────────────────────────────────────
class _DotMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color dotColor;

  const _DotMetric(
      {required this.label,
      required this.value,
      required this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFFC097D8),
                letterSpacing: -0.56)),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: dotColor,
                    letterSpacing: -0.56)),
          ],
        ),
      ],
    );
  }
}