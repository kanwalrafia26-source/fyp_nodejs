import 'package:flutter/material.dart';
import 'speakquest_screen.dart';
import 'story_builder_screen.dart';

class StoryBuilderFailScreen extends StatelessWidget {
  final List<Map<String, dynamic>> turnResults;
  final int turnsCompleted;
  final int durationSeconds;

  const StoryBuilderFailScreen({
    super.key,
    required this.turnResults,
    required this.turnsCompleted,
    required this.durationSeconds,
  });

  // ── Derived values ─────────────────────────────────────────────────────────
  bool get _hasReal =>
      turnResults.any((t) => t['hasRealData'] == true);

  /// Join all real transcripts — with filler markers highlighted.
  String get _storyText {
    final parts = turnResults
        .where((t) => (t['transcript'] as String).isNotEmpty)
        .map((t) => (t['transcript'] as String).trim())
        .toList();
    if (parts.isEmpty) return '(no speech captured)';
    return parts.join(' ');
  }

  /// Average fluency across completed turns with real data.
  int get _avgFluency {
    final scores = turnResults
        .where((t) => t['hasRealData'] == true)
        .map((t) => t['fluencyScore'] as int)
        .toList();
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) ~/ scores.length;
  }

  /// Total filler words.
  int get _totalFillers => turnResults
      .map((t) => t['fillerWordCount'] as int)
      .fold(0, (a, b) => a + b);

  /// Turns where fluency < 60 — shown in "Where fluency dropped" section.
  List<Map<String, dynamic>> get _weakTurns => turnResults
      .where((t) =>
          t['hasRealData'] == true && (t['fluencyScore'] as int) < 60)
      .toList();

  // ── Colours ────────────────────────────────────────────────────────────────
  static const Color kBg      = Color(0xFFFAF6FF);
  static const Color kHeader  = Color(0xFF290451);
  static const Color kPrimary = Color(0xFF290451);
  static const Color kYellow  = Color(0xFFD9E366);
  static const Color kYellowDk= Color(0xFF1A2000);
  static const Color kSubtitle= Color(0xFF9A70B0);
  static const Color kOrange  = Color(0xFFC07030);
  static const Color kRed     = Color(0xFFD05050);
  static const Color kCardBdr = Color(0xFFEDE0FF);
  static const Color kAICard  = Color(0xFF290451);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),

            const SizedBox(height: 16),

            // ── Story so far ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kCardBdr, width: 1.5),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('STORY SO FAR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: kSubtitle,
                          letterSpacing: 1.0,
                        )),
                    const SizedBox(height: 8),
                    Text(
                      '"$_storyText"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: kPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _hasReal
                            ? '$_totalFillers filler word${_totalFillers == 1 ? '' : 's'} broke the flow'
                            : 'Grant mic permission for filler word count',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Where fluency dropped ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kCardBdr, width: 1.5),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Where fluency dropped',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        )),
                    const SizedBox(height: 12),
                    if (_weakTurns.isEmpty)
                      Text(
                        _hasReal
                            ? 'No turns with fluency below 60% — good effort!'
                            : 'Grant mic permission to see real fluency data.',
                        style: const TextStyle(
                            fontSize: 11, color: kSubtitle),
                      )
                    else
                      ..._weakTurns.map((t) {
                        final score = t['fluencyScore'] as int;
                        final color = score < 40 ? kRed : kOrange;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _FluencyRow(
                            label: 'Turn ${t['turn']}',
                            fill: score / 100,
                            percent: '$score%',
                            color: color,
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

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
                  children: [
                    const Text('AI SAYS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC9A0E0),
                          letterSpacing: 1.0,
                        )),
                    const SizedBox(height: 6),
                    Text(
                      _hasReal && _weakTurns.isNotEmpty
                          ? '"Fluency dipped on ${_weakTurns.length} turn${_weakTurns.length == 1 ? '' : 's'}. Keep sentences short — one clear idea per turn."'
                          : '"Keep sentences short — one clear idea per turn."',
                      style: const TextStyle(
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
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StoryBuilderScreen()),
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
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
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
      decoration: const BoxDecoration(
        color: kHeader,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 28),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(
                  color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: Color(0xFFE6BEF0), size: 36),
          ),
          const SizedBox(height: 14),
          const Text('Story unfinished',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          const SizedBox(height: 4),
          Text(
            '$turnsCompleted of 10 turns · Fluency broke',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF9A70B0)),
          ),
          const SizedBox(height: 16),
          // Score badge — real avg fluency, not hardcoded 52%
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasReal ? '$_avgFluency%' : '—',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC9A0E0),
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Avg fluency',
                        style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF7A50A0))),
                    Text(
                      _hasReal ? 'Needs work' : 'No mic data',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC07030),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fluency row ────────────────────────────────────────────────────────────────
class _FluencyRow extends StatelessWidget {
  final String label;
  final double fill;
  final String percent;
  final Color color;

  const _FluencyRow({
    required this.label,
    required this.fill,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF9A70B0))),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: LinearProgressIndicator(
              value: fill,
              minHeight: 7,
              backgroundColor: const Color(0xFFF0E8FF),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(percent,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color)),
      ],
    );
  }
}
