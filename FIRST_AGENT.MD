# FIRST_AGENT.md

**Purpose**

این سند وظایف راه‌اندازی اولیهٔ مخزن Flutter (وب/اندروید) را تعریف می‌کند و تضمین می‌کند که ساختار، خودکارسازی‌ها، امن‌سازی، تست، لاگ‌گذاری و ریلزها از همان ابتدا استاندارد شوند.

---

## 1) چک‌لیست بوت‌استرپ مخزن

- [ ] ایجاد فایل‌های پایه در ریشه:
  - `README.md` (نمای کلی محصول و دستورهای اجرا)
  - `STRUCTURE.md` (معماری ماژولار: `app/`, `core/`, `features/` با شرح نقش هر پوشه)
  - `API.md` (نقاط انتهایی بک‌اند، سرآیندهای احراز هویت، فرمت پاسخ‌ها)
  - `SECURITY.md` (سیاست گزارش آسیب‌پذیری‌ها، افشای هماهنگ)
  - `CONTRIBUTING.md` (معیارهای مشارکت، Commit Convention)
  - `CHANGELOG.md` (مطابق «Keep a Changelog»)
  - `agent.log` (لاگ خطی فعالیت ایجنت‌ها – قالب در ادامه)
  - `.env.example` (متغیرهای لازم سمت کلاینت وب/اندروید)
  - `.editorconfig`, `.gitignore` (الگوی رسمی Flutter + Android)
  - `CODEOWNERS` (حداقل مالکیت برای `app/`, `core/`, `features/`)

- [ ] استاندارد کردن **برنچ‌ها**:
  - `main` (پایدار/قابل انتشار)
  - `develop` (ادغام توسعه)
  - نام‌گذاری فیچرها: `feature/<scope>-<short-title>`

- [ ] فعال‌سازی سیاست **Commit**: «Conventional Commits» (`feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:` ...)

- [ ] فعال‌سازی **Semantic Versioning** (فایل `pubspec.yaml` → فیلد `version: MAJOR.MINOR.PATCH+build`)

---

## 2) پیکربندی بات‌ها و خودکارسازی‌ها

### 2.1) CodeRabbit

در ریشه، فایل زیر را ایجاد/اصلاح کنید تا بررسی روی همهٔ برنچ‌های پایه/هدف فعال باشد و پیام وضعیت نیز نمایش داده شود.

```yaml
# .coderabbit.yaml
# yaml-language-server: $schema: https://coderabbit.ai/integrations/schema.v2.json
reviews:
  enabled: true
  review_status: true           # برای پنهان‌سازی پیام وضعیت، به false تغییر دهید
  base_branches: ["*"]         # فعال‌سازی روی همه برنچ‌های پایه/هدف
  event_triggers:
    pr_opened: true
    pr_synchronized: true
    comment_command: true       # پشتیبانی از @coderabbitai review
summary:
  enabled: true
```

نکته: اگر بررسی خودکار غیرفعال است، در PR بنویسید: `@coderabbitai review`.

### 2.2) Gemini Code Assist

دایرکتوری `.gemini/` را اضافه کنید:

```md
/.gemini
  ├─ style.md          # قوانین سبک کدنویسی (Effective Dart، Flutter Lints، Clean Architecture)
  └─ rules.yaml        # سیاست بازبینی (دامنه تغییرات، امنیت، عملکرد، تست)
```

نمونهٔ حداقلی:

```md
# .gemini/style.md
- از Effective Dart پیروی کنید.
- به null-safety و immutability توجه کنید.
- وابستگی‌ها حداقل نگه داشته شوند؛ side-effect ها شفاف باشند.
```

```yaml
# .gemini/rules.yaml
checklists:
  - name: Security
    items:
      - No secrets in source
      - Validate all external inputs
      - HTTPS-only endpoints
  - name: Performance
    items:
      - Avoid unnecessary rebuilds
      - Use const widgets where possible
```

### 2.3) GitHub Actions (CI/CD)

سه ورک‌فلو بسازید در `.github/workflows/`:

```yaml
# ci.yml – لاینتر، تست، بیلد وب به عنوان اطمینان حداقلی روی هر PR
name: CI
on:
  pull_request:
    branches: [ "**" ]
  push:
    branches: [ develop ]
jobs:
  flutter-ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: 'stable' }
      - run: flutter --version
      - run: flutter pub get
      - run: flutter analyze --no-fatal-infos --no-congratulate
      - run: flutter test --coverage
      - run: flutter build web --release --web-renderer canvaskit
      - uses: actions/upload-artifact@v4
        with: { name: web-build, path: build/web }
```

```yaml
# release-android.yml – انتشار APK/AAB روی Tag
name: Release Android
on:
  push:
    tags: [ 'v*.*.*' ]
jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: 'stable' }
      - run: flutter pub get
      - run: flutter build apk --release --split-per-abi
      - run: flutter build appbundle --release
      - uses: actions/upload-artifact@v4
        with:
          name: android-apk
          path: build/app/outputs/flutter-apk/*.apk
      - uses: actions/upload-artifact@v4
        with:
          name: android-aab
          path: build/app/outputs/bundle/release/*.aab
```

```yaml
# release-web.yml – انتشار وب روی Tag (به عنوان آرتیفکت یا پیاده‌سازی جداگانه)
name: Release Web
on:
  push:
    tags: [ 'v*.*.*' ]
jobs:
  build-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: 'stable' }
      - run: flutter pub get
      - run: flutter build web --release --web-renderer canvaskit
      - uses: actions/upload-artifact@v4
        with: { name: web-build, path: build/web }
```

### 2.4) Issue / PR Templates

پوشهٔ `.github/ISSUE_TEMPLATE/`:

