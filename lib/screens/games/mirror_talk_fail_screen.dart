import 'package:flutter/material.dart';
import 'mirror_talk_screen.dart';
import 'speakquest_screen.dart';

class MirrorTalkFailScreen extends StatelessWidget {
  final List<Map<String, dynamic>> roundResults;
  final int overallScore;
  final bool hasRealData;

  const MirrorTalkFailScreen({
    super.key,
    required this.roundResults,
    required this.overallScore,
    required this.hasRealData,
  });

  static const Color kBg       = Color(0xFFFAF6FF);
  static const Color kHeader   = Color(0xFF290451);
  static const Color kPrimary  = Color(0xFF5300AC);
  static const Color kYellow   = Color(0xFFD9E366);
  static const Color kSubtitle = Color(0xFF9A70B0);
  static const Color kCardBg   = Color(0xFFFFFFFF);
  static const Color kOrange   = Color(0xFFC07030);
  static const Color kRed      = Color(0xFFD05050);
  static const Color kAICard   = Color(0xFF290451);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),

            // ── Round breakdown ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFEDE0FF), width: 1.5),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ROUND BREAKDOWN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: kSubtitle,
                          letterSpacing: 1.2,
                        )),
                    const SizedBox(height: 10),
                    ...List.generate(roundResults.length, (i) {
                      final r     = roundResults[i];
                      final score = r['expressionScore'] as int;
                      final emo   = r['emotion'] as String? ?? '—';
                      final stars = score >= 65 ? 2 : score >= 40 ? 1 : 0;
                      final color = score >= 65 ? kOrange : kRed;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RoundRow(
                          number: i + 1,
                          emotion: emo,
                          fill: score / 100,
                          percent: hasRealData ? '$score%' : '—',
                          barColor: color,
                          stars: stars,
                        ),
                      );
                    }),
                    if (!hasRealData)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Grant mic permission and replay for real scores.',
                          style: TextStyle(
                              fontSize: 10, color: kSubtitle),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── AI says ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: kAICard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('AI SAYS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC9A0E0),
                          letterSpacing: 1.0,
                        )),
                    SizedBox(height: 6),
                    Text(
                      '"Your emotions stayed flat. Try exaggerating — speak with your whole face. Go bigger!"',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Try again ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MirrorTalkScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kYellow,
                    foregroundColor: const Color(0xFF1A2000),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Try again →',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SpeakQuestScreen()),
                    (_) => false,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kSubtitle,
                    side: const BorderSide(
                        color: Color(0xFFE0D0F0), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Back to SpeakQuest',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: kHeader,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3A0870),
              border: Border.all(
                  color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
            child: const Icon(Icons.sentiment_dissatisfied_rounded,
                color: Color(0xFFE6BEF0), size: 42),
          ),
          const SizedBox(height: 14),
          const Text('Not quite there',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Mirror Talk · 5 rounds done',
              style: TextStyle(fontSize: 12, color: kSubtitle)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 28, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  hasRealData ? '$overallScore%' : 'No mic',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC9A0E0),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                const Text('Overall expression score',
                    style:
                        TextStyle(fontSize: 10, color: kSubtitle)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundRow extends StatelessWidget {
  final int number;
  final String emotion;
  final double fill;
  final String percent;
  final Color barColor;
  final int stars;

  const _RoundRow({
    required this.number, required this.emotion, required this.fill,
    required this.percent, required this.barColor, required this.stars,
  });

  static const Color kYellow  = Color(0xFFD9E366);
  static const Color kStarOff = Color(0xFFEDE0F8);
  static const Color kBarBg   = Color(0xFFF0E8FF);
  static const Color kPrimary = Color(0xFF5300AC);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22, height: 22,
          decoration: const BoxDecoration(
              color: kBarBg, shape: BoxShape.circle),
          child: Center(
            child: Text('$number',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kPrimary)),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(emotion,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF290451))),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: LinearProgressIndicator(
              value: fill, minHeight: 7,
              backgroundColor: kBarBg,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 34,
          child: Text(percent,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: barColor)),
        ),
        Row(
          children: List.generate(3, (i) => Icon(Icons.star_rounded,
              size: 12,
              color: i < stars ? kYellow : kStarOff)),
        ),
      ],
    );
  }
}
