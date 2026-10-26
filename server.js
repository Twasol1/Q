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
        return res.status(400).json({ error: 'يرجى إدخال جميع البيانات المطلوبة.' });
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

// ==========================================
// مسار التوجيه الديناميكي (المفقود سابقاً)
// ==========================================
app.get('/:slug', (req, res) => {
    const cleanSub = req.params.slug.toLowerCase().trim();
    
    // قراءة البيانات من ملف domains.json
    if (fs.existsSync(DB_FILE)) {
        const data = JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
        
        if (data[cleanSub]) {
            let target = data[cleanSub].targetUrl;
            
            // التأكد من أن الرابط يبدأ بـ http:// أو https:// لتجنب أخطاء التوجيه
            if (!target.startsWith('http://') && !target.startsWith('https://')) {
                target = 'https://' + target;
            }
            
            // تنفيذ إعادة التوجيه الفوري إلى الرابط المستهدف
            return res.redirect(target);
        }
    }
    
    // إذا لم يتم العثور على النطاق في قاعدة البيانات
    return res.status(404).send('عذراً، هذا النطاق غير موجود أو لم يتم حجزه بعد.');
});

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
