const express     = require('express');
const router      = express.Router();
const multer      = require('multer');
const fs          = require('fs');
const { spawn }   = require('child_process');
const path        = require('path');
const { buildTherapyPlan } = require('../therapyEngine');

const upload = multer({
  dest: 'uploads/tmp/',
  limits: { fileSize: 25 * 1024 * 1024 },
});

const PYTHON_SCRIPT = path.join(__dirname, '..', 'python', 'transcribe.py');
const PYTHON_BIN = process.env.PYTHON_BIN || 'python';

function runWhisper(audioPath) {
  return new Promise((resolve, reject) => {
    const proc = spawn(PYTHON_BIN, [PYTHON_SCRIPT, audioPath]);

    let stdout = '';
    let stderr = '';

    proc.stdout.on('data', (chunk) => { stdout += chunk.toString(); });
    proc.stderr.on('data', (chunk) => { stderr += chunk.toString(); });

    proc.on('close', (code) => {
      if (code !== 0) {
        return reject(new Error(stderr || `Python process exited with code ${code}`));
      }
      try {
        const result = JSON.parse(stdout.trim().split('\n').pop());
        if (result.error) return reject(new Error(result.error));
        resolve(result);
      } catch (err) {
        reject(new Error(`Failed to parse Whisper output: ${stdout}`));
      }
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/analyze/transcribe
// Form-data: { audio: <file> }
//
// Returns:
// {
//   transcript, durationSeconds,
//   wordCount, wpm,                                        — Module 2
//   longPauseCount, totalPauseSeconds,
//   fillerWordCount, paceStability, fluencyScore,           — Module 3
//   emotionLabel, anxietyScore,
//   pitchMeanHz, pitchVariability, energyDb,
//   jitterPercent, shimmerPercent                           — Module 4
//   (Module 4 note: rule-based on acoustic features, not a trained SER
//   model — see python/transcribe.py docstring for details.)
// }
// ─────────────────────────────────────────────────────────────────────────────
router.post('/transcribe', upload.single('audio'), async (req, res) => {
  let tmpFilePath;
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No audio file received.' });
    }

    tmpFilePath = req.file.path;

    const result = await runWhisper(tmpFilePath);

    const therapyPlan = buildTherapyPlan({
      fluencyScore: result.fluencyScore ?? null,
      longPauseCount: result.longPauseCount ?? null,
      fillerWordCount: result.fillerWordCount ?? null,
      paceStability: result.paceStability ?? null,
      pronunciationScore: result.pronunciationScore ?? null,
      emotionLabel: result.emotionLabel ?? null,
      anxietyScore: result.anxietyScore ?? null,
    });

    res.json({
      transcript: (result.text || '').trim(),
      durationSeconds: result.duration || 0,
      wordCount: result.wordCount || 0,
      wpm: result.wpm || 0,
      longPauseCount: result.longPauseCount || 0,
      totalPauseSeconds: result.totalPauseSeconds || 0,
      fillerWordCount: result.fillerWordCount || 0,
      fillerBreakdown: result.fillerBreakdown || {},
      paceStability: result.paceStability || 'Stable',
      fluencyScore: result.fluencyScore ?? null,
      pronunciationScore: result.pronunciationScore ?? null,
      lowConfidenceWords: result.lowConfidenceWords || [],
      emotionLabel: result.emotionLabel ?? null,
      anxietyScore: result.anxietyScore ?? null,
      pitchMeanHz: result.pitchMeanHz ?? null,
      pitchVariability: result.pitchVariability ?? null,
      energyDb: result.energyDb ?? null,
      jitterPercent: result.jitterPercent ?? null,
      shimmerPercent: result.shimmerPercent ?? null,
      // Module 5 — rule-based therapy engine output
      feedbackMessages: therapyPlan.feedbackMessages,
      therapySuggestions: therapyPlan.therapySuggestions,
      confidenceTip: therapyPlan.confidenceTip,
    });
  } catch (err) {
    console.error('[analyze/transcribe]', err.message);
    res.status(500).json({
      message: 'Transcription failed. Is Python + faster-whisper/parselmouth installed correctly?',
    });
  } finally {
    if (tmpFilePath) {
      fs.unlink(tmpFilePath, () => {});
    }
  }
});

module.exports = router;
