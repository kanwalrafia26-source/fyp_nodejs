import 'package:flutter/material.dart';
import '../session/session_setup_screen.dart';
import '../simulation/simulation_screen.dart';
import '../games/speakquest_screen.dart';
import '../progress/progress_screen.dart';
import '../../core/app_nav.dart';
import '../../core/auth_service.dart';
import '../details/audio_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  // ── Colours ──────────────────────────────────────────────────────────────
  static const Color kBg         = Color(0xFFEFE8F8); // light lavender page bg
  static const Color kHeaderBg   = Color(0xFF290451); // dark purple header
  static const Color kCardPurple = Color(0xFF5300AC); // Dual AI card
  static const Color kCardWhite  = Color(0xFFFFFFFF);
  static const Color kBorder     = Color(0xFFE6C6F7); // card border tint
  static const Color kPrimary    = Color(0xFF5300AC);
  static const Color kSubtext    = Color(0xFF9B7EC8);
  static const Color kNavActive  = Color(0xFF5300AC);
  static const Color kNavInactive= Color(0xFFAAAAAA);
  static const Color kStreakBg   = Color(0xFF3A1260);
  static const Color kSessionBg  = Color(0xFF3A1260);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header card ─────────────────────────────────────────
                  _buildHeader(),

                  const SizedBox(height: 22),

                  // ── "What do you want to practice?" ────────────────────
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'What do you want to practice?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Practice grid ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Row 1
                        Row(
                          children: [
                            Expanded(child: GestureDetector(
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const SessionSetupScreen())),
                              child: _DualAICard(),
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: GestureDetector(
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const SimulationScreen())),
                              child: _PracticeCard(
                              icon: Icons.chat_bubble_outline_rounded,
                              iconColor: kPrimary,
                              title: 'Simulation',
                              subtitle: 'Real-world scenes',
                            ))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Row 2
                        Row(
                          children: [
                            Expanded(child: GestureDetector(
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const SpeakQuestScreen())),
                              child: _PracticeCard(
                              customIcon: _StarIcon(),
                              title: 'SpeakQuest',
                              subtitle: 'Games & rewards',
                            ))),
                            const SizedBox(width: 12),
                            Expanded(child: GestureDetector(
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ProgressScreen())),
                              child: _PracticeCard(
                              icon: Icons.show_chart_rounded,
                              iconColor: Colors.blue,
                              title: 'Progress',
                              subtitle: 'Your growth chart',
                            ))),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Tip of the day ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: kCardWhite,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9C4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text('💡', style: TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tip of the day',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Slow down — clarity always beats speed.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── DEBUG: Audio test ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const AudioTestScreen())),
                      icon: const Icon(Icons.mic_rounded),
                      label: const Text('🧪 Audio Pipeline Test'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5300AC),
                        side: const BorderSide(color: Color(0xFF5300AC)),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Bottom nav ────────────────────────────────────────────────
          _buildBottomNav(),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background rectangle: #290451, radius 32
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
          decoration: const BoxDecoration(
            color: kHeaderBg,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: greeting text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning,',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        ValueListenableBuilder<String>(
                          valueListenable: AuthService.displayNameNotifier,
                          builder: (_, name, __) => Row(
                            children: [
                              Text(
                                '$name ',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const Text('👋', style: TextStyle(fontSize: 28)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right: streak badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: kStreakBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      children: [
                        Text('🔥', style: TextStyle(fontSize: 22)),
                        SizedBox(height: 2),
                        Text(
                          '7 days',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'streak',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFC097D8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Last session score pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: kSessionBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: kPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: Color(0xFFC097D8),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last session score: 74%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tap to view full report ...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFC097D8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Decorative border overlay: rgba(255,255,255,0.05) fill,
        // 11px solid rgba(230,198,247,0.75), radius 55
        Positioned(
          top: -43,
          left: -7,
          right: -7,
          child: IgnorePointer(
            child: Container(
              height: 382,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(55),
                border: Border.all(
                  color: const Color(0xFFE6C6F7).withOpacity(0.75),
                  width: 11,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      (Icons.home_rounded,          'Home'),
      (Icons.download_rounded,      'Progress'),
      (Icons.headset_mic_outlined,  'Support'),
      (Icons.person_outline_rounded,'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = _navIndex == i;
          return GestureDetector(
            onTap: () => navigateTo(context, i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  items[i].$1,
                  color: active ? kNavActive : kNavInactive,
                  size: 24,
                ),
                const SizedBox(height: 3),
                Text(
                  items[i].$2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w400,
                    color: active ? kNavActive : kNavInactive,
                  ),
                ),
                if (active) ...[
                  const SizedBox(height: 3),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: kNavActive,
                      shape: BoxShape.circle,
                    ),
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

// ── Dual AI card (purple, large) ─────────────────────────────────────────────
class _DualAICard extends StatelessWidget {
  static const Color kPrimary = Color(0xFF5300AC);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.mic_rounded,
                color: Color(0xFFC097D8), size: 22),
          ),
          const Spacer(),
          const Text(
            'Dual AI',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Coach + Therapist',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Generic practice card (white) ────────────────────────────────────────────
class _PracticeCard extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Widget? customIcon;
  final String title;
  final String subtitle;

  const _PracticeCard({
    this.icon,
    this.iconColor,
    this.customIcon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: customIcon ??
                  Icon(icon!, color: iconColor ?? Colors.black54, size: 22),
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Star icon for SpeakQuest ──────────────────────────────────────────────────
class _StarIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF9C4),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text('⭐', style: TextStyle(fontSize: 14)),
      ),
    );
  }
}
