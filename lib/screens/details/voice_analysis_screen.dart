import 'dart:math';
import 'package:flutter/material.dart';

class VoiceAnalysisScreen extends StatelessWidget {
  // All nullable — falls back to placeholder if not available
  final int?    realWpm;
  final int?    realLongPauseCount;
  final int?    realFillerWordCount;
  final double? realPitchMeanHz;
  final double? realPitchVariability;
  final double? realEnergyDb;
  final double? realJitterPercent;
  final double? realShimmerPercent;
  final String? realPaceStability;

  const VoiceAnalysisScreen({
    super.key,
    this.realWpm,
    this.realLongPauseCount,
    this.realFillerWordCount,
    this.realPitchMeanHz,
    this.realPitchVariability,
    this.realEnergyDb,
    this.realJitterPercent,
    this.realShimmerPercent,
    this.realPaceStability,
  });

  bool get _hasReal => realWpm != null || realPitchMeanHz != null;

  static const Color kBg       = Color(0xFFFFFFFF);
  static const Color kHeader   = Color(0xFF1C0E4E);
  static const Color kPrimary  = Color(0xFF5B2DD9);
  static const Color kRed      = Color(0xFFCC3333);
  static const Color kOrange   = Color(0xFFE8860A);
  static const Color kBarBg    = Color(0xFFEDE8FF);
  static const Color kSectionBg= Color(0xFFF7F4FF);
  static const Color kDivider  = Color(0xFFEDE8FF);
  static const Color kGrey     = Color(0xFF888888);
  static const Color kGreen    = Color(0xFF2D7A40);

