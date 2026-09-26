import 'package:flutter/material.dart';
import 'avatar_picker_screen.dart';
import '../details/mic_check_screen.dart';
import 'date_picker_screen.dart';
import '../../core/auth_service.dart';
import '../main_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  int _selectedAvatar = 0;
  DateTime? _birthdate;

  static const Color kBg      = Color(0xFFF5F3EE); // warm off-white
  static const Color kPrimary = Color(0xFF5300AC); // deep violet
  static const Color kHighlight = Color(0xFFE8D5FF); // lavender highlight
  static const Color kFieldBg = Color(0xFFEDEBE6); // light grey field
  static const Color kDoneBtn = Color(0xFFB5CC3A); // yellow-green button
  static const Color kDoneTxt = Color(0xFFFFFFFF);

  // Avatar image paths
  static const List<String> _avatarAssets = [
    'assets/avator/avator1.png',
    'assets/avator/avator2.png',
    'assets/avator/avator3.png',
    'assets/avator/avator4.png',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await Navigator.push<DateTime>(
      context,
      MaterialPageRoute(
        builder: (_) => DatePickerScreen(initialDate: _birthdate),
      ),
    );
    if (picked != null) setState(() => _birthdate = picked);
  }

  String get _formattedDate {
    if (_birthdate == null) return 'Choose the date';
    return '${_birthdate!.day.toString().padLeft(2, '0')} / '
        '${_birthdate!.month.toString().padLeft(2, '0')} / '
        '${_birthdate!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Headline ─────────────────────────────────────────
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: kPrimary,
                          height: 1.25,
                        ),
                        children: [
                          TextSpan(text: "Let's set\n"),
                          WidgetSpan(
                            child: _HighlightedText(
                              text: 'up your profile!',
                              color: kHighlight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Your Name ─────────────────────────────────────────
                    const _SectionLabel('Your Name'),
                    const SizedBox(height: 10),
                    _PillField(
                      controller: _nameController,
                      hint: 'Name',
                    ),

                    const SizedBox(height: 32),

                    // ── Show your vibe ────────────────────────────────────
                    const _SectionLabel('Show your vibe'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        ...List.generate(4, (i) => _AvatarOption(
                          asset: _avatarAssets[i],
                          selected: _selectedAvatar == i,
                          onTap: () => setState(() => _selectedAvatar = i),
                        )),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked = await Navigator.push<int>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AvatarPickerScreen(),
                              ),
                            );
                            if (picked != null) {
                              setState(() => _selectedAvatar = picked);
                            }
                          },
                          child: Icon(Icons.expand_more_rounded,
                              color: kPrimary, size: 22),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ── Birthdate ─────────────────────────────────────────
                    const _SectionLabel('Select your birthdate'),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: kFieldBg,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formattedDate,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _birthdate == null
                                      ? Colors.black38
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            const Icon(Icons.expand_more_rounded,
                                color: Colors.black45, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Done button ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    // Save selected avatar
                    await AuthService.updateAvatar(_avatarAssets[_selectedAvatar]);
                    if (_nameController.text.trim().isNotEmpty) {
                      await AuthService.updateDisplayName(
                          _nameController.text.trim());
                    }
                    await AuthService.markProfileSetupDone();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                      (_) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDoneBtn,
                    foregroundColor: kDoneTxt,
                    elevation: 0,
                    minimumSize: const Size(220, 56),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Highlighted text block (lavender bg behind text) ──────────────────────
class _HighlightedText extends StatelessWidget {
  final String text;
  final Color color;
  const _HighlightedText({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: Color(0xFF5300AC),
          height: 1.25,
        ),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    );
  }
}

// ── Pill text field ────────────────────────────────────────────────────────
class _PillField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _PillField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEBE6),
        borderRadius: BorderRadius.circular(60),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 15, color: Colors.black38),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

// ── Avatar circle option ───────────────────────────────────────────────────
class _AvatarOption extends StatelessWidget {
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  const _AvatarOption({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: const Color(0xFF5300AC), width: 3)
              : Border.all(color: Colors.transparent, width: 3),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF5300AC).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: ClipOval(
          child: Image.asset(
            asset,
            width: 62,
            height: 62,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
