# خطوات التركيب (من الهاتف فقط)

الملفات: index.html (الصفحة العامة) • admin.html (لوحة الإدارة) • style.css • firebase-config.js • firestore.rules

## 1) إعداد Firebase
1. Firebase Console > مشروع syriachat-e10bd > Authentication > Sign-in method > فعّل Email/Password.
2. Authentication > Settings > Authorized domains > أضف: syriachat-5.github.io
3. Firestore Database > Rules > احذف القديم والصق محتوى firestore.rules > Publish.
4. Project settings > Your apps > Web app > انسخ apiKey و appId وضعهما في firebase-config.js.

## 2) الرفع على GitHub
ارفع الملفات الخمسة إلى المستودع نفسه (Add file > Upload files) ثم Commit.
الرابط العام: https://syriachat-5.github.io/Syriachat/
لوحة الإدارة: https://syriachat-5.github.io/Syriachat/admin.html

## 3) أول مشرف
1. افتح الصفحة العامة وأنشئ حسابك.
2. Firebase > Authentication > Users > انسخ UID حسابك.
3. Firestore > Start collection باسم admins > Document ID = الـ UID المنسوخ > أضف حقل ok (boolean) = true.
4. افتح admin.html وادخل بنفس البريد. أنشئ غرفة من تبويب "الغرف".

## الحماية
- مفتاح apiKey ظاهر للعامة بطبيعته؛ الحماية الحقيقية في firestore.rules وليس في إخفاء الصفحة.
- المشرف يُحدَّد فقط بوجود وثيقته في admins، ولا يمكن لأي مستخدم إضافتها من التطبيق.
- المحظور لا يقرأ ولا يكتب. المستخدم لا يستطيع رفع الحظر عن نفسه.
- إيقاف التطبيق من لوحة الإدارة يظهر للجميع فوراً بلا تحديث.

## غير مشمول
الإشعارات والمكالمات والـ APK لم تُبنَ في هذه النسخة.
