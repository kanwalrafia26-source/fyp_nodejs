import 'package:flutter/material.dart';

class TherapistDetailScreen extends StatelessWidget {
  // Real data from Module 4 (rule-based acoustic emotion detection).
  // Null falls back to the original example content.
  final String? realEmotionLabel;
  final int? realAnxietyScore;
  final double? realPitchVariability;
  final double? realJitterPercent;
  final double? realShimmerPercent;

  const TherapistDetailScreen({
    super.key,
    this.realEmotionLabel,
    this.realAnxietyScore,
    this.realPitchVariability,
    this.realJitterPercent,
    this.realShimmerPercent,
  });

  bool get hasRealData => realEmotionLabel != null && realAnxietyScore != null;

  static const Color kBg       = Color(0xFFFFFFFF);
  static const Color kHeader   = Color(0xFF1C0E4E);
  static const Color kPrimary  = Color(0xFF5B2DD9);
  static const Color kYellow   = Color(0xFFC8F55A);
  static const Color kYellowDk = Color(0xFF1C0E4E);
  static const Color kSubtitle = Color(0xFF9B8EC4);
  static const Color kOrange   = Color(0xFFE8860A);
  static const Color kRed      = Color(0xFFCC3333);
  static const Color kGreen    = Color(0xFF3BAA6A);
  static const Color kDivider  = Color(0xFFEDE8FF);
  static const Color kInsight  = Color(0xFFF7F4FF);
  static const Color kImprove  = Color(0xFFF4F0FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSectionLabel(),

            if (hasRealData) ...[
              // Honesty note: we only compute ONE overall emotion label +
              // anxiety score (Module 4 is rule-based over acoustic
              // features), not independent Stress/Fear/Sadness/Confidence
              // scores. Real mode shows exactly what was computed, nothing
              // fabricated beyond that.
              _buildSimpleEmotion(
                title: 'Detected emotion',
                level: realEmotionLabel!,
                levelColor: _emotionColor(realEmotionLabel!),
                dotColor: _emotionColor(realEmotionLabel!),
              ),
              _buildRealAnxietyBlock(),
            ] else ...[
              _buildEmotionBlock(
                title: 'Anxiety',
                level: 'Mild',
                levelColor: kOrange,
                dotColor: kOrange,
                subLabel: 'WHY DETECTED - 3 SIGNALS AGREED',
                signals: [
                  _Signal('Speed was fast - rushed at 0:00-1:00 and 4:00-4:12', null, kRed),
                  _Signal('Voice jitter detected', '- slight trembling at minute 2', kRed),
                  _Signal('Filler words high', '- 9 fillers signal nervousness', kRed),
                ],
                improve: 'Take 2 slow breaths before starting. Pause on purpose - silence sounds confident, not weak.',
              ),
              _buildEmotionBlock(
                title: 'Stress',
                level: 'Low',
                levelColor: kGreen,
                dotColor: kGreen,
                subLabel: 'WHY DETECTED - 2 SIGNALS AGREED',
                signals: [
                  _Signal('Energy spike at start - slight pressure in the first 30 sec', null, kRed),
                  _Signal('Strained tone was minimal - voice stayed relaxed overall', null, kRed),
                ],
                improve: 'Start slower - the first 30 seconds set your tone for the whole session.',
              ),
              _buildSimpleEmotion(
                title: 'Fear',
                level: 'None detected ✓',
                levelColor: kGreen,
                dotColor: kGreen,
              ),
              _buildSimpleEmotion(
                title: 'Sadness',
                level: 'None detected ✓',
                levelColor: kGreen,
                dotColor: kGreen,
              ),
              _buildEmotionBlock(
                title: 'Confidence',
                level: 'High',
                levelColor: kPrimary,
                dotColor: kPrimary,
                subLabel: 'WHY DETECTED - 3 SIGNALS AGREED',
                signals: [
                  _Signal('Volume was strong - steady and audible throughout', null, kGreen),
                  _Signal('Energy stayed high - 74% energy maintained', null, kGreen),
                  _Signal('Voice stability good - 76% stable, no major dips', null, kGreen),
                ],
                improve: null,
                keepDoing: 'Your confidence is your strongest asset. Channel it into slowing down - you will sound even more powerful. The calmer you go, the stronger you sound.',
              ),
            ],

            _buildAIInsight(),
            _buildFooter(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _emotionColor(String emotion) {
    switch (emotion) {
      case 'Anxious':
        return kOrange;
      case 'Angry':
        return kRed;
      case 'Sad':
        return const Color(0xFF7B6AB5);
      case 'Calm':
        return kGreen;
      case 'Happy':
      default:
        return kPrimary;
    }
  }

  // ── Real anxiety block, built from actual acoustic numbers ─────────────────
  Widget _buildRealAnxietyBlock() {
    final score = realAnxietyScore!;
    final level = score >= 65 ? 'High' : score >= 35 ? 'Mild' : 'Low';
    final levelColor = score >= 65 ? kRed : score >= 35 ? kOrange : kGreen;

    final signals = <_Signal>[];
    if (realPitchVariability != null && realPitchVariability! > 0.15) {
      signals.add(_Signal(
        'Pitch variability was elevated',
        '- ${(realPitchVariability! * 100).toStringAsFixed(0)}% (typical conversational range is ~10-15%)',
        kRed,
      ));
    }
    if (realJitterPercent != null && realJitterPercent! > 1.04) {
      signals.add(_Signal(
        'Voice jitter above typical range',
        '- ${realJitterPercent!.toStringAsFixed(2)}% (reference: <1.04%)',
        kRed,
      ));
    }
    if (realShimmerPercent != null && realShimmerPercent! > 3.81) {
      signals.add(_Signal(
        'Voice shimmer above typical range',
        '- ${realShimmerPercent!.toStringAsFixed(2)}% (reference: <3.81%)',
        kRed,
      ));
    }
    if (signals.isEmpty) {
      signals.add(_Signal(
        'Pitch, jitter, and shimmer all stayed within typical conversational range',
        null,
        kGreen,
      ));
    }

    return Container(
      color: kBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Anxiety / stress score',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kHeader)),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: levelColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text('$level ($score/100)',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: levelColor)),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text('WHY DETECTED — FROM ACOUSTIC FEATURES',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFAAAAAA),
                    letterSpacing: 0.3)),
          ),
          ...signals.map((s) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 4, right: 6),
                      decoration: BoxDecoration(
                          color: s.dotColor, shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF444444)),
                          children: [
                            TextSpan(text: s.text),
                            if (s.highlight != null)
                              TextSpan(
                                text: ' ${s.highlight}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: s.dotColor),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: score >= 65 ? kImprove : const Color(0xFFF0FDF6),
                borderRadius: BorderRadius.circular(10),
                border: score < 35
                    ? Border.all(color: kGreen, width: 1.2)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    score >= 65 ? 'HOW TO IMPROVE NEXT SESSION' : 'KEEP DOING THIS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: score >= 65 ? kPrimary : kGreen,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    score >= 65
                        ? 'Try box breathing before your next session: inhale 4 seconds, hold 4, exhale 4, hold 4. Repeat 4 times.'
                        : 'Your voice stayed steady and controlled — that vocal composure is genuinely hard to build, keep practicing at this level.',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF444444), height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: kDivider),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: kHeader,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_left_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 10),
              const Text('Therapist Report',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF3D2A7A), width: 5),
                      ),
                    ),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kYellow, width: 3),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasRealData ? '${100 - realAnxietyScore!}' : '74',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.0),
                        ),
                        const Text('/100',
                            style: TextStyle(
                                fontSize: 8,
                                color: Color(0xFFB9A8E8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Great session,',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2)),
                    const Text('Alex!',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: kYellow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        hasRealData ? 'Live pipeline result' : '+6 from last time',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kYellowDk),
                      ),
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

  // ── AI Therapist section label ─────────────────────────────────────────────
  Widget _buildSectionLabel() {
    return Container(
      color: const Color(0xFFF7F4FF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF7B3FDB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'AI\nTHERAPY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 6,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Therapist',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kHeader)),
              Text('Emotional analysis',
                  style: TextStyle(fontSize: 11, color: kSubtitle)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Emotion block with signals + improve (fallback example data) ───────────
  Widget _buildEmotionBlock({
    required String title,
    required String level,
    required Color levelColor,
    required Color dotColor,
    required String subLabel,
    required List<_Signal> signals,
    String? improve,
    String? keepDoing,
  }) {
    return Container(
      color: kBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kHeader)),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: dotColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(level,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: levelColor)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(subLabel,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFAAAAAA),
                    letterSpacing: 0.3)),
          ),
          ...signals.map((s) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 4, right: 6),
                      decoration: BoxDecoration(
                          color: s.dotColor, shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF444444)),
                          children: [
                            TextSpan(text: s.text),
                            if (s.highlight != null)
                              TextSpan(
                                text: ' ${s.highlight}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: kRed),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          if (improve != null || keepDoing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: keepDoing != null
                      ? const Color(0xFFF0FDF6)
                      : kImprove,
                  borderRadius: BorderRadius.circular(10),
                  border: keepDoing != null
                      ? Border.all(color: kGreen, width: 1.2)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      keepDoing != null
                          ? 'KEEP DOING THIS'
                          : 'HOW TO IMPROVE NEXT SESSION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: keepDoing != null ? kGreen : kPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      improve ?? keepDoing ?? '',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF444444), height: 1.5),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 14),

          Container(height: 1, color: kDivider),
        ],
      ),
    );
  }

  // ── Simple emotion row (no signals) ───────────────────────────────────────
  Widget _buildSimpleEmotion({
    required String title,
    required String level,
    required Color levelColor,
    required Color dotColor,
  }) {
    return Container(
      color: kBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kHeader)),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: dotColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(level,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: levelColor)),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: kDivider),
        ],
      ),
    );
  }

  // ── AI Insight ─────────────────────────────────────────────────────────────
  Widget _buildAIInsight() {
    return Container(
      color: kInsight,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI INSIGHT',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFAAAAAA),
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(height: 1, color: kDivider),
          const SizedBox(height: 10),
          Text(
            hasRealData
                ? '"Detected emotion: $realEmotionLabel, anxiety score: $realAnxietyScore/100 — based on real pitch, jitter, and shimmer measurements from this recording."'
                : '"Your words were clear - but your body gave you away. Slow your pace, own your pauses, and anxiety loses its grip."',
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: kHeader,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: kHeader,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: const Column(
        children: [
          Text('SPEAKORA',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          SizedBox(height: 4),
          Text('Generated: May 1, 2026 · Session #24',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10, color: Color(0xFFB9A8E8))),
        ],
      ),
    );
  }
}

// ── Signal data model ──────────────────────────────────────────────────────────
class _Signal {
  final String text;
  final String? highlight;
  final Color dotColor;
  const _Signal(this.text, this.highlight, this.dotColor);
}
