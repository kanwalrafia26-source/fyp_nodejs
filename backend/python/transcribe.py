"""
Local Whisper transcription + fluency analysis + acoustic emotion detection.

Module 2 (Speech-to-Text): transcript via faster-whisper.
Module 3 (Fluency Analysis): speaking rate, long-pause detection, silence
duration, filler-word detection, rule-based fluency score.
Module 4 (Emotion & Anxiety Detection): pitch, energy, jitter, shimmer via
Praat (parselmouth), combined into a RULE-BASED emotion label + anxiety
score.

IMPORTANT — honesty note for the FYP write-up: this is NOT a trained
pretrained SER (Speech Emotion Recognition) neural network. It's a
rule-based system over classical acoustic voice-quality features. This was
a deliberate scope decision to avoid the ~2GB torch/transformers download a
real pretrained SER model would need. A trained SER classifier remains a
documented, drop-in future extension — it would just replace the
`detect_emotion()` function below without changing anything else in the
pipeline (Node route, Flutter screens) since the output shape stays the
same.

Called by the Node backend as a subprocess:
    python transcribe.py <path_to_audio_file>

Prints a single JSON line to stdout.
"""
import sys
import json
import re
import parselmouth
from parselmouth.praat import call
from faster_whisper import WhisperModel

# ── Module 3 constants ────────────────────────────────────────────────────
PAUSE_THRESHOLD = 0.5
LONG_PAUSE_THRESHOLD = 1.0

FILLER_PATTERNS = [
    r"\bum+\b", r"\buh+\b", r"\ber+\b", r"\bhmm+\b",
    r"\blike\b", r"\byou know\b", r"\bi mean\b",
    r"\bsort of\b", r"\bkind of\b", r"\bbasically\b", r"\bactually\b",
]
FILLER_REGEX = re.compile("|".join(FILLER_PATTERNS), re.IGNORECASE)

# ── Module 4 reference thresholds ─────────────────────────────────────────
# These are rough, commonly-cited reference values from voice-quality
# literature (e.g. typical "healthy"/neutral speech jitter < ~1.04%,
# shimmer < ~3.81%). They are heuristic anchors for a rule-based system,
# NOT clinically validated per-speaker calibration.
JITTER_REF = 1.04     # percent
SHIMMER_REF = 3.81    # percent
PITCH_CV_REF = 0.15   # coefficient of variation for "typical" pitch variability
WPM_LOW, WPM_HIGH = 100, 160   # comfortable conversational range


def compute_pronunciation(words):
    """
    Approximates a 'pronunciation confidence' score from Whisper's own
    per-word probability — not a phoneme-level pronunciation model, but a
    genuinely free-by-product signal: words Whisper was unsure about are
    often the ones that were mumbled, unclear, or mispronounced.
    """
    if not words:
        return {"pronunciationScore": None, "lowConfidenceWords": []}

    probs = [w.get("probability", 1.0) for w in words]
    avg_prob = sum(probs) / len(probs)
    score = round(max(0, min(100, avg_prob * 100)))

    # Flag the least-confident words (below 0.6 probability), capped to 5
    # so the UI doesn't get flooded on longer recordings.
    low_conf = sorted(
        [w for w in words if w.get("probability", 1.0) < 0.6],
        key=lambda w: w["probability"],
    )[:5]
    low_conf_words = [w["word"].strip() for w in low_conf]

    return {"pronunciationScore": score, "lowConfidenceWords": low_conf_words}


