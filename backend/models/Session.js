const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  selectedAI: { type: Number, default: 2 }, // 0=Coach, 1=Therapist, 2=Both
  sessionType: { type: String, default: 'practice' }, // 'practice' | 'simulation'
  scenarioName: { type: String, default: '' },         // simulation only
  roleName: { type: String, default: '' },             // simulation only
  difficulty: { type: String, default: '' },           // simulation only
  durationSeconds: { type: Number, default: 0 },
  transcript: { type: String, default: '' },

  // Module 2/3 — speech-to-text & fluency
  wordCount: Number,
  wpm: Number,
  longPauseCount: Number,
  totalPauseSeconds: Number,
  fillerWordCount: Number,
  paceStability: String,
  fluencyScore: Number,
  pronunciationScore: Number,

  // Module 4 — emotion/anxiety (rule-based)
  emotionLabel: String,
  anxietyScore: Number,

  // Module 5 — therapy engine output
  feedbackMessages: [String],
  therapySuggestions: [String],
  confidenceTip: String,
}, { timestamps: true });

module.exports = mongoose.model('Session', sessionSchema);