  // ── Build real metric rows from actual data ────────────────────────────────
  List<_MetricData> _buildMetrics() {
    // Pitch — fill based on variability (0–40 Hz range → 0–1)
    final pitchFill  = realPitchVariability != null
        ? (realPitchVariability! / 40).clamp(0.0, 1.0)
        : 0.72;
    final pitchLabel = realPitchMeanHz != null
        ? '${realPitchMeanHz!.round()} Hz'
        : '72%';
    final pitchAlert = false;

    // Speed — fill wpm/180; alert if > 180 WPM (fast) or < 80 (slow)
    final speedFill  = realWpm != null
        ? (realWpm! / 180).clamp(0.0, 1.0)
        : 0.82;
    final speedLabel = realWpm != null ? '${realWpm!} WPM' : '82%';
    final speedAlert = realWpm != null && (realWpm! > 180 || realWpm! < 80);

    // Volume — fill from dB, normalised –45→0 dB
    final volFill  = realEnergyDb != null
        ? ((realEnergyDb! + 45) / 45).clamp(0.0, 1.0)
        : 0.78;
    final volLabel = realEnergyDb != null
        ? '${realEnergyDb!.round()} dB'
        : '78%';
    final volAlert = false;

    // Jitter — lower is better; inverted fill (ceiling 5%)
    final jitterFill  = realJitterPercent != null
        ? (1 - (realJitterPercent! / 5)).clamp(0.0, 1.0)
        : 0.82;
    final jitterBad   = realJitterPercent != null && realJitterPercent! > 1.04;
    final jitterLabel = realJitterPercent != null
        ? '${realJitterPercent!.toStringAsFixed(2)}%'
        : 'Low ✓';

    // Shimmer — inverted fill (ceiling 15%)
    final shimmerFill  = realShimmerPercent != null
        ? (1 - (realShimmerPercent! / 15)).clamp(0.0, 1.0)
        : 0.86;
    final shimmerBad   = realShimmerPercent != null && realShimmerPercent! > 3.81;
    final shimmerLabel = realShimmerPercent != null
        ? '${realShimmerPercent!.toStringAsFixed(1)}%'
        : 'Low ✓';

    // Pauses — inverted fill (ceiling 8 long pauses)
    final pauseFill  = realLongPauseCount != null
        ? (1 - min(realLongPauseCount!, 8) / 8).clamp(0.0, 1.0)
        : 0.55;
    final pauseLabel = realLongPauseCount != null
        ? '$realLongPauseCount long'
        : '55%';
    final pauseAlert = realLongPauseCount != null && realLongPauseCount! >= 3;

    // Fillers — inverted fill (ceiling 10)
    final fillerFill  = realFillerWordCount != null
        ? (1 - min(realFillerWordCount!, 10) / 10).clamp(0.0, 1.0)
        : 0.90;
    final fillerLabel = realFillerWordCount != null
        ? '$realFillerWordCount'
        : '3';
    final fillerAlert = realFillerWordCount != null && realFillerWordCount! >= 3;

    // Pacing
    final paceFill  = realPaceStability != null
        ? (realPaceStability == 'Stable' ? 0.85 : 0.45)
        : 0.80;
    final paceLabel = realPaceStability ?? '80%';
    final paceAlert = realPaceStability == 'Uneven';

    return [
      _MetricData('Pitch',           pitchFill,  kPrimary, pitchLabel,  pitchAlert),
      _MetricData('Speed',           speedFill,  kRed,     speedLabel,  speedAlert),
      _MetricData('Volume',          volFill,    kPrimary, volLabel,    volAlert),
      _MetricData('Tone · Jitter',   jitterFill, kOrange,  jitterLabel, jitterBad),
      _MetricData('Tone · Strained', shimmerFill,kOrange,  shimmerLabel,shimmerBad),
      _MetricData('Pauses',          pauseFill,  kRed,     pauseLabel,  pauseAlert),
      _MetricData('Filler words',    fillerFill, kRed,     fillerLabel, fillerAlert),
      _MetricData('Pacing',          paceFill,   kPrimary, paceLabel,   paceAlert),
      // Articulation genuinely not computed yet — honest placeholder
      _MetricData('Articulation',    0.80,       kPrimary, '—',         false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _buildMetrics();
    final now = DateTime.now();
    final dateStr =
        '${now.day} ${_month(now.month)} ${now.year}';

    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSectionLabel(),
            Container(
              color: kBg,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                children: [
                  if (!_hasReal)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'No real audio data — values shown are placeholders. '
                        'Complete a session with mic access for live results.',
                        style: TextStyle(
                            fontSize: 11, color: kOrange, height: 1.4),
                      ),
                    ),
                  ...metrics.map((m) => _buildMetricRow(
                        label: m.label,
                        fill: m.fill,
                        barColor: m.color,
                        value: m.value,
                        alert: m.alert,
                      )),
                  if (_hasReal)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Articulation requires phoneme-level analysis — not yet computed.',
                        style: TextStyle(fontSize: 9, color: kGrey),
                      ),
                    ),
                ],
              ),
            ),
            _buildFooter(dateStr),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: kHeader,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_left_rounded,
                  color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Voice Analysis',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              Text(
                _hasReal ? 'Live pipeline result' : 'Placeholder data',
                style: TextStyle(
                    fontSize: 10,
                    color: _hasReal
                        ? const Color(0xFF90EE90)
                        : const Color(0xFFB9A8E8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel() {
    return Container(
      color: kSectionBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFC8348A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('VOICE\nANALYS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 6,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.4)),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Voice analysis',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kHeader)),
                  Text('Acoustic feature breakdown',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF9B8EC4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: kDivider),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required double fill,
    required Color barColor,
    required String value,
    required bool alert,
  }) {
    final isLowGood = value.contains('Low ✓') || value == '—';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF333333))),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fill,
                minHeight: 10,
                backgroundColor: kBarBg,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isLowGood ? kGrey : const Color(0xFF333333),
                )),
          ),
          SizedBox(
            width: 16,
            child: alert
                ? const Text('!',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 13, color: kRed))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(String dateStr) {
    return Container(
      width: double.infinity,
      color: kHeader,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const Text('SPEAKORA',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            _hasReal
                ? 'Generated: $dateStr · Live result'
                : 'Generated: $dateStr · Placeholder',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFFB9A8E8)),
          ),
        ],
      ),
    );
  }

  static String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ── Internal data class ────────────────────────────────────────────────────────
class _MetricData {
  final String label;
  final double fill;
  final Color color;
  final String value;
  final bool alert;
  const _MetricData(this.label, this.fill, this.color, this.value, this.alert);
}
