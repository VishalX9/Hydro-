import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import crypto from 'crypto';
import { MongoClient } from 'mongodb';

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));

const MONGODB_URI = process.env.MONGODB_URI;
const DB_NAME = process.env.DB_NAME || 'hydrogauge';
const COLLECTION = process.env.COLLECTION || 'submissions';
const QR_SECRET = process.env.QR_SECRET || 'supersecret123';

if (!MONGODB_URI) {
  console.error('Missing MONGODB_URI');
  process.exit(1);
}

const client = new MongoClient(MONGODB_URI, { serverSelectionTimeoutMS: 20000 });
let col;

async function initDb() {
  await client.connect();
  col = client.db(DB_NAME).collection(COLLECTION);
  await col.createIndex({ id: 1 }, { unique: true });
  console.log('MongoDB connected');
}

function verifySignature({ id, capturedAt, deviceId }, signature) {
  const data = `${id}|${capturedAt}|${deviceId ?? 'unknown'}`;
  const mac = crypto.createHmac('sha256', QR_SECRET).update(data).digest('hex');
  try {
    return crypto.timingSafeEqual(Buffer.from(mac), Buffer.from(signature));
  } catch {
    return false;
  }
}

app.get('/health', (_req, res) => res.json({ ok: true }));
app.get('/', (_req, res) => res.send('HydroGauge backend is running ✅'));

// Anomaly detection (z-score over last N readings)
app.get('/sites/:siteId/anomaly', async (req, res) => {
  try {
    const siteId = req.params.siteId;
    const N = Number(process.env.ANOMALY_WINDOW || 20);
    const docs = await col
      .find({ siteId })
      .sort({ capturedAt: -1 })
      .limit(N)
      .toArray();

    if (!docs.length) return res.json({ z: 0, risk: 'low' });
    const values = docs.map((d) => Number(d.waterLevelMeters)).reverse();
    if (values.length < 2) return res.json({ z: 0, risk: 'low' });

    const mean = values.reduce((a, b) => a + b, 0) / values.length;
    const variance = values.reduce((a, b) => a + Math.pow(b - mean, 2), 0) / values.length;
    const sd = Math.sqrt(variance);
    const latest = values[values.length - 1];
    const z = sd === 0 ? 0 : (latest - mean) / sd;
    const absZ = Math.abs(z);
    const risk = absZ >= 3 ? 'high' : absZ >= 2 ? 'med' : 'low';
    return res.json({ z: Number(z.toFixed(2)), risk });
  } catch (e) {
    console.error('Anomaly endpoint error', e);
    return res.status(500).json({ error: 'Failed to compute anomaly' });
  }
});

// Forecast route - simple exponential smoothing over last 100 readings
app.get('/sites/:siteId/forecast', async (req, res) => {
  try {
    const siteId = req.params.siteId;
    const docs = await col
      .find({ siteId })
      .sort({ capturedAt: 1 })
      .limit(100)
      .toArray();
    if (!docs.length) return res.json({ forecast: [] });
    const levels = docs.map((d) => Number(d.waterLevelMeters));
    const alpha = Number(process.env.FORECAST_ALPHA || 0.3);
    let s = levels[0] ?? 0;
    for (let i = 1; i < levels.length; i++) {
      s = alpha * levels[i] + (1 - alpha) * s;
    }
    const horizon = Number(process.env.FORECAST_HOURS || 12);
    const forecast = Array.from({ length: horizon }, (_, i) => ({ t: i, y: s }));
    return res.json({ forecast });
  } catch (e) {
    console.error('Forecast endpoint error', e);
    return res.status(500).json({ error: 'Failed to compute forecast' });
  }
});

app.post('/submissions', async (req, res) => {
  try {
    const sig = req.header('X-Signature') || '';
    const p = req.body || {};
    if (!verifySignature({ id: p.id, capturedAt: p.capturedAt, deviceId: p.deviceId }, sig)) {
      return res.status(401).json({ ok: false, error: 'Invalid signature' });
    }
    for (const f of ['id','siteId','siteName','waterLevelMeters','lat','lng','capturedAt','imageUrl']) {
      if (p[f] === undefined || p[f] === null) {
        return res.status(400).json({ ok: false, error: `Missing field: ${f}` });
      }
    }
    p.status = 'synced';
    p.createdAt = new Date();
    await col.insertOne(p);
    return res.json({ ok: true });
  } catch (e) {
    if (e?.code === 11000) return res.status(200).json({ ok: true, dedup: true });
    console.error('POST /submissions error', e);
    return res.status(500).json({ ok: false, error: 'Server error' });
  }
});

const PORT = process.env.PORT || 8080;
initDb()
  .then(() => app.listen(PORT, () => console.log(`API listening on ${PORT}`)))
  .catch((e) => {
    console.error('Failed to init DB', e);
    process.exit(1);
  });


// --- START: TEMP DEV auth routes (for Flutter frontend testing) ---
app.post('/auth/register', async (req, res) => {
  try {
    console.log('DEV /auth/register body:', req.body);
    const dummyUser = { id: `dev_\${Date.now()}`, username: req.body?.username || 'dev-user', role: req.body?.role || 'Field Personnel' };
    return res.json({ ok: true, user: dummyUser, token: 'dev-token' });
  } catch (e) {
    console.error('DEV /auth/register error', e);
    return res.status(500).json({ ok: false, error: 'dev server error' });
  }
});

app.post('/auth/login', (req, res) => {
  console.log('DEV /auth/login body:', req.body);
  return res.json({ ok: true, token: 'dev-token', user: { id: 'dev', username: 'dev' } });
});
// --- END: TEMP DEV auth routes ---

