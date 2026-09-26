import 'package:flutter/material.dart';
import '../../core/auth_service.dart';
import '../../services/api_service.dart';
import '../../core/app_flushbar.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _messageCtrl = TextEditingController();
  int _expandedFaq   = -1;
  bool _submitted    = false;
  bool _isLoading    = false;

  // ── Colours ────────────────────────────────────────────────────────────────
  static const Color kBg       = Color(0xFFF5F0FF);
  static const Color kHeader   = Color(0xFF290451);
  static const Color kPrimary  = Color(0xFF5300AC);
  static const Color kYellow   = Color(0xFFD9E366);
  static const Color kSubtitle = Color(0xFF9A70B0);
  static const Color kCardBg   = Color(0xFFFFFFFF);
  static const Color kFieldBg  = Color(0xFFF3E8FF);
  static const Color kBorder   = Color(0xFFE0D6FF);

  static const _faqs = [
    (
      'How does the AI Coach work?',
      'The AI Coach listens to your speech in real time and gives instant feedback on pronunciation, fluency, and pacing. It adapts to your level over time.'
    ),
    (
      'What is the AI Therapist?',
      'The AI Therapist analyses your emotional tone, anxiety levels, and vocal confidence. It helps you speak with more emotional clarity and calm.'
    ),
    (
      'How is my score calculated?',
      'Your session score is a weighted average of pronunciation accuracy, fluency, pacing, volume, and emotional expression across all turns.'
    ),
    (
      'Can I use the app offline?',
      'Core features require an internet connection for AI processing. Your progress data is cached locally and syncs when you reconnect.'
    ),
    (
      'How do I reset my progress?',
      'Go to Profile → Settings → Reset Progress. This will clear all session history and scores. This action cannot be undone.'
    ),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────
              _buildHeader(),

              const SizedBox(height: 20),

              const SizedBox(height: 20),

              // ── FAQ section ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(_faqs.length, (i) {
                      final open = _expandedFaq == i;
                      return GestureDetector(
                        onTap: () => setState(
                            () => _expandedFaq = open ? -1 : i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: kCardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: open ? kPrimary : kBorder,
                              width: open ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _faqs[i].$1,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: open
                                              ? kPrimary
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      open
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: open ? kPrimary : kSubtitle,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                              if (open)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 14),
                                  child: Text(
                                    _faqs[i].$2,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Contact form ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kBorder, width: 1),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: _submitted
                      ? _buildSuccessState()
                      : _buildForm(),
                ),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.headset_mic_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "We're here to help",
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFFB9A8E8)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search bar removed
        ],
      ),
    );
  }

  // ── Contact form ────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Send us a message',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: kPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "We'll get back to you within 24 hours.",
          style: TextStyle(fontSize: 12, color: Colors.black45),
        ),
        const SizedBox(height: 16),
        _FormField(controller: _nameCtrl,    hint: 'Your name',    icon: Icons.person_outline_rounded),
        const SizedBox(height: 10),
        _FormField(controller: _emailCtrl,   hint: 'support@speakora.ai', icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
        const SizedBox(height: 10),
        _FormField(controller: _messageCtrl, hint: 'Describe your issue...', icon: Icons.edit_outlined, maxLines: 4),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () async {
              if (_nameCtrl.text.trim().isEmpty ||
                  _emailCtrl.text.trim().isEmpty ||
                  _messageCtrl.text.trim().isEmpty) {
                showFlushbar(context, 'Please fill all fields.');
                return;
              }
              setState(() => _isLoading = true);
              final error = await ApiService.sendSupportMessage(
                name:    _nameCtrl.text.trim(),
                email:   _emailCtrl.text.trim(),
                message: _messageCtrl.text.trim(),
              );
              if (!mounted) return;
              setState(() => _isLoading = false);
              if (error != null) {
                showFlushbar(context, error);
              } else {
                setState(() => _submitted = true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Send Message',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Success state ───────────────────────────────────────────────────────────
  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: Color(0xFF2D7A40), size: 36),
        ),
        const SizedBox(height: 14),
        const Text(
          'Message sent!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "We'll reply to your email within 24 hours.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.black45),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _submitted = false;
            _nameCtrl.clear();
            _emailCtrl.clear();
            _messageCtrl.clear();
          }),
          child: const Text(
            'Send another message',
            style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Bottom nav ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      (Icons.home_outlined,         'Home'),
      (Icons.show_chart_rounded,    'Progress'),
      (Icons.headset_mic_outlined,  'Support'),
      (Icons.person_outline_rounded,'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: kNavBg,
        border: Border(top: BorderSide(color: Color(0xFFE0D6FF), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = _navIndex == i;
          final color  = active ? kNavActive : kNavInact;
          return GestureDetector(
            onTap: () => navigateTo(context, i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(items[i].$1, color: color, size: 22),
                const SizedBox(height: 3),
                Text(
                  items[i].$2,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w400,
                    color: color,
                  ),
                ),
                if (active) ...[
                  const SizedBox(height: 2),
                  Container(
                    width: 4,
                    height: 4,
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

// ── Quick contact card ─────────────────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0D6FF), width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Form field ─────────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboard;

  const _FormField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D6FF), width: 1),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: maxLines > 1 ? 14 : 0,
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF9A70B0), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboard,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                    fontSize: 14, color: Color(0xFF9A70B0)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: maxLines > 1 ? 0 : 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
