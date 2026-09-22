import 'package:flutter/material.dart';
import 'simulation_active_screen.dart';

class SimulationAIRoleScreen extends StatefulWidget {
  final String scenarioName;
  final String scenarioEmoji;
  const SimulationAIRoleScreen({
    super.key,
    this.scenarioName = 'Client Discovery Call',
    this.scenarioEmoji = '📞',
  });

  @override
  State<SimulationAIRoleScreen> createState() =>
      _SimulationAIRoleScreenState();
}

class _SimulationAIRoleScreenState
    extends State<SimulationAIRoleScreen> {
  int _difficulty   = 1; // 0=Easy, 1=Medium, 2=Hard
  int _selectedRole = 0; // 0=Senior Web Dev, 1=HR, 2=CTO, 3=Panel, 4=Other
  int _selectedSubRole = 0; // sub-role chip index
  final _customCtrl = TextEditingController();

  static const Color kBg       = Color(0xFF1C0E4E);
  static const Color kCard     = Color(0xFF3D2490);
  static const Color kIconBg   = Color(0xFF2D1B69);
  static const Color kYellow   = Color(0xFFC8F55A);
  static const Color kYellowDk = Color(0xFF1C0E4E);
  static const Color kSubtitle = Color(0xFFB9A8E8);
  static const Color kMuted    = Color(0xFF7B6AB5);
  static const Color kRed      = Color(0xFFFF6B6B);
  static const Color kBtnBg    = Color(0xFFD9E366);
  static const Color kChipBg   = Color(0xFF2D1B69);
  static const Color kChipBdr  = Color(0xFF5B2DD9);

  static const _difficulties = ['Easy', 'Medium', 'Hard'];

  // Unique sub-role options per role
  static const _seniorDevRoles = [
    'Frontend Dev', 'Backend Dev', 'Full Stack Dev',
    'DevOps / Cloud', 'Mobile (React Native)', 'Or write yours',
  ];
  static const _hrRoles = [
    'Entry Level', 'Mid Level', 'Senior Level',
    'Manager', 'Director', 'Or write yours',
  ];
  static const _ctoRoles = [
    'Startup CTO', 'Enterprise CTO', 'VP Engineering',
    'Tech Lead', 'Engineering Manager', 'Or write yours',
  ];
  static const _panelRoles = [
    'Technical Panel', 'Behavioral Panel', 'Cross-functional',
    'Leadership Panel', 'Or write yours',
  ];

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ─────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Feature 2 · Step 2 of 3',
                                style: TextStyle(
                                    fontSize: 12, color: kSubtitle),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Assign AI Role',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pick a role, then tell ARIA the exact context',
                                style: TextStyle(
                                    fontSize: 13, color: kSubtitle),
                              ),
                            ],
                          ),
                        ),
                        const Text('✦',
                            style: TextStyle(
                                fontSize: 20,
                                color: kYellow,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Step indicator ─────────────────────────────
                    _buildStepIndicator(),

                    const SizedBox(height: 14),

                    // ── Scenario pill ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.scenarioEmoji,
                              style: const TextStyle(
                                  fontSize: 14, color: kYellow)),
                          const SizedBox(width: 8),
                          Text(
                            'Scenario:  ',
                            style: const TextStyle(
                                fontSize: 11, color: kSubtitle),
                          ),
                          Text(
                            widget.scenarioName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── SET DIFFICULTY ─────────────────────────────
                    const Text(
                      'SET DIFFICULTY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kYellow,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: List.generate(3, (i) {
                          final active = _difficulty == i;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _difficulty = i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: active ? kYellow : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _difficulties[i],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: active ? kYellowDk : kMuted,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── INTERVIEW ROLES ────────────────────────────
                    const Text(
                      'INTERVIEW ROLES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kYellow,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Senior Web Developer (expandable)
                    _buildRoleCard(
                      index: 0,
                      emoji: '💻',
                      title: 'Senior Web Developer',
                      subtitle: 'Grills you on tech depth, architecture,\nproblem-solving and system design',
                      badge: null,
                      expanded: _selectedRole == 0,
                      expandedContent: _buildSubRoleSection(
                        _seniorDevRoles,
                        label: 'What role are you interviewing for?',
                        hint: '✎ e.g. Creative Strategist, AI Engineer, Game Dev...',
                      ),
                    ),

                    const SizedBox(height: 8),

                    // HR Recruiter
                    _buildRoleCard(
                      index: 1,
                      emoji: '📋',
                      title: 'HR Recruiter',
                      subtitle: 'STAR method, values, situational questions,\nsalary discussion and team culture',
                      subBadge: 'Behavioral + culture fit',
                      badge: null,
                      expanded: _selectedRole == 1,
                      expandedContent: _buildSubRoleSection(
                        _hrRoles,
                        label: 'What level are you applying for?',
                        hint: '✎ e.g. HR Business Partner, Talent Acquisition...',
                      ),
                    ),

                    const SizedBox(height: 8),

                    // CTO / Tech Lead
                    _buildRoleCard(
                      index: 2,
                      emoji: '🛠',
                      title: 'CTO / Tech Lead',
                      subtitle: 'Scalability, trade-offs, past failures,\nleadership and architecture under pressure',
                      badge: 'Hard Mode',
                      badgeColor: kRed,
                      expanded: _selectedRole == 2,
                      expandedContent: _buildSubRoleSection(
                        _ctoRoles,
                        label: 'What leadership role?',
                        hint: '✎ e.g. Head of Engineering, Principal Architect...',
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Panel Interview
                    _buildRoleCard(
                      index: 3,
                      emoji: '👥',
                      title: 'Panel Interview',
                      subtitle: 'AI play — technical,\nbehavioural and leadership, turn by turn',
                      badge: 'Hard Mode',
                      badgeColor: kRed,
                      expanded: _selectedRole == 3,
                      expandedContent: _buildSubRoleSection(
                        _panelRoles,
                        label: 'What type of panel?',
                        hint: '✎ e.g. 3-person panel, mixed technical & HR...',
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Other
                    _buildRoleCard(
                      index: 4,
                      emoji: '✏️',
                      title: 'Other',
                      subtitle: 'Write the role &\nWhat role are you interviewing for?',
                      badge: null,
                      expanded: _selectedRole == 4,
                      expandedContent: _buildSubRoleSection(
                        const [],
                        label: 'Describe your role',
                        hint: '✎ e.g. Creative Strategist, AI Engineer, Game Dev...',
                        showChips: false,
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Start Session button ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    final difficultyLabel =
                        _difficulties[_difficulty];
                    final roleLabels = [
                      _seniorDevRoles,
                      _hrRoles,
                      _ctoRoles,
                      _panelRoles,
                      const <String>[],
                    ];
                    final subRoles = roleLabels[_selectedRole];
                    String roleName;
                    if (_selectedRole == 4) {
                      // "Other" — use whatever they typed
                      roleName = _customCtrl.text.trim().isNotEmpty
                          ? _customCtrl.text.trim()
                          : 'Custom Role';
                    } else {
                      roleName = (subRoles.isNotEmpty &&
                              _selectedSubRole < subRoles.length)
                          ? subRoles[_selectedSubRole]
                          : [
                              'Senior Web Developer',
                              'HR Recruiter',
                              'CTO / Tech Lead',
                              'Panel Interview',
                              'Other',
                            ][_selectedRole];
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SimulationActiveScreen(
                          roleName:     roleName,
                          scenarioName: widget.scenarioName,
                          difficulty:   difficultyLabel,
                          selectedAI:   2,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBtnBg,
                    foregroundColor: kYellowDk,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start Session',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, size: 22),
                    ],
                  ),
                ),
              ),
            ),

            // ── Back link ──────────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  '← Back to Scenario',
                  style: TextStyle(fontSize: 12, color: kMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Role card ──────────────────────────────────────────────────────────────
  Widget _buildRoleCard({
    required int index,
    required String emoji,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    String? subBadge,
    bool expanded = false,
    Widget? expandedContent,
  }) {
    final selected = _selectedRole == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = index),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: kYellow, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kIconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (subBadge != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            subBadge,
                            style: const TextStyle(
                                fontSize: 10, color: kMuted),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: kSubtitle,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge or checkmark
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? kRed).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeColor ?? kRed,
                      ),
                    ),
                  )
                else if (selected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: kYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: kYellowDk, size: 14),
                  ),
              ],
            ),
            // Expanded sub-content
            if (selected && expandedContent != null) ...[
              const SizedBox(height: 12),
              expandedContent,
            ],
          ],
        ),
      ),
    );
  }

  // ── Sub-role chips (reusable for all roles) ───────────────────────────────
  Widget _buildSubRoleSection(
    List<String> roles, {
    required String label,
    required String hint,
    bool showChips = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: kYellow,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Tap one — ARIA will ask questions for that exact role',
          style: TextStyle(fontSize: 10, color: kMuted),
        ),
        if (showChips && roles.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(roles.length, (i) {
              final active = _selectedSubRole == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedSubRole = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? kYellow : kChipBg,
                    borderRadius: BorderRadius.circular(8),
                    border: active
                        ? null
                        : Border.all(color: kChipBdr, width: 1),
                  ),
                  child: Text(
                    roles[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? kYellowDk : kSubtitle,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
        const SizedBox(height: 10),
        // Custom text field
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: kChipBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kChipBdr, width: 1),
          ),
          child: TextField(
            controller: _customCtrl,
            style: const TextStyle(fontSize: 12, color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  fontSize: 12, color: Color(0xFF4A5A6A)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  // ── Step indicator ─────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    final steps = ['Scenario', 'AI Role', 'Go Live'];
    final activeStep = 1; // Step 2 is active
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (i) {
        final active = i == activeStep;
        final done   = i < activeStep;
        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: active
                        ? kYellow
                        : done
                            ? kChipBdr.withOpacity(0.5)
                            : const Color(0xFF3D2A7A),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: active ? kYellowDk : kMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  steps[i],
                  style: TextStyle(
                    fontSize: 9,
                    color: active ? kYellow : kMuted,
                  ),
                ),
              ],
            ),
            if (i < steps.length - 1)
              Container(
                width: 28,
                height: 2,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: i < activeStep
                      ? kYellow
                      : const Color(0xFF3D2A7A),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        );
      }),
    );
  }
}
