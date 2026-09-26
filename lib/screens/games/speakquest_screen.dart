import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'mirror_talk_screen.dart';
import 'tongue_twister_screen.dart';
import 'story_builder_screen.dart';

class SpeakQuestScreen extends StatefulWidget {
  const SpeakQuestScreen({super.key});

  @override
  State<SpeakQuestScreen> createState() => _SpeakQuestScreenState();
}

class _SpeakQuestScreenState extends State<SpeakQuestScreen> {
  int _selectedGame = 1;

  // ── Real XP from session history ───────────────────────────────────────────
  // XP formula: sessionCount × 30 + avgFluency × 2
  // Tiers: Bronze 0–199, Silver 200–499, Gold 500+
  int  _xp         = 0;
  bool _xpLoaded   = false;

  static const int _silverThreshold = 200;
  static const int _goldThreshold   = 500;

  @override
  void initState() {
    super.initState();
    _loadXP();
  }

  Future<void> _loadXP() async {
    try {
      final sessions = await ApiService.getSessions();
      if (!mounted) return;
      final count = sessions.length;
      final scores = sessions
          .map((s) => (s['fluencyScore'] as num?)?.toInt())
          .whereType<int>()
          .toList();
      final avgFluency =
          scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) ~/ scores.length;
      final xp = count * 30 + avgFluency * 2;
      setState(() { _xp = xp; _xpLoaded = true; });
    } catch (_) {
      if (mounted) setState(() => _xpLoaded = true);
    }
  }

  String get _tier {
    if (_xp >= _goldThreshold) return 'Gold';
    if (_xp >= _silverThreshold) return 'Silver';
    return 'Bronze';
  }

  int get _nextThreshold =>
      _xp >= _goldThreshold ? _goldThreshold : (_xp >= _silverThreshold ? _goldThreshold : _silverThreshold);

  String get _nextTierName =>
      _xp >= _goldThreshold ? 'Max' : (_xp >= _silverThreshold ? 'Gold' : 'Silver');

  // ── Colours ────────────────────────────────────────────────────────────────
  static const Color kBg         = Color(0xFFF5F0FF);
  static const Color kHeader     = Color(0xFF290451);
  static const Color kHeaderSub  = Color(0xFF3A0870);
  static const Color kYellow     = Color(0xFFD9E366);
  static const Color kYellowDark = Color(0xFF1A2000);
  static const Color kPrimary    = Color(0xFF5300AC);
  static const Color kSubtitle   = Color(0xFF9A70B0);
  static const Color kCardWhite  = Color(0xFFFFFFFF);
  static const Color kCardPurple = Color(0xFF5300AC);
  static const Color kNavInactive= Color(0xFFC0A0D8);
  static const Color kProgressBg = Color(0x1AFFFFFF); // rgba(255,255,255,0.1)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          _buildHeader(),

          // ── Scrollable content ───────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Daily challenge
                  _buildDailyChallenge(),

                  const SizedBox(height: 18),

                  // GAMES label
                  const Text(
                    'GAMES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: kNavInactive,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Mirror Talk
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedGame = 0);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MirrorTalkScreen()),
                      );
                    },
                    child: _GameCard(
                      selected: _selectedGame == 0,
                      iconBg: _selectedGame == 0
                          ? Colors.white.withOpacity(0.1)
                          : const Color(0xFFF0E8FF),
                      iconColor: _selectedGame == 0
                          ? const Color(0xFFE6BEF0)
                          : kPrimary,
                      icon: Icons.person_rounded,
                      title: 'Mirror Talk',
                      subtitle: 'Speak. AI mirrors your emotion.',
                      xp: '+30 XP',
                      xpBg: _selectedGame == 0
                          ? kYellow
                          : const Color(0xFFF0E8FF),
                      xpColor: _selectedGame == 0 ? kYellowDark : kPrimary,
                      titleColor: _selectedGame == 0 ? Colors.white : kHeader,
                      subtitleColor: _selectedGame == 0
                          ? const Color(0xFFC9A0E0)
                          : const Color(0xFF9070B0),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Tongue Twister
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedGame = 1);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TongueTwisterScreen()),
                      );
                    },
                    child: _GameCard(
                      selected: _selectedGame == 1,
                      iconBg: _selectedGame == 1
                          ? Colors.white.withOpacity(0.1)
                          : const Color(0xFFF0E8FF),
                      iconColor: _selectedGame == 1
                          ? const Color(0xFFE6BEF0)
                          : kPrimary,
                      icon: Icons.menu_rounded,
                      title: 'Tongue Twister',
                      subtitle: 'Beat the clock. Nail every sound.',
                      xp: '+40 XP',
                      xpBg: _selectedGame == 1
                          ? kYellow
                          : const Color(0xFFF0E8FF),
                      xpColor: _selectedGame == 1 ? kYellowDark : kPrimary,
                      titleColor: _selectedGame == 1 ? Colors.white : kHeader,
                      subtitleColor: _selectedGame == 1
                          ? const Color(0xFFC9A0E0)
                          : const Color(0xFF9070B0),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Story Builder
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedGame = 2);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const StoryBuilderScreen()),
                      );
                    },
                    child: _GameCard(
                      selected: _selectedGame == 2,
                      iconBg: _selectedGame == 2
                          ? Colors.white.withOpacity(0.1)
                          : const Color(0xFFF5FFD0),
                      iconColor: _selectedGame == 2
                          ? const Color(0xFFE6BEF0)
                          : kYellow,
                      icon: Icons.layers_rounded,
                      title: 'Story Builder',
                      subtitle: 'AI starts. You continue it.',
                      xp: '+50 XP',
                      xpBg: _selectedGame == 2
                          ? kYellow
                          : const Color(0xFFF0E8FF),
                      xpColor: _selectedGame == 2 ? kYellowDark : kPrimary,
                      titleColor: _selectedGame == 2 ? Colors.white : kHeader,
                      subtitleColor: _selectedGame == 2
                          ? const Color(0xFFC9A0E0)
                          : const Color(0xFF9070B0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header block ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final xpDisplay  = _xpLoaded ? '$_xp' : '—';
    final tierLabel  = _xpLoaded ? '$_tier' : '...';
    final toNext     = _xpLoaded && _xp < _goldThreshold
        ? '$_xp / $_nextThreshold'
        : (_xp >= _goldThreshold ? 'Max rank' : '$_xp / $_nextThreshold');
    final progress   = _xpLoaded && _nextThreshold > 0
        ? (_xp / _nextThreshold).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      color: kHeader,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button — matches simulation screen style
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SpeakQuest',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.21,
                        )),
                    const SizedBox(height: 4),
                    const Text('Play. Speak. Level up.',
                        style: TextStyle(
                            fontSize: 13, color: kSubtitle, height: 1.23)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(xpDisplay,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: kYellow,
                        height: 1.2,
                      )),
                  Text('XP · $tierLabel',
                      style:
                          const TextStyle(fontSize: 11, color: kSubtitle)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kHeaderSub.withOpacity(0.8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progress to $_nextTierName',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFB090D0))),
                    Text(toNext,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kYellow,
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(kYellow),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Daily challenge banner ───────────────────────────────────────────────────
  Widget _buildDailyChallenge() {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedGame = 1);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TongueTwisterScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kYellow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.star_rounded,
                  color: Color(0xFF1A2000), size: 26),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily challenge',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kYellowDark,
                      )),
                  SizedBox(height: 2),
                  Text('Say it perfectly in 3 tries · +50 XP',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF3A4800))),
                ],
              ),
            ),
            const Text('Go →',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kYellowDark,
                )),
          ],
        ),
      ),
    );
  }

}

// ── Game card ──────────────────────────────────────────────────────────────────
class _GameCard extends StatelessWidget {
  final bool selected;
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final String xp;
  final Color xpBg;
  final Color xpColor;
  final Color titleColor;
  final Color subtitleColor;

  static const Color kPrimary = Color(0xFF5300AC);

  const _GameCard({
    required this.selected,
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.xp,
    required this.xpBg,
    required this.xpColor,
    required this.titleColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: selected ? kPrimary : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: kPrimary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          // Icon box
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: subtitleColor),
                ),
              ],
            ),
          ),
          // XP badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: xpBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              xp,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: xpColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
