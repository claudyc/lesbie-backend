require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();

app.use(cors());
app.use(express.json());
app.use('/public', express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
  res.json({
    success: true,
    message: '🌸 Lesbie Chat Backend ap mache!',
  });
});

app.get('/health', (req, res) => {
  res.json({
    success: true,
    ok: true,
  });
});

app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.path} pa egziste.`,
  });
});

if (process.env.NODE_ENV !== 'production') {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🌸 Lesbie Chat Backend running on port ${PORT}`);
  });
}

module.exports = app;
