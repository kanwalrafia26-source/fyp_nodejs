const express     = require('express');
const router      = express.Router();
const multer      = require('multer');
const fs          = require('fs');
const { spawn }   = require('child_process');
const path        = require('path');
const https       = require('https');
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

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/analyze/story-continuation
// Body: { storySoFar: string, latestUserTurn: string, turnNumber: number }
// Returns: { continuation: string }
//
// Calls Gemini 2.0 Flash (server-side) to generate a 1–2 sentence story
// continuation that directly acknowledges the user's latest contribution.
// API key is server-side only — never exposed to Flutter.
// ─────────────────────────────────────────────────────────────────────────────
function queryGeminiModel(modelName, apiKey, prompt) {
  return new Promise((resolve, reject) => {
    const requestBody = JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        maxOutputTokens: 2048,
        temperature: 0.85,
        topP: 0.9,
      },
    });

    const options = {
      hostname: 'generativelanguage.googleapis.com',
      path: `/v1beta/models/${modelName}:generateContent?key=${apiKey}`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(requestBody),
      },
    };

    const request = https.request(options, (response) => {
      let data = '';
      response.on('data', (chunk) => { data += chunk; });
      response.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (parsed.error) {
            const msg = parsed.error.message || 'unknown Gemini error';
            console.error(`[queryGeminiModel] ${modelName} HTTP ${response.statusCode} – ${msg}`);
            return reject(new Error(`Gemini ${response.statusCode} (${modelName}): ${msg}`));
          }
          const parts = parsed?.candidates?.[0]?.content?.parts || [];
          const text = parts.filter(p => !p.thought).map(p => p.text || '').join(' ').trim();
          if (text) {
            resolve(text);
          } else {
            console.error(`[queryGeminiModel] ${modelName} returned no text (HTTP ${response.statusCode}):`, data.substring(0, 200));
            reject(new Error(`Gemini returned no text: ${data}`));
          }
        } catch (e) {
          console.error(`[queryGeminiModel] Failed to parse response from ${modelName} (HTTP ${response.statusCode}):`, data.substring(0, 200));
          reject(new Error(`Failed to parse Gemini response: ${data}`));
        }
      });
    });
    request.on('error', reject);
    request.write(requestBody);
    request.end();
  });
}

async function queryGeminiWithFallbacks(apiKey, prompt) {
  const models = [
    'gemini-3.5-flash',
    'gemini-flash-lite-latest',
    'gemini-3.8-flash',
    'gemini-flash-latest'
  ];
  let lastError;
  for (const model of models) {
    try {
      const res = await queryGeminiModel(model, apiKey, prompt);
      return res;
    } catch (err) {
      lastError = err;
      console.warn(`[queryGeminiWithFallbacks] Model ${model} failed: ${err.message}`);
    }
  }
  throw lastError || new Error('All Gemini model fallbacks failed');
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/analyze/story-opening
// Returns: { opening: string }
//
// Generates a fresh, unique 1–2 sentence story opening for a new game session.
// ─────────────────────────────────────────────────────────────────────────────
router.post('/story-opening', async (req, res) => {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey.startsWith('AIzaSyExample')) {
    return res.status(503).json({ message: 'Gemini API key not configured.' });
  }

  const prompt =
    `Generate a fresh, unique, and creative 1–2 sentence story opening for an interactive speaking game.\n` +
    `Requirements:\n` +
    `- Must be engaging, imaginative, and easy for a student to continue.\n` +
    `- Must NOT be a question to the user.\n` +
    `- Must NOT include quotation marks around the output.\n` +
    `- Must NOT reuse common cliches like "It was a dark and stormy night".\n` +
    `- Output ONLY the 1–2 sentence story opening.`;

  try {
    const opening = await queryGeminiWithFallbacks(apiKey, prompt);
    res.json({ opening });
  } catch (err) {
    console.error('[analyze/story-opening] All models failed:', err.message);
    res.status(500).json({ message: 'Failed to generate story opening.', error: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/analyze/story-continuation
// Body: { storySoFar: string, latestUserTurn: string, turnNumber: number }
// Returns: { continuation: string }
// ─────────────────────────────────────────────────────────────────────────────
router.post('/story-continuation', async (req, res) => {
  const { storySoFar, latestUserTurn, turnNumber } = req.body;

  if (!storySoFar || !latestUserTurn) {
    return res.status(400).json({ message: 'storySoFar and latestUserTurn are required.' });
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey.startsWith('AIzaSyExample')) {
    return res.status(503).json({ message: 'Gemini API key not configured.' });
  }

  const prompt =
    `You are a creative writing collaborator helping build a short spoken story.\n` +
    `The story so far:\n${storySoFar}\n\n` +
    `The user just said on turn ${turnNumber}:\n"${latestUserTurn}"\n\n` +
    `Continue the story in 1–2 sentences. ` +
    `Directly acknowledge or build on what the user just said. ` +
    `Preserve all characters, setting, and events established so far. ` +
    `Do not restart the story. Do not give feedback to the user. ` +
    `Do not mention that you are an AI. ` +
    `Do not use quotation marks around your response. ` +
    `Output ONLY the story continuation.`;

  try {
    const continuation = await queryGeminiWithFallbacks(apiKey, prompt);
    res.json({ continuation });
  } catch (err) {
    console.error('[analyze/story-continuation] All models failed:', err.message);
    res.status(500).json({ message: 'Story continuation failed.', error: err.message });
  }
});

module.exports = router;
