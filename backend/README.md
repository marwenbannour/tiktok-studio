# السيرفر الوسيط — Studio TikTok (Backend)

سيرفر صغير (**Supabase Edge Function**) يخبّي مفتاح Ollama في السيرفر عوض ما يكون
على التليفون. هكّاكا تنجّم تنشر الـapp على **Play Store** بلا ما المفتاح يكون فالـAPK،
والمستخدمين ما يحتاجوش مفتاح خاصّ بيهم.

```
التطبيق  ──(x-app-token)──▶  Edge Function (generate)  ──(Bearer OLLAMA_API_KEY)──▶  ollama.com
         ◀──── JSON ────────                           ◀──────── JSON ───────────
```

المفتاح `OLLAMA_API_KEY` يقعد **برك فالسيرفر**. الـapp تبعث `x-app-token` (كلمة سرّ
تاع التطبيق) باش ما يستعملش السيرفرَ حتى واحد آخر.

> نطاق المرحلة هذي: **proxy شخصي** (بلا حسابات). الحسابات ومزامنة الـhistorique = مرحلة جاية.

---

## 1. اللي تحتاجو

- حساب [Supabase](https://supabase.com) (الـplan المجّاني يكفي).
- [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started) مثبّت.
- مفتاح [ollama.com](https://ollama.com) (Settings → API Keys).
- كلمة سرّ تاختارها إنتا للتطبيق (`APP_TOKEN`) — أي نصّ طويل وعشوائي.

## 2. اعمل مشروع واربط الـCLI

```bash
# سجّل الدخول
supabase login

# من مجلّد backend/ (فيه supabase/functions/generate)
cd backend

# اربط بمشروعك (الـref تلقاه في Supabase → Project Settings → General)
supabase link --project-ref <PROJECT_REF>
```

## 3. حطّ الأسرار (ما يبانوش فالكود)

```bash
supabase secrets set OLLAMA_API_KEY="<مفتاح_ollama_متاعك>"
supabase secrets set APP_TOKEN="<كلمة_سرّ_طويلة_عشوائية>"
```

توليد `APP_TOKEN` عشوائي (مثال):

```bash
openssl rand -hex 32
```

## 4. انشر الـfunction

```bash
supabase functions deploy generate --no-verify-jwt
```

`--no-verify-jwt` خاطر ما نستعملوش حسابات Supabase؛ الحماية بـ`APP_TOKEN`.

عنوان الـfunction بيكون:

```
https://<PROJECT_REF>.supabase.co/functions/v1/generate
```

## 5. اختبار سريع (curl)

```bash
curl -i -X POST "https://<PROJECT_REF>.supabase.co/functions/v1/generate" \
  -H "content-type: application/json" \
  -H "x-app-token: <كلمة_السرّ>" \
  -d '{"model":"gemma4:31b","messages":[{"role":"user","content":"قولي سلام بالتونسي"}],"stream":false}'
```

- `200` + JSON فيه `message.content` → السيرفر يخدم ✅
- `401` → `x-app-token` غالط.
- `500 server not configured` → الأسرار موش محطوطين.

## 6. ربط التطبيق

في **الإعدادات ← السيرفر الوسيط**:

- **عنوان السيرفر**: `https://<PROJECT_REF>.supabase.co/functions/v1/generate`
- **كلمة سرّ التطبيق**: نفس `APP_TOKEN`

كان العنوان محطوط، الـapp تمشي عبر السيرفر (**ما تحتاجش مفتاح Ollama محلّي**).
كان فارغ، ترجع للوضع المباشر (المفتاح على التليفون).

---

## أمان

- `OLLAMA_API_KEY` يقعد **برك فالسيرفر** — عمرو ما يبان فالـAPK ولا فالـapp.
- `APP_TOKEN` يمنع الغرباء يستعملو السيرفر متاعك. بدّلو كان تشكّ إنّو تسرّب.
- حطّ **حدّ إنفاق شهري** في console متاع ollama.com برضو.
- السقف الأعلى للـ`num_predict` محدّد في [`index.ts`](supabase/functions/generate/index.ts) (`MAX_NUM_PREDICT`).

## الحسابات ومزامنة الـhistorique (V2)

التطبيق ينجّم يزامن السكريبتات بين الأجهزة عبر **Supabase Auth** + جدول `scripts`
(RLS: كل مستخدم يشوف سكريبتاتو برك). يستعمل Supabase REST مباشرة (بلا package إضافي).

**الإعداد:**

1. طبّق الـmigrations (تعمل جدول `scripts` + `usage_log`):
   ```bash
   supabase db push   # يطبّق supabase/migrations/*.sql
   ```
2. في Supabase → **Authentication → Providers** → فعّل **Email**.
   (كان تحب بلا تأكيد إيميل: Authentication → Settings → عطّل "Confirm email".)
3. في التطبيق → **الإعدادات → الحساب والمزامنة**:
   - **URL**: `https://<PROJECT_REF>.supabase.co`
   - **anon key**: من Project Settings → API (مفتاح `anon` `public` — موش سرّي، RLS يحمي).
4. اعمل حساب / ادخل، وبعد **«زامن الآن»**.

الـ`anon key` عمومي (يتحطّ فالتطبيق بلا مشكل)؛ البيانات محميّة بـRLS (JWT المستخدم).
المفتاح السرّي الوحيد يبقى `OLLAMA_API_KEY` فالـEdge Function.

## الخطوة الجاية

- Google sign-in.
- حدّ شهري من جهة السيرفر (جدول عدّاد لكل مستخدم).
