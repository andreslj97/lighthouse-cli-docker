import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const app = express();
const PORT = process.env.PORT || 3000;

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Servir frontend ya compilado
app.use(express.static(path.join(__dirname, '../build')));

// API route
app.get('/api/run', async (req, res) => {
  try {
    const { runLighthouse } = await import('./run-process-lighthouse.js');
    const result = await runLighthouse();
    res.json({ urls: result.url });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Catch-all: frontend SPA
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../build/index.html')); 
});

app.listen(PORT, () => console.log(`🚀 Server running on http://localhost:${PORT}`));
