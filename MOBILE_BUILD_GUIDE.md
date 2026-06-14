
# دليل بناء تطبيق Jouw Driver للموبايل

## نظرة عامة

هذا الدليل يشرح كيفية تحويل مشروع Next.js إلى تطبيق أصلي لـ Android وiOS باستخدام Capacitor،
ورفعه على Google Play Store وApple App Store.

> **ملاحظة مهمة**: التطبيق يعمل بنظام **Server Mode** — أي أن التطبيق الأصلي يتصل بسيرفر Next.js المنشور
> ويعرض المحتوى منه. هذا يعني أن جميع API routes والمصادقة تعمل بشكل طبيعي.

---

## المتطلبات الأساسية

### عام
- Node.js 18+
- pnpm مثبت بشكل عام
- **سيرفر Next.js منشور ومتاح على الإنترنت** (مطلوب قبل البناء)

### Android
- Java JDK 17+
- Android Studio (أحدث إصدار)
- Android SDK (API level 33+)
- متغير البيئة `ANDROID_HOME` مضبوط

### iOS (macOS فقط)
- Xcode 15+
- CocoaPods: `sudo gem install cocoapods`
- حساب Apple Developer (مدفوع - 99$/سنة)

---

## الخطوة 1 — تثبيت Capacitor

```bash
pnpm add @capacitor/core @capacitor/cli
pnpm add @capacitor/android @capacitor/ios
pnpm add @capacitor/splash-screen @capacitor/status-bar
pnpm add @capacitor/geolocation @capacitor/push-notifications
pnpm add @capacitor/keyboard
```

---

## الخطوة 2 — ضبط رابط السيرفر

افتح `capacitor.config.ts` وعدّل:
```ts
server: {
  url: 'https://your-actual-domain.com', // ← ضع رابط سيرفرك الفعلي هنا
}
```

> التطبيق سيتصل بهذا الرابط مباشرة — لا حاجة لـ static export.

---

## الخطوة 3 — تهيئة Capacitor (مرة واحدة فقط)

```bash
# تهيئة المشروع
npx cap init "Jouw Driver" "com.jouwdriver.app" --web-dir out

# إضافة المنصات
npx cap add android
npx cap add ios

# مزامنة الأصول
npx cap sync
```

---

## الخطوة 4 — بناء Android APK

### بناء سريع (باستخدام السكريبت)
```bash
# APK للاختبار
bash capacitor-build.sh debug

# APK للإصدار
bash capacitor-build.sh release

# AAB لـ Google Play
bash capacitor-build.sh aab
```

### بناء يدوي
```bash
npx cap sync android
cd android
./gradlew assembleDebug
# الملف في: android/app/build/outputs/apk/debug/app-debug.apk
```

### توقيع APK للإصدار
```bash
# إنشاء keystore (مرة واحدة فقط — احتفظ بها بأمان!)
keytool -genkey -v -keystore jouwdriver.keystore \
  -alias jouwdriver -keyalg RSA -keysize 2048 -validity 10000

# توقيع APK
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
  -keystore jouwdriver.keystore \
  android/app/build/outputs/apk/release/app-release-unsigned.apk \
  jouwdriver

# محاذاة APK
zipalign -v 4 \
  android/app/build/outputs/apk/release/app-release-unsigned.apk \
  jouwdriver-release.apk
```

---

## الخطوة 5 — بناء iOS IPA

> macOS فقط

```bash
bash capacitor-ios-build.sh
```

في Xcode:
1. اختر `Any iOS Device (arm64)` كجهاز هدف
2. `Product > Archive`
3. في Organizer: `Distribute App > App Store Connect`
4. صدّر IPA

---

## الخطوة 6 — رفع على Google Play Store

### المتطلبات
- حساب Google Play Developer (25$ رسوم لمرة واحدة)
- ملف AAB موقَّع

