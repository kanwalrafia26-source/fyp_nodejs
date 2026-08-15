import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import 'session_active_screen.dart';

class SessionSetupScreen extends StatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  int _selectedAI = 0;       // 0=Coach, 1=Therapist, 2=Both
  // 0=Live, 1=After, 2=Both — defaults to After since that's the mode
  // that's actually implemented right now (record → analyze → report).
  // Live streaming feedback isn't built yet, marked below.
  int _selectedFeedback = 1;

  // ── Colours ──────────────────────────────────────────────────────────────
  static const Color kBg          = Color(0xFFEFE8F8);
  static const Color kPrimary     = Color(0xFF2D0A52);
  static const Color kPurple      = Color(0xFF5300AC);
  static const Color kHighlight   = Color(0xFFE0D0FF);
  static const Color kCardWhite   = Color(0xFFFFFFFF);
  static const Color kCardDark    = Color(0xFF1E0840);
  static const Color kCardGreen   = Color(0xFFE8F0A0);
  static const Color kYellow      = Color(0xFFCDCC58);
  static const Color kSubtitle    = Color(0xFF9B7EC8);
  static const Color kLabel       = Color(0xFF9B7EC8);
  static const Color kBtnBg       = Color(0xFFD4A8F0);

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon — using After (report) mode for now.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Back button ─────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: kPurple,
                    size: 28,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Header card ─────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                decoration: BoxDecoration(
                  color: kCardWhite,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "Setup your" plain
                    const Text(
                      'Setup your',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: kPurple,
                        height: 1.15,
                      ),
                    ),
                    // "session!" highlighted
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: kHighlight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'session!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: kPurple,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Choose your AI and Feedback!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: kSubtitle,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── SELECT YOUR AI label ────────────────────────────────
              const Text(
                'SELECT YOUR AI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kLabel,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              // ── AI Coach ────────────────────────────────────────────
              _AIOptionCard(
                index: 0,
                selected: _selectedAI,
                onTap: () => setState(() => _selectedAI = 0),
                bgColor: _selectedAI == 0 ? kCardDark : kCardWhite,
                iconBg: _selectedAI == 0
                    ? const Color(0xFF3D1080)
                    : const Color(0xFFEDE0FF),
                icon: Icons.person_rounded,
                iconColor: _selectedAI == 0
                    ? const Color(0xFFC097D8)
                    : kPurple,
                title: 'AI Coach',
                titleColor: _selectedAI == 0 ? Colors.white : Colors.black87,
                subtitle: 'Pronunciation · Fluency',
                subtitleColor: _selectedAI == 0
                    ? const Color(0xFFC097D8)
                    : Colors.black45,
                showCheck: _selectedAI == 0,
                showRadio: _selectedAI != 0,
              ),

              const SizedBox(height: 10),

              // ── AI Therapist ────────────────────────────────────────
              _AIOptionCard(
                index: 1,
                selected: _selectedAI,
                onTap: () => setState(() => _selectedAI = 1),
                bgColor: _selectedAI == 1 ? kCardDark : kCardWhite,
                iconBg: _selectedAI == 1
                    ? const Color(0xFF3D1080)
                    : const Color(0xFFEDE0FF),
                icon: Icons.psychology_rounded,
                iconColor: _selectedAI == 1
                    ? const Color(0xFFC097D8)
                    : kPurple,
                title: 'AI Therapist',
                titleColor: _selectedAI == 1 ? Colors.white : Colors.black87,
                subtitle: 'Emotions · Anxiety · Tone',
                subtitleColor: _selectedAI == 1
                    ? const Color(0xFFC097D8)
                    : Colors.black45,
                showCheck: _selectedAI == 1,
                showRadio: _selectedAI != 1,
              ),

              const SizedBox(height: 10),

              // ── Both ────────────────────────────────────────────────
              GestureDetector(
                onTap: () => setState(() => _selectedAI = 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _selectedAI == 2
                        ? kCardDark
                        : kCardGreen,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      // Icon box
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _selectedAI == 2
                              ? const Color(0xFF3D1080)
                              : const Color(0xFFD4E060),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.people_rounded,
                          color: _selectedAI == 2
                              ? const Color(0xFFC097D8)
                              : const Color(0xFF4A5A00),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Both',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _selectedAI == 2
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: kCardDark,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Recommended',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Full coaching experience',
                              style: TextStyle(
                                fontSize: 13,
                                color: _selectedAI == 2
                                    ? const Color(0xFFC097D8)
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedAI == 2)
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: kYellow,
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 16),
                        )
                      else
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.black26, width: 1.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── FEEDBACK MODE label ─────────────────────────────────
              const Text(
                'FEEDBACK MODE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kLabel,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              // ── Feedback toggle row ─────────────────────────────────
              // Only "After" is real right now (record → analyze → report).
              // Live and Both are marked "Soon" rather than silently doing
              // nothing when tapped — see session_active/report_screen for
              // the actual implemented pipeline.
              Row(
                children: [
                  _FeedbackTab(
                    label: 'Live',
                    sublabel: 'During',
                    selected: _selectedFeedback == 0,
                    locked: true,
                    onTap: () => _showComingSoon('Live feedback'),
                  ),
                  const SizedBox(width: 10),
                  _FeedbackTab(
                    label: 'After',
                    sublabel: 'Report',
                    selected: _selectedFeedback == 1,
                    onTap: () => setState(() => _selectedFeedback = 1),
                  ),
                  const SizedBox(width: 10),
                  _FeedbackTab(
                    label: 'Both',
                    sublabel: 'All',
                    selected: _selectedFeedback == 2,
                    locked: true,
                    onTap: () => _showComingSoon('Combined live + report feedback'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Start Session button ────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SessionActiveScreen(
                              selectedAI: _selectedAI,
                            )),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBtnBg,
                    foregroundColor: kPrimary,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Start Session',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── AI option card ────────────────────────────────────────────────────────────
class _AIOptionCard extends StatelessWidget {
  final int index;
  final int selected;
  final VoidCallback onTap;
  final Color bgColor;
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final String subtitle;
  final Color subtitleColor;
  final bool showCheck;
  final bool showRadio;

  static const Color kYellow = Color(0xFFCDCC58);

  const _AIOptionCard({
    required this.index,
    required this.selected,
    required this.onTap,
    required this.bgColor,
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.titleColor,
    required this.subtitle,
    required this.subtitleColor,
    required this.showCheck,
    required this.showRadio,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                ],
              ),
            ),
            if (showCheck)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kYellow,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Feedback tab ──────────────────────────────────────────────────────────────
class _FeedbackTab extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;
  final bool locked;

  static const Color kCardDark  = Color(0xFF1E0840);
  static const Color kCardWhite = Color(0xFFFFFFFF);

  const _FeedbackTab({
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: locked ? 0.55 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected ? kCardDark : kCardWhite,
              borderRadius: BorderRadius.circular(16),
              border: locked
                  ? Border.all(color: Colors.black12, width: 1)
                  : null,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (locked) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.lock_outline_rounded,
                          size: 12, color: Colors.black45),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  locked ? 'Soon' : sublabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? const Color(0xFFC097D8)
                        : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
