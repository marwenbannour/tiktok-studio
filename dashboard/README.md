# Dashboard — Studio TikTok (Next.js)

لوحة تحكّم ويب مربوطة بالسيرفر الوسيط (Edge Function). فيها:

- **الإحصائيات** (`/`): استعمال الـAPI — عدد التوليدات، هالشهر، نسبة النجاح،
  متوسّط المدّة، رسم بياني في الوقت، حسب الموديل، وآخر الطلبات.
- **المولّد** (`/generate`): تولّد سكريبت TikTok بالدارجة عبر نفس السيرفر الوسيط.

```
المتصفّح ──▶ Next.js (API routes, الأسرار هوني) ──▶ Edge Function ──▶ ollama.com
                         │
                         └──▶ Supabase (usage_log) للإحصائيات
```

الأسرار (`APP_TOKEN`, `SERVICE_ROLE_KEY`) يقعدو في **سيرفر Next.js** برك، ما يبانوش
فالمتصفّح.

## التشغيل

```bash
cd dashboard
npm install
cp .env.example .env.local   # وعمّرو بالقيم متاعك
npm run dev                  # http://localhost:3000
```

> بلا `.env.local`، الداشبورد تخدم بـ**بيانات تجريبية** (demo) باش تشوف الشكل.

## متغيّرات البيئة (`.env.local`)

| المتغيّر | الوصف |
|---|---|
| `BACKEND_URL` | عنوان الـEdge Function (`…/functions/v1/generate`) |
| `APP_TOKEN` | نفس `APP_TOKEN` متاع الـbackend (x-app-token) |
| `SUPABASE_URL` | عنوان مشروع Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | مفتاح service role (قراءة `usage_log`) |

## الإحصائيات

تقرا من جدول `usage_log` (شوف [`../backend`](../backend)). الـEdge Function تكتب صفّ
لكل طلب توليد. طبّق الـmigration:

```bash
cd ../backend
supabase db push   # يطبّق supabase/migrations/*_usage_log.sql
```

## النشر

أي منصّة تدعم Next.js (Vercel مثلا): اربط الـrepo، حطّ المتغيّرات الأربعة، وانشر.
