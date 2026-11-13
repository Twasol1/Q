# محفظة تجريبية (Flutter + خادم)

## 1) تشغيل الخادم
```
cd backend
npm init -y
npm install express
ADMIN_PASSWORD=ضع_كلمة_مرورك node server.js
```

## 2) تجهيز مشروع Flutter
الملفات في `lib/` فقط. أنشئ المشروع أولاً ثم انسخ المجلد `lib` و`pubspec.yaml` فوق الموجود:
```
flutter create --project-name wallet_demo .
flutter pub get
```
يتطلب Dart 3.3 أو أحدث.

## 3) تشغيل تطبيق المستخدم (موبايل)
```
flutter run -t lib/main_user.dart --dart-define=API_URL=http://10.0.2.2:3000
```
`10.0.2.2` للمحاكي Android. على هاتف حقيقي استخدم عنوان IP لجهازك على نفس الشبكة.

## 4) تشغيل لوحة التحكم (منفصلة، على المتصفح)
```
flutter run -d chrome -t lib/main_admin.dart --dart-define=API_URL=http://localhost:3000
```
للنشر: `flutter build web -t lib/main_admin.dart` ثم ارفع مجلد `build/web` على أي استضافة.

## ملاحظات
- كل البيانات وهمية، ولا توجد أي عملية مالية حقيقية.
- كلمة المرور الحقيقية موجودة على الخادم فقط، وليست داخل تطبيق الموبايل أو المتصفح.
- تغيير الاسم والميزات والإشعار من اللوحة يظهر للمستخدم خلال 5 ثوانٍ تقريباً.