def compute_fluency(words, full_text, duration):
    pauses = []
    for i in range(len(words) - 1):
        gap = words[i + 1]["start"] - words[i]["end"]
        if gap >= PAUSE_THRESHOLD:
            pauses.append(gap)

    long_pause_count = sum(1 for g in pauses if g >= LONG_PAUSE_THRESHOLD)
    total_pause_seconds = round(sum(pauses), 2)

    filler_matches = FILLER_REGEX.findall(full_text)
    filler_count = len(filler_matches)
    filler_breakdown = {}
    for match in filler_matches:
        key = match.strip().lower()
        filler_breakdown[key] = filler_breakdown.get(key, 0) + 1

    word_count = len(words)
    wpm = round((word_count / duration) * 60) if duration > 0 else 0

    pace_stability = "Stable"
    if duration > 6 and word_count >= 6:
        window_len = duration / 3
        window_counts = [0, 0, 0]
        for w in words:
            idx = min(int(w["start"] // window_len), 2)
            window_counts[idx] += 1
        window_wpms = [round((c / window_len) * 60) for c in window_counts]
        spread = max(window_wpms) - min(window_wpms)
        pace_stability = "Uneven" if spread > 40 else "Stable"

    score = 100
    score -= min(long_pause_count * 8, 40)
    score -= min(filler_count * 4, 24)
    if pace_stability == "Uneven":
        score -= 10
    score = max(0, min(100, score))

    return {
        "wordCount": word_count,
        "wpm": wpm,
        "longPauseCount": long_pause_count,
        "totalPauseSeconds": total_pause_seconds,
        "fillerWordCount": filler_count,
        "fillerBreakdown": filler_breakdown,
        "paceStability": pace_stability,
        "fluencyScore": score,
    }


def compute_acoustic_features(audio_path):
    """Extracts pitch, energy, jitter, and shimmer using Praat via parselmouth."""
    sound = parselmouth.Sound(audio_path)

    # Pitch (F0)
    pitch = sound.to_pitch()
    pitch_values = pitch.selected_array["frequency"]
    voiced = pitch_values[pitch_values > 0]
    mean_pitch = float(voiced.mean()) if len(voiced) > 0 else 0.0
    pitch_std = float(voiced.std()) if len(voiced) > 0 else 0.0
    pitch_cv = (pitch_std / mean_pitch) if mean_pitch > 0 else 0.0

    # Energy / intensity
    intensity = sound.to_intensity()
    mean_energy_db = float(call(intensity, "Get mean", 0, 0, "energy"))

    # Jitter & shimmer (need a periodic point process first)
    try:
        point_process = call(sound, "To PointProcess (periodic, cc)", 75, 600)
        jitter_local = call(point_process, "Get jitter (local)", 0, 0, 0.0001, 0.02, 1.3) * 100
        shimmer_local = call(
            [sound, point_process], "Get shimmer (local)", 0, 0, 0.0001, 0.02, 1.3, 1.6
        ) * 100
    except Exception:
        # Can fail on very short/quiet/silent clips — fall back to 0 rather
        # than crashing the whole request.
        jitter_local = 0.0
        shimmer_local = 0.0

    return {
        "pitchMeanHz": round(mean_pitch, 1),
        "pitchVariability": round(pitch_cv, 3),
        "energyDb": round(mean_energy_db, 1),
        "jitterPercent": round(jitter_local, 2),
        "shimmerPercent": round(shimmer_local, 2),
    }


def detect_emotion(acoustic, wpm):
    """
    Rule-based emotion label + anxiety/stress score.
    See module docstring — this is a heuristic system, not a trained model.
    """
    pitch_cv = acoustic["pitchVariability"]
    energy_db = acoustic["energyDb"]
    jitter = acoustic["jitterPercent"]
    shimmer = acoustic["shimmerPercent"]

    # ── Anxiety/stress score (0-100), weighted combination ──
    score = 0.0
    score += min(jitter / JITTER_REF, 3) * 15 if JITTER_REF > 0 else 0
    score += min(shimmer / SHIMMER_REF, 3) * 15 if SHIMMER_REF > 0 else 0
    score += min(pitch_cv / PITCH_CV_REF, 3) * 30

    # Speaking rate extremity (very fast or very slow both add stress signal)
    if wpm > 0:
        if wpm > WPM_HIGH:
            score += min((wpm - WPM_HIGH) / 40, 1) * 20
        elif wpm < WPM_LOW:
            score += min((WPM_LOW - wpm) / 40, 1) * 10

    anxiety_score = round(max(0, min(100, score)))

    # ── Emotion label (simplified decision tree) ──
    if anxiety_score >= 65:
        label = "Anxious"
    elif energy_db < 55 and pitch_cv < 0.10:
        label = "Sad"
    elif energy_db > 68 and acoustic["pitchMeanHz"] > 180:
        label = "Angry"
    elif pitch_cv < 0.12 and anxiety_score < 35:
        label = "Calm"
    else:
        label = "Happy"

    return {"emotionLabel": label, "anxietyScore": anxiety_score}


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No audio file path provided."}))
        sys.exit(1)

    audio_path = sys.argv[1]

    model = WhisperModel("small", device="cpu", compute_type="int8")

    segments, info = model.transcribe(
        audio_path,
        beam_size=5,
        word_timestamps=True,
        vad_filter=True,
        vad_parameters=dict(min_silence_duration_ms=500),
        condition_on_previous_text=False,
    )

    segments = list(segments)
    full_text = " ".join(s.text.strip() for s in segments).strip()

    words = []
    for seg in segments:
        if seg.words:
            for w in seg.words:
                words.append({
                    "start": w.start,
                    "end": w.end,
                    "word": w.word,
                    "probability": w.probability,
                })

    fluency = compute_fluency(words, full_text, info.duration)
    pronunciation = compute_pronunciation(words)

    try:
        acoustic = compute_acoustic_features(audio_path)
        emotion = detect_emotion(acoustic, fluency["wpm"])
    except Exception as e:
        # Emotion detection is additive — if it fails for any reason, the
        # transcription/fluency result should still come back successfully.
        acoustic = {}
        emotion = {"emotionLabel": None, "anxietyScore": None}

    result = {
        "text": full_text,
        "duration": info.duration,
        **fluency,
        **pronunciation,
        **acoustic,
        **emotion,
    }
    print(json.dumps(result))


if __name__ == "__main__":
    main()
