import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _tabIndex    = 0;
  int _skillTab    = 2;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _sessions = [];

  static const Color kBg       = Color(0xFFF5F0FF);
  static const Color kHeader   = Color(0xFF290451);
  static const Color kPrimary  = Color(0xFF5B2DD9);
  static const Color kGreen    = Color(0xFFC8F55A);
  static const Color kGreenDk  = Color(0xFF2A3D00);
  static const Color kCardBg   = Color(0xFFFFFFFF);
  static const Color kSubtitle = Color(0xFF999999);
  static const Color kAICard   = Color(0xFF290451);

  static const _tabs = ['Last session', 'Week', 'Month', '6 months'];
  static const _barColors = [
    Color(0xFF5B2DD9),
    Color(0xFF7C52E8),
    Color(0xFF9D7AF0),
    Color(0xFFBBA8F7),
  ];
  static const _barLabels = ['Pronun.', 'Fluency', 'Pacing', 'Clarity'];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sessions = await ApiService.getSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load session history.';
        _loading = false;
      });
    }
  }

  DateTime? _createdAt(Map<String, dynamic> s) {
    final raw = s['createdAt'] as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  List<Map<String, dynamic>> _sessionsForTab(int tabIndex) {
    if (_sessions.isEmpty) return [];
    if (tabIndex == 0) return [_sessions.first]; // most recent only

    final now = DateTime.now();
    final cutoffDays = tabIndex == 1 ? 7 : (tabIndex == 2 ? 30 : 180);
    return _sessions.where((s) {
      final created = _createdAt(s);
      if (created == null) return false;
      return now.difference(created).inDays <= cutoffDays;
    }).toList();
  }

  double _avg(List<Map<String, dynamic>> list, String key) {
    final values = list
        .map((e) => (e[key] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  List<double> _chartValuesForTab(int tabIndex) {
    final list = _sessionsForTab(tabIndex);
    if (list.isEmpty) return [0.0, 0.0, 0.0, 0.75];

    final pronunciation = _avg(list, 'pronunciationScore') / 100;
    final fluency = _avg(list, 'fluencyScore') / 100;

    final stableCount =
        list.where((e) => e['paceStability'] == 'Stable').length;
    final stableRatio = list.isEmpty ? 0.0 : stableCount / list.length;
    final pacing = 0.4 + stableRatio * 0.5; // scaled 0.4–0.9

    const clarity = 0.75; // not yet computed from real audio — placeholder

    return [
      pronunciation.clamp(0.0, 1.0),
      fluency.clamp(0.0, 1.0),
      pacing.clamp(0.0, 1.0),
      clarity,
    ];
  }

  int _dayStreak() {
    if (_sessions.isEmpty) return 0;
    final dates = _sessions
        .map(_createdAt)
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    // Streak only counts if there's a session today or yesterday — otherwise
    // it's broken.
    if (todayDate.difference(dates.first).inDays > 1) return 0;

    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final diff = dates[i].difference(dates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else if (diff > 1) {
        break;
      }
    }
    return streak;
  }

  String _formatPracticeTime() {
    final totalSeconds = _sessions
        .map((e) => (e['durationSeconds'] as num?)?.toInt() ?? 0)
        .fold<int>(0, (a, b) => a + b);
    if (totalSeconds < 60) return '$totalSeconds sec';
    final minutes = totalSeconds ~/ 60;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remMinutes = minutes % 60;
    return '${hours}h ${remMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final data = _chartValuesForTab(_tabIndex);
    final hasData = _sessions.isNotEmpty;
    final avgScore = hasData ? _avg(_sessions, 'fluencyScore').round() : 0;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSessions,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────
                _buildHeader(),

                const SizedBox(height: 16),

                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: CircularProgressIndicator(color: kPrimary),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Column(
                      children: [
                        Text(_error!,
                            style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadSessions,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  )
                else if (!hasData)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60, horizontal: 30),
                    child: Column(
                      children: [
                        Icon(Icons.bar_chart_rounded,
                            size: 48, color: kSubtitle),
                        SizedBox(height: 12),
                        Text(
                          'No sessions saved yet — complete a practice session and tap Save to start building your progress history.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: kSubtitle),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // ── Stats grid ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _StatCard(
                              value: '${_sessions.length}',
                              label: 'Sessions',
                              valueColor: kPrimary,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _StatCard(
                              value: '$avgScore%',
                              label: 'Avg score',
                              valueColor: kPrimary,
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _StatCard(
                              value: _formatPracticeTime(),
                              label: 'Practice time',
                              valueColor: kPrimary,
                              valueFontSize: 20,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _StatCard(
                              value: '${_dayStreak()}',
                              label: 'Day streak',
                              valueColor: kGreenDk,
                              labelColor: const Color(0xFF4A5E00),
                              bgColor: kGreen,
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Speech skills chart card ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: kCardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Speech skills',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: kPrimary,
                                ),
                              ),
                              Row(
                                children: [
                                  _SkillTab(
                                    label: 'Both',
                                    active: _skillTab == 2,
                                    onTap: () => setState(() => _skillTab = 2),
                                  ),
                                  const SizedBox(width: 6),
                                  _SkillTab(
                                    label: 'Coach',
                                    active: _skillTab == 0,
                                    onTap: () => setState(() => _skillTab = 0),
                                  ),
                                  const SizedBox(width: 6),
                                  _SkillTab(
                                    label: 'Therapist',
                                    active: _skillTab == 1,
                                    onTap: () => setState(() => _skillTab = 1),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            height: 200,
                            child: _BarChart(
                              values: data,
                              colors: _barColors,
                              labels: _barLabels,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Clarity is a placeholder — not yet computed from real audio.',
                              style: TextStyle(fontSize: 9, color: kSubtitle),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── AI insight card ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      decoration: BoxDecoration(
                        color: kAICard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: kGreen.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: kGreen, width: 2),
                            ),
                            child: const Icon(
                              Icons.show_chart_rounded,
                              color: kGreen,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _sessions.length >= 2
                                  ? '"You\'ve logged ${_sessions.length} sessions with an average fluency score of $avgScore%. Keep the streak going."'
                                  : '"This is your first saved session — practice a few more to start seeing real trends here."',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFE8E0FF),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: kHeader,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            "See how far you've come",
            style: TextStyle(fontSize: 12, color: Color(0xFFB9A8E8)),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(_tabs.length, (i) {
              final active = _tabIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _tabIndex = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFC8F55A)
                        : Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _tabs[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: active
                          ? const Color(0xFF1A1A1A)
                          : Colors.white,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

}

// ── Stat card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final Color? labelColor;
  final Color? bgColor;
  final double valueFontSize;

  const _StatCard({
    required this.value,
    required this.label,
    required this.valueColor,
    this.labelColor,
    this.bgColor,
    this.valueFontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: labelColor ?? const Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skill tab toggle ───────────────────────────────────────────────────────────
class _SkillTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  static const Color kPrimary = Color(0xFF5B2DD9);

  const _SkillTab(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: active
              ? null
              : Border.all(color: const Color(0xFFE0D6FF), width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? Colors.white : kPrimary,
          ),
        ),
      ),
    );
  }
}

// ── Bar chart ──────────────────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final List<String> labels;

  const _BarChart({
    required this.values,
    required this.colors,
    required this.labels,
  });

  static const _yLabels = ['100%', '75%', '50%', '25%', '0%'];
  static const _yValues = [1.0, 0.75, 0.50, 0.25, 0.0];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _yLabels
              .map((l) => Text(l,
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFFAAAAAA))))
              .toList(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(builder: (ctx, constraints) {
                  final chartH = constraints.maxHeight;
                  final chartW = constraints.maxWidth;
                  final barW   = (chartW - (values.length - 1) * 12) /
                      values.length;

                  return Stack(
                    children: [
                      ..._yValues.map((v) {
                        final y = chartH * (1 - v);
                        return Positioned(
                          top: y,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 1,
                            color: const Color(0xFFF0EAFF),
                          ),
                        );
                      }),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(values.length, (i) {
                          final barH = chartH * values[i];
                          final pct  =
                              '${(values[i] * 100).round()}%';
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right: i < values.length - 1 ? 12 : 0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    pct,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colors[i],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 400),
                                    curve: Curves.easeOut,
                                    height: (barH - 20).clamp(0.0, chartH),
                                    decoration: BoxDecoration(
                                      color: colors[i],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                        topRight: Radius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(labels.length, (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: i < labels.length - 1 ? 12 : 0),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF888888)),
                    ),
                  ),
                )),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
