# دليل الاختبارات — ستوديو التيكتوك 🧪

ثلاث مستويات: **host tests** (سريعة، بلا جهاز) · **e2e** (على جهاز/إيميلاتور) ·
**screenshots** (لقطات Play Store).

---

## قبل ما تبدا

```bash
cd tiktok_studio
flutter pub get
flutter analyze          # لازم: No issues found
```

## 1. Host tests (46 test — وحدات + widgets)

يخدمو على الـPC مباشرة، بلا جهاز، في ~15 ثانية:

```bash
flutter test
```

يغطّيو:
- `models_test` · `history_db_test` (drift: بحث، فلترة، مفضّلة، إحصائيات، سلاسل)
- `backup_test` (export/import JSON + dedup) · `sync_test` (push/pull Supabase + refresh 401)
- `backend_proxy_test` (routage backend/direct) · `prompts_test` (hooks + script)
- `gen_cap_test` (F20) · `splash_nav_test` · `widget_test`

تست وحيد:
```bash
flutter test test/backup_test.dart
flutter test --plain-name "F21"      # بالاسم
```

## 2. E2E (20 test — الرحلة الكاملة على جهاز)

يشغّلو التطبيق الكامل على **إيميلاتور/تليفون**. الـAPI (Ollama) و DB و
secure storage **مبدّلين بـmocks** → حتمي وبلاش:

```bash
flutter test integration_test/app_e2e_test.dart -d emulator-5554
```

يغطّيو: المفتاح/الموديل، توليد سكريبت، أفكار، **hooks**, **A/B**, Teleprompter،
المحفوظات (بحث/فلترة/مفضّلة)، البرنامج + تذكيرات، إحصائيات، سلاسل، التصدير،
الحدّ الشهري، وكل رسائل الأخطاء بالدارجة (401/429/529/JSON مكسّر...).

> النتيجة المرجوّة: **+20: All tests passed!**

## 3. Screenshots (لقطات Play Store)

```bash
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshots_test.dart -d emulator-5554
```

الصور تتسجّل في `screenshots/` (شاشة حضّر، النتيجة، المحفوظات، الإعدادات، الإحصائيات،
التسجيل بالكاميرا).

---

## إعداد الإيميلاتور (مهمّ)

على هالمشروع، شغّل الإيميلاتور بـ**ANGLE GPU** (الـdriver العادي يطيّح الـapp):

```bash
emulator -avd Medium_Phone -gpu angle_indirect -no-snapshot -no-boot-anim
```

## ملاحظات حلّ المشاكل (معروفة)

- **الخطوط**: Poppins **مدمجة** (`google_fonts/`) + `allowRuntimeFetching=false`
  → التست ما يحتاجش إنترنت. (قبل كان يطيح بـ«Failed to load font» على جهاز بلا شبكة.)
- **secure storage**: keystore الإيميلاتور غير مستقرّ ويرجّع `null` بعد الكتابة →
  الـe2e **يعمل mock** للـchannel (`plugins.it_nomads.com/flutter_secure_storage`).
- **قاعدة البيانات**: الـtests يستعملو `AppDatabase.forTesting(NativeDatabase.memory())`.
- **Ollama**: `MockClient` يرجّع نتيجة ثابتة (و404 لطلبات غير-ollama).
- كان الإيميلاتور يموت وقت البناء: عاود (`-gpu angle_indirect` يساعد)، وانتظر
  `sys.boot_completed=1` قبل التشغيل.

## البناء (APK)

```bash
flutter build apk --release --split-per-abi   # ملفات لكل معمارية (أصغر)
flutter build apk --release                    # ملف universal
flutter build appbundle --release              # AAB للـPlay Store
```

الشرط: `flutter analyze` نظيف، وحجم الـAPK **< 25 Mo** (حاليًا ~22-23 Mo).
التوقيع من `android/key.properties` + `upload-keystore.jks` (موش في git).
