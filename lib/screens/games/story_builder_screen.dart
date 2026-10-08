import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'story_builder_fail_screen.dart';
import '../../services/api_service.dart';
import 'story_builder_result_screen.dart';

class StoryBuilderScreen extends StatefulWidget {
  const StoryBuilderScreen({super.key});

  @override
  State<StoryBuilderScreen> createState() => _StoryBuilderScreenState();
}

class _StoryBuilderScreenState extends State<StoryBuilderScreen>
    with TickerProviderStateMixin {
  // ── Turn state ─────────────────────────────────────────────────────────────
  int _turn        = 1;          // starts at 1, not 3
  static const int _total = 10;
  int _timerSecs   = 15;
  bool _recording  = false;
  bool _isAnalyzing = false;
  Timer? _countdown;

  // Real session start time for duration tracking
  final DateTime _sessionStart = DateTime.now();

  // ── Per-turn results — appended, never overwritten ─────────────────────────
  final List<Map<String, dynamic>> _turnResults = [];

  // Chat messages built from real transcripts: (isAI, text)
  final List<(bool, String)> _chatMessages = [];

  // Story history — preserves BOTH AI and user contributions in order.
  final List<Map<String, String>> _storyHistory = [];

  bool _loadingOpening = true;

  // ── Real audio ─────────────────────────────────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();
  bool _hasPermission = false;

  late AnimationController _waveCtrl;
  late AnimationController _pulseCtrl;

  // ── Colours ────────────────────────────────────────────────────────────────
  static const Color kBg        = Color(0xFF150028);
  static const Color kHeaderBg  = Color(0xFF1E0040);
  static const Color kPrimary   = Color(0xFF5300AC);
  static const Color kYellow    = Color(0xFFD9E366);
  static const Color kYellowDk  = Color(0xFF290451);
  static const Color kSubtitle  = Color(0xFF7A50A0);
  static const Color kPromptBg  = Color(0x1AD9E366);
  static const Color kGreen     = Color(0xFF90D070);

  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _checkPermission();
    _initNewGame();
  }

  Future<void> _initNewGame() async {
    if (mounted) {
      setState(() {
        _turn = 1;
        _turnResults.clear();
        _storyHistory.clear();
        _chatMessages.clear();
        _loadingOpening = true;
      });
    }

    final opening = await ApiService.getStoryOpening();
    final text = (opening != null && opening.isNotEmpty)
        ? opening
        : 'The old train stopped suddenly in the middle of the forest.';

    if (mounted) {
      setState(() {
        _chatMessages.add((true, '"$text"'));
        _storyHistory.add({'speaker': 'AI', 'text': text});
        _loadingOpening = false;
      });
    }
  }

  Future<void> _checkPermission() async {
    try {
      final ok = await _recorder.hasPermission();
      if (mounted) setState(() => _hasPermission = ok);
    } catch (_) {}
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _pulseCtrl.dispose();
    _countdown?.cancel();
    _textController.dispose();
    if (_recording) _recorder.stop();
    _recorder.dispose();
    super.dispose();
  }

  // ── Recording & Analysis lifecycle ─────────────────────────────────────────
  Future<void> _toggleRecording() async {
    if (_isAnalyzing) return;

    if (!_recording) {
      final started = await _startRecordingForTurn();
      if (!started) return;

      setState(() => _recording = true);
      _waveCtrl.repeat(reverse: true);
      _timerSecs = 15;
      _countdown?.cancel();
      _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_timerSecs > 0) {
          if (mounted) setState(() => _timerSecs--);
        } else {
          t.cancel();
          _stopRecording();
        }
      });
    } else {
      await _stopRecording();
    }
  }

  Future<bool> _startRecordingForTurn() async {
    if (!_hasPermission) {
      await _checkPermission();
      if (!_hasPermission) return false;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/sb_t${_turn}_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: path);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _stopRecording() async {
    _countdown?.cancel();
    _waveCtrl.stop();
    if (mounted) {
      setState(() {
        _recording = false;
        _timerSecs = 15;
      });
    }
    await _analyseCurrentTurn();
  }

  Future<void> _analyseCurrentTurn({String? manualText}) async {
    if (mounted) setState(() => _isAnalyzing = true);

    Map<String, dynamic>? result;
    String transcript = manualText?.trim() ?? '';

    if (transcript.isEmpty) {
      try {
        final path = await _recorder.stop();
        if (path != null) {
          result = await ApiService.transcribeAudio(path);
          transcript = result['text'] as String? ??
              result['transcript'] as String? ?? '';
          transcript = transcript.trim();
        }
      } catch (_) {}
    }

    // If transcript is still empty (e.g. mic didn't catch speech), prompt user to try again
    if (transcript.isEmpty) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No speech detected. Please tap the mic or type to try again.'),
            backgroundColor: Color(0xFF5300AC),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // ── Save turn result ──────────────────────────────────────────────────────
    _turnResults.add({
      'turn':            _turn,
      'transcript':      transcript,
      'fluencyScore':    (result?['fluencyScore']    as num?)?.toInt() ?? 80,
      'fillerWordCount': (result?['fillerWordCount']  as num?)?.toInt() ?? 0,
      'paceStability':   result?['paceStability']    as String? ?? 'Stable',
      'wpm':             (result?['wpm']             as num?)?.toInt() ?? 120,
      'hasRealData':     result != null || manualText != null,
    });

    // ── Add user contribution to chat and story history ───────────────────────
    _chatMessages.add((false, '"$transcript"'));
    _storyHistory.add({'speaker': 'You', 'text': transcript});

    // ── Generate dynamic AI continuation ─────────────────────────────────────
    final storySoFar = _storyHistory
        .map((e) => '${e['speaker']}: ${e['text']}')
        .join('\n');

    final continuation = await ApiService.getStoryContinuation(
      storySoFar:     storySoFar,
      latestUserTurn: transcript,
      turnNumber:     _turn,
    );

    if (continuation != null && continuation.isNotEmpty) {
      // Real Gemini response
      _chatMessages.add((true, '"$continuation"'));
      _storyHistory.add({'speaker': 'AI', 'text': continuation});
    } else {
      // Graceful fallback if Gemini endpoint unavailable
      debugPrint('[StoryBuilder] Showing AI unavailable fallback for turn $_turn');
      _chatMessages.add(
        (true, '(AI continuation unavailable — continue the story your way...)'),
      );
    }

    if (mounted) {
      setState(() {
        if (_turn < _total) {
          _turn++;
        }
        _isAnalyzing = false;
      });
      if (_turnResults.length >= _total) {
        _finish();
      }
    }
  }

  void _submitTextTurn() {
    final text = _textController.text.trim();
    if (text.isEmpty || _isAnalyzing) return;
    _textController.clear();
    FocusScope.of(context).unfocus();
    _analyseCurrentTurn(manualText: text);
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _finish() {
    final elapsed = DateTime.now().difference(_sessionStart).inSeconds;

    final validScores = _turnResults
        .where((t) => t['hasRealData'] == true)
        .map((t) => t['fluencyScore'] as int)
        .toList();
    final avgFluency = validScores.isNotEmpty
        ? (validScores.reduce((a, b) => a + b) ~/ validScores.length)
        : 80;

    // Save session to backend
    ApiService.saveSession({
      'sessionType': 'story_builder',
      'durationSeconds': elapsed,
      'fluencyScore': avgFluency,
      'turnResults': _turnResults,
    });

    if (avgFluency >= 60 || _turnResults.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StoryBuilderResultScreen(
            turnResults:      _turnResults,
            durationSeconds:  elapsed,
            storyHistory:     List<Map<String, String>>.unmodifiable(_storyHistory),
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StoryBuilderFailScreen(
            turnResults:     _turnResults,
            turnsCompleted:  _turnResults.length,
            durationSeconds: elapsed,
            storyHistory:    List<Map<String, String>>.unmodifiable(_storyHistory),
          ),
        ),
      );
    }
  }

  void _giveUp() {
    final elapsed = DateTime.now().difference(_sessionStart).inSeconds;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StoryBuilderFailScreen(
          turnResults:     _turnResults,
          turnsCompleted:  _turn,
          durationSeconds: elapsed,
          storyHistory:    List<Map<String, String>>.unmodifiable(_storyHistory),
        ),
      ),
    );
  }

  // ── Latest completed turn result ────────────────────────────────────────────
  Map<String, dynamic>? get _lastResult =>
      _turnResults.isNotEmpty ? _turnResults.last : null;

  @override
  Widget build(BuildContext context) {
    final progress = _turn / _total;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(progress),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      children: [
                        // ── Chat bubbles from real transcripts ──────────
                        ..._chatMessages.map((m) => _ChatBubble(
                              isAI: m.$1,
                              text: m.$2,
                            )),

                        const SizedBox(height: 12),

                        // ── Your turn prompt ────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: kPromptBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: kYellow.withOpacity(0.25),
                                width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                    color: kYellow,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Your turn — continue the story...',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: kYellow,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Mic button ──────────────────────────────────
                        GestureDetector(
                          onTap: _toggleRecording,
                          child: AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (context, child) {
                              final scale = _recording
                                  ? 1.0 + 0.06 * sin(_pulseCtrl.value * pi)
                                  : 1.0;
                              return Transform.scale(
                                scale: scale,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 80, height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: kPrimary.withOpacity(0.15),
                                        border: Border.all(
                                          color: kYellow.withOpacity(0.15),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 62, height: 62,
                                      decoration: BoxDecoration(
                                        color: _recording
                                            ? Colors.redAccent
                                            : kPrimary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _recording
                                            ? Icons.stop_rounded
                                            : Icons.mic_rounded,
                                        color: const Color(0xFFE6BEF0),
                                        size: 28,
                                      ),
                                    ),
                                    if (_recording)
                                      Positioned(
                                        top: 8, right: 8,
                                        child: Container(
                                          width: 12, height: 12,
                                          decoration: const BoxDecoration(
                                              color: Color(0xFFD05050),
                                              shape: BoxShape.circle),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Optional text input for typing turns ───────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _textController,
                                  enabled: !_recording && !_isAnalyzing,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Or type your turn here...',
                                    hintStyle: TextStyle(
                                      color: kSubtitle.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.06),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: kYellow.withOpacity(0.2)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: kYellow.withOpacity(0.2)),
                                    ),
                                  ),
                                  onSubmitted: (_) => _submitTextTurn(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: (_recording || _isAnalyzing)
                                    ? null
                                    : _submitTextTurn,
                                icon: const Icon(Icons.send_rounded, color: kYellow),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Last turn stats ─────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFE6BEF0)
                                    .withOpacity(0.08),
                                width: 1),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _lastResult != null
                                    ? 'TURN ${_lastResult!['turn']} RESULT'
                                    : 'LAST SENTENCE',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: kSubtitle,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _StatBox(
                                    value: _lastResult != null &&
                                            _lastResult!['hasRealData'] == true
                                        ? '${_lastResult!['fluencyScore']}%'
                                        : '—',
                                    label: 'Fluency',
                                    valueColor: const Color(0xFFE6BEF0),
                                    bgColor: kPrimary.withOpacity(0.25),
                                  ),
                                  const SizedBox(width: 10),
                                  _StatBox(
                                    value: _lastResult != null &&
                                            _lastResult!['hasRealData'] == true
                                        ? (_lastResult!['paceStability'] ?? '—')
                                        : '—',
                                    label: 'Pacing',
                                    valueColor: kGreen,
                                    bgColor: const Color(0xFF5A9040)
                                        .withOpacity(0.2),
                                  ),
                                  const SizedBox(width: 10),
                                  _StatBox(
                                    value: _lastResult != null &&
                                            _lastResult!['hasRealData'] == true
                                        ? '${_lastResult!['fillerWordCount']}'
                                        : '—',
                                    label: 'Fillers',
                                    valueColor: kGreen,
                                    bgColor: const Color(0xFF5A9040)
                                        .withOpacity(0.2),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Give up / Next turn buttons ─────────────────
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: _giveUp,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        const Color(0xFF9A70B0),
                                    side: const BorderSide(
                                        color: Color(0xFF3A1260),
                                        width: 1.5),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  child: const Text('Give up',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                             Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed:
                                      (_recording || _isAnalyzing || _loadingOpening || _turnResults.isEmpty)
                                          ? null
                                          : _finish,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kYellow,
                                    foregroundColor: kYellowDk,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  child: Text(
                                    _turnResults.length >= _total
                                        ? 'Finish & View Report  ✓'
                                        : 'Finish Story  ✓',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Loading opening overlay ──────────────────────────────────
            if (_loadingOpening)
              Container(
                color: kBg,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: kYellow),
                      SizedBox(height: 16),
                      Text('Generating new story opening...',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),

            // ── Analysing overlay ─────────────────────────────────────
            if (_isAnalyzing)
              Container(
                color: Colors.black.withOpacity(0.55),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: kYellow),
                      SizedBox(height: 14),
                      Text('Analysing turn...',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double progress) {
    return Container(
      color: kHeaderBg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Game 3 · Story Builder',
                        style:
                            TextStyle(fontSize: 12, color: kSubtitle)),
                    SizedBox(height: 2),
                    Text('Your turn',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3,
                        )),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: kYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: kYellow.withOpacity(0.25), width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      _recording
                          ? _timerSecs.toString().padLeft(2, '0')
                          : '15',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: kYellow,
                        height: 1.0,
                      ),
                    ),
                    const Text('sec',
                        style: TextStyle(
                            fontSize: 10, color: kSubtitle)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Turn $_turn',
                  style: const TextStyle(
                      fontSize: 10, color: kSubtitle)),
              Text('of $_total',
                  style: const TextStyle(
                      fontSize: 10, color: kSubtitle)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(kYellow),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

}

// ── Chat bubble ────────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final bool isAI;
  final String text;

  static const Color kAIBubble  = Color(0xFF1E0040);
  static const Color kYouBubble = Color(0xFF5300AC);
  static const Color kSubtitle  = Color(0xFF9A70B0);
  static const Color kYellow    = Color(0xFFD9E366);

  const _ChatBubble({required this.isAI, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAI) ...[
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(
                  color: Color(0xFF5300AC), shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Color(0xFFE6BEF0), size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isAI
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Text(isAI ? 'AI' : 'You',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isAI ? kSubtitle : kYellow,
                    )),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isAI ? kAIBubble : kYouBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isAI ? 4 : 14),
                      topRight: Radius.circular(isAI ? 14 : 4),
                      bottomLeft: const Radius.circular(14),
                      bottomRight: const Radius.circular(14),
                    ),
                    border: Border.all(
                        color:
                            const Color(0xFFE6BEF0).withOpacity(0.1),
                        width: 1),
                  ),
                  child: Text(text,
                      style: TextStyle(
                        fontSize: 12,
                        color: isAI
                            ? const Color(0xFFE6BEF0)
                            : Colors.white,
                        height: 1.5,
                      )),
                ),
              ],
            ),
          ),
          if (!isAI) ...[
            const SizedBox(width: 8),
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFE6BEF0).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  color: Color(0xFFE6BEF0), size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stat box ───────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final Color bgColor;

  static const Color kSubtitle = Color(0xFF7A50A0);

  const _StatBox({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: valueColor)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: kSubtitle)),
          ],
        ),
      ),
    );
  }
}