### الخطوات
1. افتح [Google Play Console](https://play.google.com/console)
2. أنشئ تطبيقاً جديداً
3. أكمل معلومات التطبيق:
   - الاسم: `Jouw Driver`
   - الوصف: نظام إدارة سيارات الأجرة المحترف
   - الفئة: `Business` أو `Travel & Local`
4. ارفع ملف AAB في قسم `Production > Releases`
5. أضف لقطات الشاشة والأيقونات
6. أرسل للمراجعة (عادة 1-3 أيام)

### أيقونات Android المطلوبة
ضع الأيقونات في:
```
android/app/src/main/res/
  mipmap-mdpi/ic_launcher.png        (48x48)
  mipmap-hdpi/ic_launcher.png        (72x72)
  mipmap-xhdpi/ic_launcher.png       (96x96)
  mipmap-xxhdpi/ic_launcher.png      (144x144)
  mipmap-xxxhdpi/ic_launcher.png     (192x192)
```
استخدم [appicon.co](https://appicon.co) لتوليد جميع الأحجام.

---

## الخطوة 7 — رفع على Apple App Store

### المتطلبات
- حساب Apple Developer (99$/سنة)
- Mac مع Xcode 15+
- شهادات توقيع صالحة

### الخطوات
1. افتح [App Store Connect](https://appstoreconnect.apple.com)
2. أنشئ تطبيقاً جديداً بـ Bundle ID: `com.jouwdriver.app`
3. أكمل معلومات التطبيق
4. ارفع IPA عبر Xcode Organizer أو Transporter
5. أرسل للمراجعة (عادة 1-7 أيام)

### أيقونات iOS المطلوبة
ضع الأيقونات في:
```
ios/App/App/Assets.xcassets/AppIcon.appiconset/
```
الأحجام المطلوبة: 20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024 px

---

## إعداد الأيقونات والـ Splash Screen

### الأيقونة الرسمية
```
https://cdn.chat2db-ai.com/app/avatar/custom/16eda623-2b94-41ea-8390-395dcb708494_737955.png
```

### توليد جميع الأحجام تلقائياً
1. اذهب إلى [appicon.co](https://appicon.co)
2. ارفع الأيقونة بحجم 1024x1024
3. حمّل حزمة Android وiOS
4. ضع الملفات في المسارات المذكورة أعلاه

### Splash Screen
- Android: `android/app/src/main/res/drawable/splash.png`
- لون الخلفية: `#020817` (مضبوط في capacitor.config.ts)

---

## إعدادات الصلاحيات

### Android — `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

### iOS — `ios/App/App/Info.plist`
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Jouw Driver needs location access for the taximeter</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Jouw Driver needs background location for active trips</string>
```

---

## استكشاف الأخطاء

### خطأ: "out/ directory not found"
```bash
# تأكد من وجود next.config.ts مع output: 'export'
# أو استخدم server mode (الافتراضي في هذا المشروع)
npx cap sync
```

### خطأ: فشل بناء Android
```bash
# تأكد من ضبط ANDROID_HOME
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# تنظيف وإعادة البناء
cd android && ./gradlew clean && ./gradlew assembleDebug
```

### خطأ: API لا تعمل في التطبيق
- تأكد أن `server.url` في `capacitor.config.ts` يشير لسيرفرك الفعلي
- تأكد أن السيرفر يعمل ومتاح من الإنترنت
- تحقق من إعدادات CORS في Next.js

### خطأ: iOS signing issues
```bash
# في Xcode: Preferences > Accounts > أضف Apple ID
# ثم: Signing & Capabilities > Team > اختر حسابك
```

---

## ملاحظات مهمة

1. **Server Mode**: التطبيق يتصل بسيرفرك المنشور — جميع API routes تعمل طبيعياً
2. **المصادقة**: الكوكيز تعمل بشكل طبيعي عند الاتصال بالسيرفر
3. **الموقع الجغرافي**: يعمل بشكل أصلي على كلا المنصتين عبر Capacitor plugin
4. **الإشعارات**: تحتاج إعداد Firebase (Android) وAPNs (iOS) للإشعارات الفعلية
5. **التحديثات**: أي تحديث على السيرفر يظهر فوراً في التطبيق بدون نشر إصدار جديد

---

## قائمة التحقق قبل النشر

- [ ] سيرفر Next.js منشور ويعمل
- [ ] `capacitor.config.ts` يحتوي على الرابط الصحيح
- [ ] Capacitor مثبت (`pnpm add @capacitor/core @capacitor/cli`)
- [ ] المنصات مضافة (`npx cap add android` / `npx cap add ios`)
- [ ] الأيقونات موضوعة في المسارات الصحيحة
- [ ] APK/AAB موقَّع بـ keystore
- [ ] حساب Google Play / Apple Developer نشط
- [ ] معلومات التطبيق مكتملة في المتجر
- [ ] لقطات الشاشة مرفوعة
- [ ] الصلاحيات مضبوطة في AndroidManifest.xml / Info.plist
