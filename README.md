# Gold Exchange Shop (Flutter + Firebase)

تطبيق لإدارة محل واحد لبيع/شراء الذهب وصرافة العملات (يدوي بالكامل) مع Firebase.

## ما يطابق المتطلبات (مختصر)
- كل الأسعار والكميات تدخل يدويًا.
- لا يوجد تعديل تلقائي للأسعار.
- كل العمليات (بيع/شراء/صرف/تعديل مخزون) = حساب إجمالي + نافذة Confirm/Cancel + تنفيذ بعد Confirm فقط.
- المخزون لا يمكن أن يصبح سالبًا (مفروض داخل Firestore transactions).
- تسجيل دخول: Username + Password (يتم تحويل Username → Email داخليًا).
- منع الدخول إن لم يكن البريد مفعّلًا (مع إرسال Verification Email).
- Register: Username فريد + Email + Password + Shop name + Shop address.
- بعد التسجيل: شاشة CAPTCHA بسيطة (سؤال رياضي) ثم إرسال Verification Email.
- معاملات transactions فقط تحتوي createdAt (serverTimestamp).

## إعداد Firebase (لازم أنت تسويه)
1) أنشئ Firebase project.
2) فعّل Authentication (Email/Password).
3) فعّل Cloud Firestore.
4) أضف تطبيق Android و iOS و ضع ملفات:
   - android/app/google-services.json
   - ios/Runner/GoogleService-Info.plist
5) ضع قواعد Firestore من الملف `firestore.rules`.

## تشغيل
```bash
flutter pub get
flutter run
```

## ملاحظات مهمة
- قراءة `usernames/{username}` في القواعد مسموحة كـ **get فقط** حتى نقدر نعمل Username→Email قبل تسجيل الدخول (بدون list).
- أسعار الـ Home هي Display فقط وغير مستخدمة بالحسابات.
- CAPTCHA هنا “بسيط” داخل التطبيق. لو بدك CAPTCHA حقيقي (reCAPTCHA/AppCheck) خبرني وبجهز لك دمج رسمي.
- فلترة Transactions حسب (التاريخ + العملة) قد تتطلب **Composite Index**؛ إذا ظهر لك رابط إنشاء Index من Firebase Console انسخه ونفذه.
