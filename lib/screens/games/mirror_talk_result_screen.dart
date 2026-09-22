import 'package:flutter/material.dart';
import 'mirror_talk_screen.dart';

class MirrorTalkResultScreen extends StatelessWidget {
  final List<Map<String, dynamic>> roundResults;
  final int overallScore;
  final bool hasRealData;

  const MirrorTalkResultScreen({
    super.key,
    required this.roundResults,
    required this.overallScore,
    required this.hasRealData,
  });

  static const Color kBg       = Color(0xFFFAF6FF);
  static const Color kHeader   = Color(0xFF290451);
  static const Color kPrimary  = Color(0xFF5300AC);
  static const Color kYellow   = Color(0xFFD9E366);
  static const Color kYellowDk = Color(0xFF1A2000);
  static const Color kSubtitle = Color(0xFF9A70B0);
  static const Color kCardBg   = Color(0xFFFFFFFF);
  static const Color kGreen    = Color(0xFF2D7A40);
  static const Color kOrange   = Color(0xFFC07030);
  static const Color kXPCard   = Color(0xFF290451);

  String get _bestEmotion {
    if (roundResults.isEmpty) return '—';
    return roundResults.reduce((a, b) =>
        (a['expressionScore'] as int) >= (b['expressionScore'] as int)
            ? a
            : b)['emotion'] as String? ?? '—';
  }

  String get _worstEmotion {
    if (roundResults.isEmpty) return '—';
    return roundResults.reduce((a, b) =>
        (a['expressionScore'] as int) <= (b['expressionScore'] as int)
            ? a
            : b)['emotion'] as String? ?? '—';
  }

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
                      final r   = roundResults[i];
                      final score = r['expressionScore'] as int;
                      final emo   = r['emotion'] as String? ?? '—';
                      final stars = _starsForScore(score);
                      final color = score >= 75
                          ? kPrimary
                          : score >= 50
                              ? kOrange
                              : const Color(0xFFD05050);
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

            // ── Best / Needs work ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          const Text('Best emotion',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: kSubtitle)),
                          const SizedBox(height: 4),
                          Text(_bestEmotion,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: kGreen)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F0),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          const Text('Needs work',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: kSubtitle)),
                          const SizedBox(height: 4),
                          Text(_worstEmotion,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: kOrange)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── XP card ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: kXPCard,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('XP earned',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFC9A0E0))),
                          SizedBox(height: 4),
                          Text('+150 XP',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: kYellow,
                              )),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Badge unlocked',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFC9A0E0))),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A0870),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: kYellow.withOpacity(0.3),
                                width: 1),
                          ),
                          child: const Text('Emotion Master',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: kYellow,
                              )),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Buttons ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MirrorTalkScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF0E8FF),
                          foregroundColor: kHeader,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Play again',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kHeader,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Next game →',
                            style: TextStyle(
                                fontSize: 13,
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
              border:
                  Border.all(color: kYellow.withOpacity(0.35), width: 1.5),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: kYellow, size: 40),
          ),
          const SizedBox(height: 14),
          const Text('You nailed it!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Mirror Talk · All 5 rounds complete',
              style: TextStyle(fontSize: 12, color: kSubtitle)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 28, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF3A0870),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: kYellow.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  hasRealData ? '$overallScore%' : 'No mic',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: kYellow,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                const Text('Overall expression score',
                    style: TextStyle(fontSize: 10, color: kSubtitle)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _starsForScore(int score) {
    if (score >= 80) return 3;
    if (score >= 50) return 2;
    if (score > 0)   return 1;
    return 0;
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

  static const Color kYellow = Color(0xFFD9E366);
  static const Color kStarOff = Color(0xFFEDE0F8);
  static const Color kBarBg   = Color(0xFFF0E8FF);
  static const Color kPrimary = Color(0xFF5300AC);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22, height: 22,
          decoration: const BoxDecoration(color: kBarBg, shape: BoxShape.circle),
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
