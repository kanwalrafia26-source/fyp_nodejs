/**
 * Module 5 — AI Therapy & Coaching Engine (Rule-Based)
 *
 * Takes the outputs of Modules 2–4 (transcript/fluency/pronunciation from
 * Whisper, emotion/anxiety from acoustic features) and applies IF/ELSE
 * rule logic to produce:
 *   - feedbackMessages: what happened, in plain language
 *   - therapySuggestions: concrete exercises/techniques to try
 *   - confidenceTip: one encouraging, specific closing note
 *
 * This is intentionally NOT a trained model — per the proposal, Module 5
 * is explicitly rule-based ("NOT a trained model — Uses IF/ELSE logic").
 * Thresholds below are reasonable starting points for a demo; they're
 * easy to tune once you have more real session data to calibrate against.
 */

function buildTherapyPlan({
  fluencyScore,
  longPauseCount,
  fillerWordCount,
  paceStability,
  pronunciationScore,
  emotionLabel,
  anxietyScore,
}) {
  const feedbackMessages = [];
  const therapySuggestions = [];

  // ── Fluency rules ──────────────────────────────────────────────────────
  if (fluencyScore != null) {
    if (fluencyScore < 50) {
      feedbackMessages.push(`Fluency was low this session (${fluencyScore}/100) — pauses and fillers broke up your flow.`);
      therapySuggestions.push('Try the "slow speech" drill: read a paragraph aloud at half your normal speed, focusing on finishing each sentence before starting the next.');
    } else if (fluencyScore < 75) {
      feedbackMessages.push(`Decent fluency (${fluencyScore}/100) — a few rough patches, but mostly steady.`);
    } else {
      feedbackMessages.push(`Strong fluency this session (${fluencyScore}/100).`);
    }
  }

  // ── Pause rules ────────────────────────────────────────────────────────
  if (longPauseCount != null && longPauseCount >= 3) {
    therapySuggestions.push('Practice "pausing on purpose" — when you feel a hesitation coming, take a deliberate silent breath instead of a filler word. Silence reads as confidence, not weakness.');
  }

  // ── Filler word rules ──────────────────────────────────────────────────
  if (fillerWordCount != null) {
    if (fillerWordCount >= 6) {
      feedbackMessages.push(`${fillerWordCount} filler words detected — noticeably high for this length of speech.`);
      therapySuggestions.push('Try recording yourself for 60 seconds on a random topic, then count your fillers. Repeat daily — awareness alone cuts filler use significantly within a week.');
    } else if (fillerWordCount >= 3) {
      therapySuggestions.push('A couple of filler words crept in — next time, replace "um" with a short pause instead.');
    }
  }

  // ── Pacing rules ───────────────────────────────────────────────────────
  if (paceStability === 'Uneven') {
    therapySuggestions.push('Your pace sped up and slowed down noticeably across the recording. Try practicing with a metronome app at a steady 120 BPM to build a consistent internal rhythm.');
  }

  // ── Pronunciation rules ────────────────────────────────────────────────
  if (pronunciationScore != null && pronunciationScore < 70) {
    feedbackMessages.push(`A few words came through unclear (pronunciation confidence: ${pronunciationScore}%).`);
    therapySuggestions.push('Slow down on multi-syllable words and over-enunciate consonants at the ends of words — this is often where clarity drops.');
  }

  // ── Emotion / anxiety rules (Module 4 → Module 5 handoff) ───────────────
  if (emotionLabel === 'Anxious' || (anxietyScore != null && anxietyScore >= 65)) {
    feedbackMessages.push('Your voice showed signs of tension — elevated pitch variability and a strained tone.');
    therapySuggestions.push('Try box breathing before your next session: inhale 4 seconds, hold 4, exhale 4, hold 4. Repeat 4 times. This lowers vocal tension measurably within minutes.');
  } else if (emotionLabel === 'Sad') {
    therapySuggestions.push('Your energy came through a little flat — try smiling while you speak (yes, it changes your tone) to bring more warmth into your voice.');
  } else if (emotionLabel === 'Calm') {
    feedbackMessages.push('Your tone stayed calm and steady throughout — good vocal control.');
  }

  // ── Confidence tip (always exactly one, picks the most relevant) ────────
  let confidenceTip;
  if (fluencyScore != null && fluencyScore >= 75 && (anxietyScore == null || anxietyScore < 35)) {
    confidenceTip = "You're in a strong place here — channel this into slightly slower pacing next time, and you'll sound even more in control.";
  } else if (longPauseCount != null && longPauseCount >= 3) {
    confidenceTip = 'Long pauses feel worse to you than they sound to a listener — trust the silence.';
  } else if (fillerWordCount != null && fillerWordCount >= 3) {
    confidenceTip = 'Cutting fillers is a habit you build in small reps, not a single session — you\'re already on the right track by testing this.';
  } else {
    confidenceTip = 'Keep practicing at this pace — consistency matters more than any single session.';
  }

  // Fallback if literally nothing triggered (a very clean, short recording)
  if (feedbackMessages.length === 0) {
    feedbackMessages.push('Clean session — no major fluency, pacing, or tension issues detected.');
  }
  if (therapySuggestions.length === 0) {
    therapySuggestions.push('Nothing specific to work on here — try a longer or more spontaneous topic next time to stress-test your fluency further.');
  }

  return { feedbackMessages, therapySuggestions, confidenceTip };
}

module.exports = { buildTherapyPlan };
