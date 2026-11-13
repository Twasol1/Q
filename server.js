// خادم تجريبي. البيانات في الذاكرة وتُعاد عند إعادة تشغيل الخادم.
// للإنتاج: قاعدة بيانات حقيقية، تشفير كلمات المرور، HTTPS، وحدود للطلبات.
const express = require('express');
const crypto = require('crypto');

const app = express();
app.use(express.json());

app.use((req, res, next) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.set('Access-Control-Allow-Methods', 'GET, POST, PATCH, OPTIONS');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'change-me';
const sessions = new Set();

let state = {
  config: { brand: 'محفظتي' },
  user: { name: 'مستخدم تجريبي', balance: 500000, number: 'DEMO-0001' },
  features: { send: true, deposit: true, receive: true },
  notice: '',
  txs: [{ id: 1, label: 'شحن تجريبي', amount: 500000, date: '2026-11-10' }],
};

function addTx(label, amount) {
  state.txs.unshift({
    id: Date.now(),
    label,
    amount,
    date: new Date().toISOString().slice(0, 10),
  });
  state.txs = state.txs.slice(0, 30);
}

function requireAdmin(req, res, next) {
  const token = (req.get('Authorization') || '').replace('Bearer ', '');
  if (!sessions.has(token)) return res.status(401).json({ error: 'غير مصرّح' });
  next();
}

function passwordOk(input) {
  const a = Buffer.from(String(input));
  const b = Buffer.from(ADMIN_PASSWORD);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

const isInt = (n) => Number.isInteger(n);

// ---- عام ----
app.get('/api/state', (_req, res) => res.json(state));

// ---- لوحة التحكم ----
app.post('/api/admin/login', (req, res) => {
  if (!passwordOk(req.body?.password ?? '')) {
    return res.status(401).json({ error: 'كلمة المرور غير صحيحة' });
  }
  const token = crypto.randomUUID();
  sessions.add(token);
  res.json({ token });
});

app.patch('/api/admin/state', requireAdmin, (req, res) => {
  const b = req.body || {};
  if (typeof b.brand === 'string') state.config.brand = b.brand.slice(0, 40);
  if (typeof b.userName === 'string') state.user.name = b.userName.slice(0, 60);
  if (typeof b.notice === 'string') state.notice = b.notice.slice(0, 200);
  if (b.features && typeof b.features === 'object') {
    for (const k of ['send', 'deposit', 'receive']) {
      if (typeof b.features[k] === 'boolean') state.features[k] = b.features[k];
    }
  }
  res.json(state);
});

app.post('/api/admin/adjust', requireAdmin, (req, res) => {
  const amount = req.body?.amount;
  if (!isInt(amount) || amount === 0) {
    return res.status(400).json({ error: 'مبلغ غير صالح' });
  }
  if (state.user.balance + amount < 0) {
    return res.status(400).json({ error: 'الرصيد لا يمكن أن يصبح سالباً' });
  }
  state.user.balance += amount;
  addTx(amount > 0 ? 'تعديل من الإدارة (+)' : 'تعديل من الإدارة (-)', amount);
  res.json(state);
});

// ---- المستخدم ----
app.post('/api/user/send', (req, res) => {
  if (!state.features.send) {
    return res.status(403).json({ error: 'الإرسال متوقف حالياً' });
  }
  const { to, amount } = req.body || {};
  if (typeof to !== 'string' || !to.trim()) {
    return res.status(400).json({ error: 'أدخل اسم المستلم' });
  }
  if (!isInt(amount) || amount <= 0) {
    return res.status(400).json({ error: 'مبلغ غير صالح' });
  }
  if (amount > state.user.balance) {
    return res.status(400).json({ error: 'الرصيد غير كافٍ' });
  }
  state.user.balance -= amount;
  addTx('إرسال إلى ' + to.trim().slice(0, 40), -amount);
  res.json(state);
});

app.post('/api/user/deposit', (req, res) => {
  if (!state.features.deposit) {
    return res.status(403).json({ error: 'الشحن متوقف حالياً' });
  }
  const { amount } = req.body || {};
  if (!isInt(amount) || amount <= 0) {
    return res.status(400).json({ error: 'مبلغ غير صالح' });
  }
  state.user.balance += amount;
  addTx('شحن تجريبي', amount);
  res.json(state);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log('Demo API on port ' + PORT));
