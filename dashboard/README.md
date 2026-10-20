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

## النشر على Vercel

الداشبورد في مجلّد فرعي (`dashboard/`)، على هيكا **لازم تحدّد Root Directory**.

### الطريقة 1 — من GitHub (الأسهل)

1. [vercel.com/new](https://vercel.com/new) ← Import الـrepo `marwenbannour/tiktok-studio`.
2. **Root Directory** → اختار `dashboard`.
3. Framework: Next.js (يتعرّف وحدو). Build: `next build` (default).
4. **Environment Variables** → زيد الأربعة:
   - `BACKEND_URL`, `APP_TOKEN`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`
5. Deploy. أي push على `main` يعمل redeploy وحدو.

### الطريقة 2 — بالـCLI

```bash
cd dashboard
vercel login
vercel            # أول مرّة: يسأل، خلّي Root Directory = ./ (إنت ديجا في dashboard)
vercel env add BACKEND_URL
vercel env add APP_TOKEN
vercel env add SUPABASE_URL
vercel env add SUPABASE_SERVICE_ROLE_KEY
vercel --prod     # النشر النهائي
```

> الأسرار تتحطّ في Vercel (Environment Variables)، ما تتحطّش في الكود. بلا متغيّرات
> الداشبورد تنشر وتخدم بـ**بيانات تجريبية**.
