# 🎬 ستوديو التيكتوك: app Android بـFlutter

الـapp تعمل نفس الخدمة متاع النسخة الـweb: تختار النوع والفكرة، و Claude يحضّرلك السكريبت ثانية بثانية، والكود، والمونتاج، والـcaption، ومعاها Teleprompter باش تقرى وإنت تسجّل.

## شنوّة فيه المشروع

```
pubspec.yaml                  ← المكتبات
lib/main.dart                 ← الـapp والـbottom bar
lib/claude_api.dart           ← الاتصال بـClaude API
lib/prompts.dart              ← التعليمات اللي تمشي لـClaude (تنجم تبدّلها)
lib/models.dart               ← شكل السكريبت
lib/storage.dart              ← المفتاح (مشفّر) + المحفوظات + الموديل
lib/screens/                  ← الشاشات: حضّر، النتيجة، Teleprompter، المحفوظات، الإعدادات
```

## الخطوة 1: نصّب الأدوات على الـPC

1. نصّب **Flutter** من الموقع الرسمي: flutter.dev ← Get started ← Windows (ولا macOS/Linux) ← Android.
2. نصّب **Android Studio**، وحلّو مرّة وحدة باش ينصّب الـAndroid SDK.
3. افتح terminal (PowerShell) واكتب:
   ```
   flutter doctor
   flutter doctor --android-licenses
   ```
   قبل كل الـlicenses بـ`y`. عاود `flutter doctor` لين يولّي Flutter و Android toolchain ✅.

## الخطوة 2: اعمل المشروع

```
flutter create tiktok_studio
cd tiktok_studio
```

بعد، **فسخ** الـdossier `lib` اللي عملو Flutter، وحطّ في بلاصتو الـdossier `lib` متاعي، وبدّل `pubspec.yaml` بالـfichier متاعي.

```
flutter pub get
```

## الخطوة 3: زيد الإذن متاع الإنترنت (مهمّة برشا!)

افتح `android/app/src/main/AndroidManifest.xml` وزيد السطر هذا **قبل** `<application`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

بلاش السطر هذا، الـAPK يتبنى عادي أما ما يتّصلش بالإنترنت.

واختياري: في نفس الـfichier بدّل `android:label="tiktok_studio"` بـ`android:label="ستوديو التيكتوك"` باش يبان الاسم هكا في التليفون.

## الخطوة 4: جرّبها على التليفون

1. في التليفون: Paramètres ← À propos ← اضغط 7 مرّات على «Numéro de build» باش تحلّ Options développeur، وبعد فعّل **Débogage USB**.
2. ركّح التليفون بالـUSB، وقبل الـpopup اللي يطلع.
3. اكتب:
   ```
   flutter run
   ```

## الخطوة 5: اعمل الـAPK

```
flutter build apk --release
```

الـAPK تلقاه هوني: `build/app/outputs/flutter-apk/app-release.apk`
بعثو للتليفون (USB، Drive…) ونصّبو. ينجم التليفون يطلب منك تقبل «تثبيت تطبيقات من مصادر غير معروفة».

## الخطوة 6: المفتاح متاع Claude API

1. ادخل لـ**console.anthropic.com** واعمل compte.
2. في Billing زيد رصيد (credits). كل سكريبت ياكل شوية tokens؛ ثبّت الأسعار في صفحة الـpricing الرسمية قبل.
3. في API Keys اعمل مفتاح جديد وانسخو.
4. في الـapp: «الإعدادات» ← الصق المفتاح ← «سجّل المفتاح».
5. اختار الموديل: **Haiku** أرخص وأسرع (باهي للبداية)، **Sonnet** أقوى في الكتابة.

## ⚠️ حاجات مهمّة

- **المفتاح هو فلوسك.** ما تحطّوش في الكود، ما تبعثوش لحدّ، وما تخلّيهش يبان في تسجيل الشاشة وإنت تصوّر فيديو!
- الـapp هذي لاستعمالك إنت. كان تحب تنشرها على Play Store للناس الكل، يلزمك server يخبّي المفتاح، خاطر أي مفتاح داخل app ينجم يتسرق.
- إذا الموديلات تبدّلت أسماؤهم، بدّلهم في `lib/storage.dart` (الـmap `models`). الأسماء الصحيحة تلقاهم في docs.claude.com.

## مشاكل معروفة

| المشكل | الحل |
|---|---|
| «المفتاح موش صحيح» | ثبّت إنك نسخت المفتاح كامل، بلا espaces |
| «الطلب ما تقبلش» | غالباً الرصيد كمل، زيد credits |
| «ما فماش كونكسيون» في الـAPK برك | نسيت الخطوة 3 (إذن الإنترنت) |
| `flutter doctor` فيه ❌ | اتبع الحل اللي يكتبهولك تحت كل ❌ |
