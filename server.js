const express = require('express');
const fs = require('fs');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;
const DB_FILE = path.join(__dirname, 'domains.json');

app.use(express.json());
app.use(cors());
app.use(express.static(__dirname));

// تهيئة قاعدة البيانات المحلية إذا لم تكن موجودة
if (!fs.existsSync(DB_FILE)) {
    fs.writeFileSync(DB_FILE, JSON.stringify({}, null, 2));
}

// جلب قائمة النطاقات المسجلة
app.get('/api/domains', (req, res) => {
    const data = JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
    res.json(data);
});

// تسجيل نطاق فرعي جديد
app.post('/api/register', (req, res) => {
    const { subdomain, targetUrl } = req.body;

    if (!subdomain || !targetUrl) {
        return res.status(400).json({ error: 'يرجى إدخال جميع البيانات المطلوب.' });
    }

    const cleanSub = subdomain.toLowerCase().trim();
    const data = JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));

    if (data[cleanSub]) {
        return res.status(400).json({ error: 'هذا النطاق الفرعي محجوز بالفعل!' });
    }

    data[cleanSub] = {
        targetUrl,
        createdAt: new Date().toISOString()
    };

    fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2));
    res.json({ success: true, message: `تم تسجيل النطاق ${cleanSub} بنجاح!` });
});

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
