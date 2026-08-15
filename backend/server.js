const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const fs = require('fs');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Ensure the temp upload folder exists (used by multer in routes/analyze.js)
const tmpDir = 'uploads/tmp/';
if (!fs.existsSync(tmpDir)) {
  fs.mkdirSync(tmpDir, { recursive: true });
}

// MongoDB connect
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/fyp_app';

mongoose.connect(MONGO_URI)
  .then(() => console.log('MongoDB connected:', MONGO_URI))
  .catch((err) => {
    console.error('MongoDB connection failed:', err.message);
    process.exit(1);
  });

// Routes
app.use('/api/auth',     require('./routes/auth'));
app.use('/api/support',  require('./routes/support'));
app.use('/api/analyze',  require('./routes/analyze'));
app.use('/api/sessions', require('./routes/sessions'));

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok' }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
