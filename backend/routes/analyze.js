const express     = require('express');
const router      = express.Router();
const multer      = require('multer');
const fs          = require('fs');
const { spawn }   = require('child_process');
const path        = require('path');

// ── Multer setup: store uploaded audio temporarily on disk ───────────────────
const upload = multer({
  dest: 'uploads/tmp/',
  limits: { fileSize: 25 * 1024 * 1024 }, // 25MB cap, plenty for a speech clip
});

const PYTHON_SCRIPT = path.join(__dirname, '..', 'python', 'transcribe.py');
const PYTHON_BIN = process.env.PYTHON_BIN || 'python';

/**
 * Runs the local Whisper Python script on a given audio file and resolves
 * with the parsed result object (transcript + fluency signals).
 */
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
//   wordCount, wpm,                              — Module 2
//   longPauseCount, totalPauseSeconds,
//   fillerWordCount, paceStability, fluencyScore  — Module 3
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

    res.json({
      transcript: (result.text || '').trim(),
      durationSeconds: result.duration || 0,
      wordCount: result.wordCount || 0,
      wpm: result.wpm || 0,
      longPauseCount: result.longPauseCount || 0,
      totalPauseSeconds: result.totalPauseSeconds || 0,
      fillerWordCount: result.fillerWordCount || 0,
      paceStability: result.paceStability || 'Stable',
      fluencyScore: result.fluencyScore ?? null,
    });
  } catch (err) {
    console.error('[analyze/transcribe]', err.message);
    res.status(500).json({
      message: 'Transcription failed. Is Python + faster-whisper installed correctly?',
    });
  } finally {
    if (tmpFilePath) {
      fs.unlink(tmpFilePath, () => {});
    }
  }
});

module.exports = router;
