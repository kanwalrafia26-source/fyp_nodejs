import 'package:flutter/material.dart';
import 'speakquest_screen.dart';
import 'tongue_twister_screen.dart';

class TongueTwisterFailScreen extends StatelessWidget {
  final List<Map<String, dynamic>> attempts;
  final int bestScore;
  final bool hasRealData;

  const TongueTwisterFailScreen({
    super.key,
    required this.attempts,
    required this.bestScore,
    required this.hasRealData,
  });

  static const Color kBg       = Color(0xFF290451);
  static const Color kHeaderBg = Color(0xFF2F0A56);
  static const Color kCardBg   = Color(0xFFFAF6FF);
  static const Color kPrimary  = Color(0xFF290451);
  static const Color kYellow   = Color(0xFFD9E366);
  static const Color kYellowDk = Color(0xFF1A2000);
  static const Color kSubtitle = Color(0xFF9A70B0);
  static const Color kOrange   = Color(0xFFC07030);
  static const Color kPurple   = Color(0xFF5300AC);
  static const Color kCardBdr  = Color(0xFFEDE0FF);
  static const Color kAICard   = Color(0xFF290451);

  List<String> get _mispronounced {
    if (!hasRealData || attempts.isEmpty) return [];
    // Collect from worst attempt
    final worst = attempts.reduce((a, b) =>
        (a['score'] as int) <= (b['score'] as int) ? a : b);
    return (worst['lowConfidenceWords'] as List?)
            ?.map((e) => e.toString())
            .take(3)
            .toList() ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    final mis = _mispronounced;

    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),

            Container(
              color: kCardBg,
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ── Try cards ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: List.generate(attempts.length, (i) {
                        final score = attempts[i]['score'] as int;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                                right: i < attempts.length - 1 ? 10 : 0),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: kCardBdr, width: 1.5),
                            ),
                            child: Column(
                              children: [
                                Text('Try ${i + 1}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: kSubtitle)),
                                const SizedBox(height: 4),
                                Text(
                                  hasRealData ? '$score%' : '—',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: kOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Words to practise ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: kCardBdr, width: 1.5),
                      ),
                      padding:
                          const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Words to practise',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: kPrimary,
                              )),
                          const SizedBox(height: 10),
                          if (mis.isNotEmpty)
                            ...mis.map((w) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF8F0),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Text('"$w"',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFC07030),
                                        )),
                                  ),
                                ))
                          else
                            Text(
                              hasRealData
                                  ? 'No specific words flagged — keep pushing!'
                                  : 'Grant mic permission for word-level feedback.',
                              style: const TextStyle(
                                  fontSize: 11, color: kSubtitle),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── AI Tip ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.fromLTRB(18, 14, 18, 16),
                      decoration: BoxDecoration(
                        color: kAICard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('AI TIP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFC9A0E0),
                                letterSpacing: 1.0,
                              )),
                          SizedBox(height: 6),
                          Text(
                            '"Slow down by 50%. Say each word separately first, then blend."',
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

                  // ── Try again ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const TongueTwisterScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kYellow,
                          foregroundColor: kYellowDk,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Try again →',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
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
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Back to SpeakQuest',
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
      color: kHeaderBg,
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 28),
      child: Column(
        children: [
          const Text('Tongue Twister · Try again!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: kSubtitle)),
          const SizedBox(height: 14),
          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(
                  color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
            child: const Icon(Icons.sentiment_dissatisfied_rounded,
                color: Color(0xFFE6BEF0), size: 40),
          ),
          const SizedBox(height: 12),
          const Text('So close!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          const SizedBox(height: 4),
          const Text('Need 65% to pass · Level 3',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: kSubtitle)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: kYellow, size: 28),
              Icon(Icons.star_rounded,
                  color: Colors.white.withOpacity(0.15), size: 28),
              Icon(Icons.star_rounded,
                  color: Colors.white.withOpacity(0.15), size: 28),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hasRealData ? '$bestScore%' : '—',
            style: const TextStyle(
              fontSize: 62,
              fontWeight: FontWeight.w700,
              color: Color(0xFFC9A0E0),
              height: 1.1,
            ),
          ),
          Text(
            hasRealData
                ? 'Best try · Need 65% to pass'
                : 'Grant mic permission for real scores',
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF7A50A0)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
