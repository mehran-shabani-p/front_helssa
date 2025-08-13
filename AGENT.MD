# AGENT.md

**Operating Procedure** – رویهٔ استاندارد برای همهٔ ایجنت‌های بعدی.

---

## 1) دریافت زمینه

1. `agent.log`، `NEXT_TASK.md`، `STRUCTURE.md`، `API.md`، و آخرین PRها/Issues را مرور کنید.
2. اگر سندی غایب است (مثلاً `STRUCTURE.md` یا `API.md`)، **ابتدا ایجاد کنید**.

---

## 2) برنامهٔ کوتاه کار (Plan)

- دامنهٔ دقیق تغییر را بنویسید (حداکثر 5 خط) و در `agent.log` با `action=plan` ثبت کنید.
- در صورت لمس امنیت/حریم خصوصی، بندهای اثر را روشن بنویسید.

---

## 3) پیاده‌سازی (Implement)

- از **Effective Dart** و لایبرری‌های سبک پیروی کنید؛ از `flutter_lints` عبور کند.
- معمار‌ی:
  - `app/` پیکربندی و ورودی برنامه (Theme، Router، DI).
  - `core/` قابلیت‌های اشتراکی (network, storage, utils, design system).
  - `features/<name>/` شامل `data/`, `domain/`, `presentation/`.
- قواعد **go_router** و SEO (title/meta per route) را رعایت کنید.
- در چت/OCR/PDF:
  - برای OCR، ساخت `InputImageMetadata` صحیح را رعایت کنید.
  - برای استخراج PDF از کتابخانهٔ انتخابی استفاده و خطاها را کاربر-پسند مدیریت کنید.
- اسنک‌بار/نوتیف‌ها فقط از Utility مرکزی (مثلاً `AppSnack`) فراخوانی شوند.

---

## 4) تست و تحلیل

- `flutter analyze` بدون خطا/هشدارهای بحرانی.
- `flutter test --coverage` و در صورت لزوم `integration_test` برای مسیرهای حیاتی.
- اگر دادهٔ بیرونی مصرف می‌شود، **mocks** و **fixtures** بیفزایید.

---

## 5) اسناد و نسخه

- اگر ساختار تغییر کرد، `STRUCTURE.md` را به‌روزرسانی کنید.
- اگر قرارداد API تغییر کرد، `API.md` را به‌روزرسانی کنید (نمونه درخواست/پاسخ، کدهای وضعیت).
- نسخه را در `pubspec.yaml` و `CHANGELOG.md` به‌روز کنید؛ از «Conventional Commits» برای نگاشت خودکار CHANGELOG استفاده کنید (در صورت وجود اسکریپت).

---

## 6) امنیت

- ورود هر متغیر حساس فقط از محیط؛ بررسی کنید چیزی به سورس نشت نکرده باشد.
- ورودی‌های کاربر را اعتبارسنجی کنید (وب/اندروید) و مسیرهای ذخیره‌سازی محلی را بازبینی کنید.

---

## 7) بیلد و آرتیفکت‌ها

- **Web**: `flutter build web --release --web-renderer canvaskit`
- **Android**: `flutter build apk --release --split-per-abi` و `flutter build appbundle --release`
- آرتیفکت‌ها را در CI آپلود کنید و مسیر خروجی را در PR ذکر کنید.

---

## 8) PR و بازبینی

- PR را از برنچ فیچر به `develop` باز کنید؛ عنوان با الگوی Conventional Commit.
- قالب PR را تکمیل و لینک Issue را اضافه کنید (`Fixes #<id>`).
- در توضیحات PR بنویسید: `@coderabbitai review` و در صورت نیاز، از Gemini نیز بازبینی بخواهید.
- همهٔ چک‌ها باید سبز باشند (CI، کاوریج، Lints).

---

## 9) لاگ‌گذاری و تحویل

- پایان کار را در `agent.log` با `action=impl|test|build|docs` ثبت کنید.
- `NEXT_TASK.md` را با مرحلهٔ بعدی و ریسک‌ها به‌روزرسانی کنید.

---

## 10) برنچینگ، ریلیز و تگ‌ها

- ادغام به `main` فقط از طریق Release PR.
- تگ‌گذاری: `vMAJOR.MINOR.PATCH`.
- ایجاد Release Note بر اساس `CHANGELOG.md`.

---

## پیوست‌ها – میان‌بُر دستورات

```bash
# آماده‌سازی
flutter clean && flutter pub get

# تحلیل و تست
flutter analyze --no-fatal-infos --no-congratulate
flutter test --coverage

# بیلد
flutter build web --release --web-renderer canvaskit
flutter build apk --release --split-per-abi
flutter build appbundle --release
```

**الگوی ورودی `agent.log`:**
```
<UTC-ISO8601> | agent=<id> | action=<plan|impl|test|build|docs|release|fix> | ref=<branch/commit/pr> | note=<...>
```

---

## چک‌لیست تحویل برای هر ایجنت

- [ ] Plan نوشته و در `agent.log` ثبت شد
- [ ] کد پیاده‌سازی و تست‌ها پاس شدند
- [ ] اسناد (`STRUCTURE.md`/`API.md`/`README.md`) به‌روز شد
- [ ] نسخه و `CHANGELOG.md` به‌روزرسانی شد
- [ ] PR با قالب استاندارد باز شد و بات‌ها فراخوانی شدند
- [ ] `NEXT_TASK.md` برای ایجنت بعدی تکمیل شد

