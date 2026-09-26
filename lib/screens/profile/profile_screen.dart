import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/auth_service.dart';
import '../../core/app_flushbar.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../onboarding/avatar_picker_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsOn = true;
  bool get _darkMode => themeModeNotifier.value == ThemeMode.dark;

  // Editable user data — populated from Firebase/AuthService
  late String _name;
  String _language = 'English';

  // ── Real stats from session history ───────────────────────────────────────
  int    _sessionCount = 0;
  int    _avgScore     = 0;
  int    _dayStreak    = 0;
  bool   _statsLoaded  = false;

  static const List<String> _languages = [
    'English', 'Urdu', 'Arabic', 'French', 'Spanish', 'German'
  ];

  String get _email => AuthService.windowsEmail ?? 'user@example.com';

  @override
  void initState() {
    super.initState();
    AuthService.syncDisplayName();
    _name = AuthService.displayNameNotifier.value;
    AuthService.displayNameNotifier.addListener(_onNameChanged);
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final sessions = await ApiService.getSessions();
      if (!mounted) return;
      setState(() {
        _sessionCount = sessions.length;
        _avgScore     = _computeAvgScore(sessions);
        _dayStreak    = _computeDayStreak(sessions);
        _statsLoaded  = true;
      });
    } catch (_) {
      if (mounted) setState(() => _statsLoaded = true);
    }
  }

  int _computeAvgScore(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) return 0;
    final scores = sessions
        .map((s) => (s['fluencyScore'] as num?)?.toInt())
        .whereType<int>()
        .toList();
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) ~/ scores.length;
  }

  int _computeDayStreak(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) return 0;
    final dates = sessions
        .map((s) {
          final raw = s['createdAt'] as String?;
          if (raw == null) return null;
          final dt = DateTime.tryParse(raw);
          if (dt == null) return null;
          return DateTime(dt.year, dt.month, dt.day);
        })
        .whereType<DateTime>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (dates.isEmpty) return 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (todayDate.difference(dates.first).inDays > 1) return 0;
    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      if (dates[i].difference(dates[i + 1]).inDays == 1) {
        streak++;
      } else if (dates[i].difference(dates[i + 1]).inDays > 1) {
        break;
      }
    }
    return streak;
  }

  void _onNameChanged() {
    if (mounted) setState(() => _name = AuthService.displayNameNotifier.value);
  }

  @override
  void dispose() {
    AuthService.displayNameNotifier.removeListener(_onNameChanged);
    super.dispose();
  }

  // ── Colours ────────────────────────────────────────────────────────────────
  static const Color kBg       = Color(0xFFF5F0FF);
  static const Color kHeader   = Color(0xFF290451);
  static const Color kPrimary  = Color(0xFF5300AC);
  static const Color kYellow   = Color(0xFFD9E366);

  static const Color kSubtitle = Color(0xFF9A70B0);
  static const Color kRed      = Color(0xFFD05050);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header / Avatar ────────────────────────────────────
              _buildHeader(),

              const SizedBox(height: 20),

              // ── Stats row ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _statsLoaded
                    ? Row(
                        children: [
                          _StatChip(
                            value: '$_sessionCount',
                            label: 'Sessions',
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            value: _avgScore > 0 ? '$_avgScore%' : '—',
                            label: 'Avg Score',
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            value: '$_dayStreak',
                            label: 'Day Streak',
                            accent: kYellow,
                          ),
                        ],
                      )
                    : const SizedBox(
                        height: 64,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kPrimary,
                            ),
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              // ── Account section ────────────────────────────────────
              _SectionLabel('Account'),
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
                onTap: () => _showEditDialog(
                  title: 'Edit Name',
                  initial: _name,
                  hint: 'Your name',
                  onSave: (v) async {
                    setState(() => _name = v);
                    await AuthService.updateDisplayName(v);
                  },
                ),
              ),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                onTap: () => _showPasswordDialog(),
              ),
              _SettingsTile(
                icon: Icons.email_outlined,
                label: 'Email',
                trailing: Text(
                  _email,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9A70B0)),
                ),
                onTap: null,
              ),

              const SizedBox(height: 8),

              // ── Preferences section ────────────────────────────────
              _SectionLabel('Preferences'),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                trailing: Switch(
                  value: _notificationsOn,
                  onChanged: (v) => setState(() => _notificationsOn = v),
                  activeColor: kPrimary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onTap: null,
              ),
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                label: 'Dark Mode',
                trailing: Switch(
                  value: _darkMode,
                  onChanged: (v) {
                    themeModeNotifier.value =
                        v ? ThemeMode.dark : ThemeMode.light;
                    setState(() {});
                  },
                  activeColor: kPrimary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onTap: null,
              ),
              _SettingsTile(
                icon: Icons.language_outlined,
                label: 'Language',
                trailing: Text(
                  _language,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9A70B0)),
                ),
                onTap: null,
              ),

              const SizedBox(height: 8),

              // ── Support section ────────────────────────────────────
              _SectionLabel('Support'),
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & FAQ',
                onTap: null,
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: 'About',
                trailing: const Text(
                  'v1.0.0',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9A70B0)),
                ),
                onTap: () {},
              ),

              const SizedBox(height: 8),

              // ── Danger zone ────────────────────────────────────────
              _SectionLabel('Account Actions'),
              _SettingsTile(
                icon: Icons.logout_rounded,
                label: 'Log Out',
                labelColor: kRed,
                iconColor: kRed,
                onTap: () => _showLogoutDialog(context),
              ),

              const SizedBox(height: 28),
            ],
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
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              ValueListenableBuilder<String>(
                valueListenable: AuthService.avatarNotifier,
                builder: (_, avatarPath, __) => Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimary,
                    border: Border.all(color: kYellow, width: 3),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      avatarPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AvatarPickerScreen()),
                    );
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: kYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: Color(0xFF2A3D00),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            _name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            _email,
            style: const TextStyle(fontSize: 13, color: Color(0xFFB9A8E8)),
          ),

          const SizedBox(height: 12),

          // Silver badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: kYellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kYellow.withOpacity(0.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.workspace_premium_rounded,
                    color: kYellow, size: 16),
                SizedBox(width: 6),
                Text(
                  'Silver · 340 XP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kYellow,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit field dialog ───────────────────────────────────────────────────────
  void _showEditDialog({
    required String title,
    required String initial,
    required String hint,
    required Future<void> Function(String) onSave,
    TextInputType keyboard = TextInputType.text,
  }) {
    final ctrl = TextEditingController(text: initial);
    showDialog(
      context: context,
      builder: (dialogContext) => _EditNameDialog(
        title: title,
        hint: hint,
        ctrl: ctrl,
        keyboard: keyboard,
        onSave: (value) async {
          await onSave(value);
        },
      ),
    );
  }

  // ── Change password dialog ───────────────────────────────────────────────────
  void _showPasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isLoading    = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Password',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(
                  ctrl: currentCtrl,
                  hint: 'Current password',
                  obscure: true),
              const SizedBox(height: 10),
              _DialogField(
                  ctrl: newCtrl,
                  hint: 'New password (min 8, A-Z, a-z, 0-9)',
                  obscure: true),
              const SizedBox(height: 10),
              _DialogField(
                  ctrl: confirmCtrl,
                  hint: 'Confirm new password',
                  obscure: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF9A70B0))),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      final error = await AuthService.changePassword(
                        currentPassword: currentCtrl.text,
                        newPassword: newCtrl.text,
                        confirmPassword: confirmCtrl.text,
                      );
                      setDialogState(() => isLoading = false);
                      if (!mounted) return;
                      if (error != null) {
                        showFlushbar(context, error);
                      } else {
                        Navigator.pop(ctx);
                        showFlushbar(context, '✅ Password updated! Please log in again.', isError: false);
                        await Future.delayed(const Duration(seconds: 2));
                        if (mounted) {
                          await AuthService.logout();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (_) => false,
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5300AC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Language picker ──────────────────────────────────────────────────────────
  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select Language',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF290451),
              ),
            ),
            const SizedBox(height: 12),
            ..._languages.map((lang) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(lang,
                      style: const TextStyle(fontSize: 14)),
                  trailing: _language == lang
                      ? const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF5300AC))
                      : null,
                  onTap: () {
                    setState(() => _language = lang);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  // ── Logout dialog ───────────────────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9A70B0))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await AuthService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

}

