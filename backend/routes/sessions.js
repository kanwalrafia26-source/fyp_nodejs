const express = require('express');
const router  = express.Router();
const Session = require('../models/Session');
const { requireAuth } = require('../middleware/authMiddleware');

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/sessions
// Header: Authorization: Bearer <token>
// Body: any subset of the Session schema fields (from a completed analysis)
// ─────────────────────────────────────────────────────────────────────────────
router.post('/', requireAuth, async (req, res) => {
  try {
    const session = new Session({
      userId: req.user.id,
      ...req.body,
    });
    await session.save();
    res.status(201).json({ message: 'Session saved.', session });
  } catch (err) {
    console.error('[sessions/save]', err.message);
    res.status(500).json({ message: 'Failed to save session.' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/sessions
// Header: Authorization: Bearer <token>
// Returns the current user's sessions, most recent first.
// ─────────────────────────────────────────────────────────────────────────────
router.get('/', requireAuth, async (req, res) => {
  try {
    const sessions = await Session.find({ userId: req.user.id })
      .sort({ createdAt: -1 })
      .limit(50);
    res.json({ sessions });
  } catch (err) {
    console.error('[sessions/list]', err.message);
    res.status(500).json({ message: 'Failed to fetch sessions.' });
  }
});

module.exports = router;
