
# توثيق المشروع الحالي

هذا المشروع هو نظام إدارة وتشغيل تاكسي مبني باستخدام `Next.js App Router` و `PostgreSQL` مع تكامل متقدم مع `Chiron API`، ويدعم:

- إدارة المسؤول `admin`
- إدارة الشركات `company`
- إدارة الموزعين `distributor`
- بوابة السائق `driver portal`
- الرحلات والفواتير
- الرسائل والإشعارات
- العقود
- الامتثال `GDPR`
- اختبارات وتزامن `Chiron`

## ملفات التوثيق الأساسية

### التوثيق الشامل
- `CURRENT_PROJECT_FULL_DOCUMENTATION.md`

### توثيق متخصص
- `CHIRON_FIXES_DOCUMENTATION.md`
- `CHIRON_STATE_MACHINE.md`
- `DEPLOYMENT_GUIDE.md`
- `DISTRIBUTOR_LOGIN_GUIDE.md`
- `DRIVER_PORTAL_USER_GUIDE.md`

## ملخص سريع عن المشروع

### الواجهة
- `src/app/**`
- `src/components/**`

### API
- `src/app/next_api/**`

### المكتبات الأساسية
- `src/lib/auth.ts`
- `src/lib/chiron-service.ts`
- `src/lib/crud-operations.ts`
- `src/lib/api-client.ts`
- `src/lib/api-utils.ts`
- `src/lib/create-response.ts`

### مزودي الحالة العامة
- `src/components/auth/AuthProvider.tsx`
- `src/components/ThemeProvider.tsx`
- `src/contexts/LanguageContext.tsx`

## أهم المسارات

### صفحات عامة
- `src/app/page.tsx`
- `src/app/login/page.tsx`
- `src/app/driver-login/page.tsx`
- `src/app/landing/page.tsx`

### صفحات الإدارة
- `src/app/admin/**`

### صفحات الشركة
- `src/app/company/dashboard/page.tsx`

### صفحات الموزع
- `src/app/distributor/dashboard/page.tsx`

### صفحات السائق
- `src/app/driver/**`

## أهم الجداول

- `users`
- `companies`
- `distributors`
- `drivers`
- `driver_profiles`
- `vehicles`
- `trips`
- `trip_locations`
- `trip_state_transitions`
- `trip_summaries`
- `invoices`
- `internal_messages`
- `message_replies`
- `notifications`
- `approval_requests`
- `driver_registration_requests`
- `driver_registration_steps`
- `company_contracts`
- `platform_contracts`
- `chiron_sync_log`
- `privacy_policy_versions`
- `user_consents`
- `cookie_categories`
- `data_subject_requests`
- `personal_data_breach_incidents`
- `data_transfer_registry`
- `expenses`

## ملاحظات مهمة

- الصفحة الرئيسية الحالية تستخدم `src/components/landing/LandingPage`
- النظام يلف التطبيق بالكامل داخل `AuthProvider` و `ThemeProvider` و `LanguageProvider`
- كل الوصول إلى قاعدة البيانات يمر عبر `Next.js API routes`
- تكامل `Chiron` يعتمد على `state machine` واضح لتجنب أخطاء التسلسل
- هناك فصل واضح بين صلاحيات `admin` و `driver` و `company` و `distributor`

## ترتيب القراءة المقترح

1. `CURRENT_PROJECT_FULL_DOCUMENTATION.md`
2. `CHIRON_FIXES_DOCUMENTATION.md`
3. `CHIRON_STATE_MACHINE.md`
4. `DEPLOYMENT_GUIDE.md`
5. الأدلة الخاصة حسب الدور

