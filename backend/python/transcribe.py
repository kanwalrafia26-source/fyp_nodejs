"""
Local Whisper transcription + fluency analysis — Modules 2 & 3.

Module 2 (Speech-to-Text): transcript via faster-whisper.
Module 3 (Fluency Analysis): speaking rate, long-pause detection, silence
duration, filler-word (hesitation) detection, and a simple rule-based
fluency score built from those signals.

Called by the Node backend as a subprocess:
    python transcribe.py <path_to_audio_file>

Prints a single JSON line to stdout.
"""
import sys
import json
import re
from faster_whisper import WhisperModel

# Gap between words, in seconds, before it counts as a "pause" at all.
PAUSE_THRESHOLD = 0.5
# Gap before it counts as a "long" pause (the kind that breaks fluency).
LONG_PAUSE_THRESHOLD = 1.0

# Common hesitation / filler words & phrases (case-insensitive whole-word match).
FILLER_PATTERNS = [
    r"\bum+\b", r"\buh+\b", r"\ber+\b", r"\bhmm+\b",
    r"\blike\b", r"\byou know\b", r"\bi mean\b",
    r"\bsort of\b", r"\bkind of\b", r"\bbasically\b", r"\bactually\b",
]
FILLER_REGEX = re.compile("|".join(FILLER_PATTERNS), re.IGNORECASE)


def compute_fluency(words, full_text, duration):
    """Returns a dict of fluency signals derived from word timestamps."""
    pauses = []
    for i in range(len(words) - 1):
        gap = words[i + 1]["start"] - words[i]["end"]
        if gap >= PAUSE_THRESHOLD:
            pauses.append(gap)

    long_pause_count = sum(1 for g in pauses if g >= LONG_PAUSE_THRESHOLD)
    total_pause_seconds = round(sum(pauses), 2)

    filler_matches = FILLER_REGEX.findall(full_text)
    filler_count = len(filler_matches)

    word_count = len(words)
    wpm = round((word_count / duration) * 60) if duration > 0 else 0

    # ── Pace stability: split into 3 equal time windows, compare their WPM ──
    pace_stability = "Stable"
    if duration > 6 and word_count >= 6:
        window_len = duration / 3
        window_counts = [0, 0, 0]
        for w in words:
            idx = min(int(w["start"] // window_len), 2)
            window_counts[idx] += 1
        window_wpms = [round((c / window_len) * 60) for c in window_counts]
        spread = max(window_wpms) - min(window_wpms)
        # Large spread between the fastest and slowest third = uneven pacing.
        pace_stability = "Uneven" if spread > 40 else "Stable"

    # ── Simple rule-based fluency score (Module 3 output, not the Module 5
    #    therapy logic itself — this just quantifies what happened) ──
    score = 100
    score -= min(long_pause_count * 8, 40)      # long pauses hurt most
    score -= min(filler_count * 4, 24)          # fillers, capped
    if pace_stability == "Uneven":
        score -= 10
    score = max(0, min(100, score))

    return {
        "wordCount": word_count,
        "wpm": wpm,
        "longPauseCount": long_pause_count,
        "totalPauseSeconds": total_pause_seconds,
        "fillerWordCount": filler_count,
        "paceStability": pace_stability,
        "fluencyScore": score,
    }


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

    segments = list(segments)  # materialize the generator once
    full_text = " ".join(s.text.strip() for s in segments).strip()

    words = []
    for seg in segments:
        if seg.words:
            for w in seg.words:
                words.append({"start": w.start, "end": w.end, "word": w.word})

    fluency = compute_fluency(words, full_text, info.duration)

    result = {
        "text": full_text,
        "duration": info.duration,
        **fluency,
    }
    print(json.dumps(result))


if __name__ == "__main__":
    main()