```md
/.github/ISSUE_TEMPLATE
  ├─ bug_report.md
  ├─ feature_request.md
  └─ task.md
```

**bug_report.md**
```md
---
name: Bug report
about: گزارش باگ
labels: bug
---
**شرح باگ**
رفتار فعلی:
رفتار مورد انتظار:
گام‌های بازتولید:
لاگ‌ها/اسکرین‌شات:
نسخه/برنچ:
چک‌لیست:
- [ ] تست بازتولید افزوده شد
- [ ] امنیت بررسی شد
```

**feature_request.md**
```md
---
name: Feature request
about: پیشنهاد قابلیت جدید
labels: enhancement
---
**شرح قابلیت**
انگیزه/ارزش:
دامنه و معیار پذیرش:
اثرات بر ساختار/سکیوریتی:
```

**task.md**
```md
---
name: Task
about: کار فنی/نگه‌داری
labels: task
---
شرح کار:
تعریف Done:
خطرات/وابستگی‌ها:
```

**PULL_REQUEST_TEMPLATE.md** (در `.github/`)
```md
## خلاصه تغییرات

## نوع تغییر
- [ ] feat
- [ ] fix
- [ ] refactor
- [ ] docs
- [ ] test

## چک‌لیست
- [ ] تست‌ها پاس شدند و کاوریج افت نکرد
- [ ] `STRUCTURE.md`/`API.md`/`README.md` در صورت نیاز به‌روزرسانی شد
- [ ] نسخه و `CHANGELOG.md` به‌روزرسانی شد
- [ ] امنیت و حریم خصوصی بررسی شد
- [ ] `@coderabbitai review` و `@gemini-code-assist` فراخوانی شدند (در صورت نیاز)
```

---

## 3) امنیت و انطباق

- **توکن‌ها/کلیدها** فقط از محیط یا Secret Store گیت‌هاب خوانده شوند؛ در سورس/تاریخچه ممنوع.
- فعال‌سازی **Dependabot** و **Secret Scanning**:

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "pub"
    directory: "/"
    schedule: { interval: "weekly" }
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule: { interval: "weekly" }
```

- `SECURITY.md` باید مسیر گزارش باگ امنیتی و زمان‌بندی پاسخ را مشخص کند (مثلاً پاسخ اولیه ≤72h).

---

## 4) بیلد، خروجی‌ها و SEO (Flutter Web/Android)

### 4.1) دستورات بیلد

- **Web**
  ```bash
  flutter clean && flutter pub get
  flutter build web --release --web-renderer canvaskit
  # خروجی: build/web
  ```
- **Android (APK/AAB)**
  ```bash
  flutter clean && flutter pub get
  flutter build apk --release --split-per-abi
  flutter build appbundle --release
  # خروجی: build/app/outputs
  ```

### 4.2) SEO وب

- فایل‌های `web/robots.txt` و `web/sitemap.xml` را اضافه/به‌روزرسانی کنید.
- به‌روزرسانی `<title>` و meta-tagها بر اساس مسیر فعال (Route) – هماهنگ با `go_router`.

---

## 5) تست و پوشش

- اجرای `flutter test --coverage` در CI اجباری است.
- آستانهٔ حداقلی کاوریج (مثلاً 60٪) را برقرار کنید و افت کاوریج را Fail کنید.
- برای فیچرهای UI مهم، از `integration_test` استفاده شود.

---

## 6) لاگ‌گذاری ایجنت‌ها

فایل `agent.log` در ریشه، **Append-only**:

```
YYYY-MM-DDTHH:mm:ssZ | agent=<name> | action=<plan|impl|test|build|docs|release|fix> | ref=<branch/commit/pr> | note=<short-message>
```

نمونه:
```
2025-08-14T14:10:00Z | agent=codex-1 | action=plan | ref=feature/chat-ocr | note=Bootstrap CI and fix OCR metadata
```

---

## 7) اصلاحات فوری از بازبینی PR اخیر (مصوب)

- **OCR (`lib/features/chat/data/ocr_service.dart`)**: استفاده از `InputImage.fromBytes` با `InputImageMetadata` صحیح (اندازه/فرمت/rotation/bytesPerRow). نمونهٔ پیشنهادی:
  ```dart
  import 'package:image/image.dart' as img;
  final decoded = img.decodeImage(imageBytes);
  if (decoded == null) return '';
  final input = InputImage.fromBytes(
    bytes: imageBytes,
    metadata: InputImageMetadata(
      size: Size(decoded.width.toDouble(), decoded.height.toDouble()),
      rotation: InputImageRotation.rotation0deg,
      format: InputImageFormat.bgra8888,
      bytesPerRow: decoded.width * 4,
    ),
  );
  ```
- **Media Picker (`media_service.dart`)**: پارامتر `imageQuality` منسوخ؛ حذف شود و فشرده‌سازی در مسیر تبدیل JPEG انجام گردد.
- **Snackbars**: استفادهٔ مجدد از `AppSnack.show()` به‌جای متدهای محلی تکراری.
- **Profile Screen**: در بلاک `catch` پیام خطا به کاربر نمایش داده شود؛ لاگ مناسب نیز اضافه گردد.

---

## 8) تحویل و ریلز

- برچسب‌گذاری نسخه با `vMAJOR.MINOR.PATCH`.
- پیوست آرتیفکت‌های وب/اندروید به Release یا ارسال به کانال توزیع داخلی.
- به‌روزرسانی `CHANGELOG.md` و `README.md` اجباری.

---

## 9) تحویل به ایجنت بعدی (Handoff)

- فایل `NEXT_TASK.md` را بسازید/به‌روزرسانی کنید و مرحلهٔ فعلی، ریسک‌ها و سه کار بعدی را فهرست کنید.
- ورودی‌های پیوسته به `agent.log` اضافه شوند.