// ── Stat chip ──────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color? accent;

  static const Color kPrimary = Color(0xFF5300AC);

  const _StatChip({required this.value, required this.label, this.accent});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: accent != null
              ? accent!.withOpacity(0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent != null
                ? accent!.withOpacity(0.4)
                : const Color(0xFFE0D6FF),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: accent ?? kPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF9A70B0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog text field helper ───────────────────────────────────────────────────
class _DialogField extends StatefulWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool obscure;
  const _DialogField(
      {required this.ctrl, required this.hint, this.obscure = false});

  @override
  State<_DialogField> createState() => _DialogFieldState();
}

class _DialogFieldState extends State<_DialogField> {
  late bool _hide;

  @override
  void initState() {
    super.initState();
    _hide = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.ctrl,
      obscureText: _hide,
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: true,
        fillColor: const Color(0xFFF3E8FF),
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                  _hide ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: const Color(0xFF9A70B0),
                ),
                onPressed: () => setState(() => _hide = !_hide),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0D6FF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0D6FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5300AC), width: 1.5),
        ),
      ),
    );
  }
}
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9A70B0),
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// ── Settings tile ──────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  static const Color kPrimary = Color(0xFF5300AC);

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.labelColor,
    this.iconColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0D6FF), width: 1),
            ),
            child: Row(
              children: [
                Icon(icon,
                    color: iconColor ?? kPrimary.withOpacity(0.7), size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: labelColor ?? Colors.black87,
                    ),
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (onTap != null)
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFCCBBEE), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Edit name dialog ───────────────────────────────────────────────────────────
class _EditNameDialog extends StatefulWidget {
  final String title;
  final String hint;
  final TextEditingController ctrl;
  final TextInputType keyboard;
  final Future<void> Function(String) onSave;

  const _EditNameDialog({
    required this.title,
    required this.hint,
    required this.ctrl,
    required this.keyboard,
    required this.onSave,
  });

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      content: TextField(
        controller: widget.ctrl,
        keyboardType: widget.keyboard,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hint,
          filled: true,
          fillColor: const Color(0xFFF3E8FF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0D6FF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0D6FF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF5300AC), width: 1.5),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: Color(0xFF9A70B0))),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  final value = widget.ctrl.text.trim();
                  if (value.isEmpty) return;
                  setState(() => _isLoading = true);
                  await widget.onSave(value);
                  if (mounted) Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5300AC),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
