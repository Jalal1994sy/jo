
# التوثيق الكامل للمشروع الحالي من البداية إلى النهاية

## 1. مقدمة عامة

هذا المشروع هو منصة تشغيل وإدارة لقطاع التاكسي، مبنية على `Next.js` باستخدام `App Router` في الواجهة والخادم، وتعتمد على `PostgreSQL` عبر `PostgREST` في طبقة البيانات.

المنصة ليست مجرد لوحة تحكم واحدة، بل هي نظام متعدد الأدوار يغطي عدة مسارات تشغيلية:

- إدارة مركزية بواسطة `admin`
- إدارة شركات بواسطة `company`
- إدارة موزعين بواسطة `distributor`
- بوابة سائق تشغيلية بواسطة `driver`
- تكامل حكومي وتقني مع `Chiron API`
- نظام عقود وفواتير
- نظام رسائل وإشعارات
- نظام امتثال وخصوصية `GDPR`

---

## 2. الهدف التجاري والوظيفي للنظام

الهدف من المشروع هو تقديم منصة موحدة لإدارة دورة العمل الكاملة لقطاع التاكسي، وتشمل:

1. تسجيل الشركات والسائقين والمركبات
2. تشغيل الرحلات داخل النظام
3. دعم رحلات خارجية من منصات مثل:
   - `UBER`
   - `BOLT`
   - `HEETCH`
4. إرسال بيانات الرحلات إلى `Chiron`
5. إصدار الفواتير
6. إدارة الاشتراكات والعقود
7. إدارة الرسائل والإشعارات
8. تطبيق ضوابط الخصوصية والامتثال

---

## 3. البنية التقنية العامة

### 3.1 الواجهة الأمامية
- `Next.js 15`
- `React 19`
- `TypeScript`
- `Tailwind CSS v4`
- `shadcn/ui`
- `lucide-react`
- `framer-motion`

### 3.2 الخلفية
- `Next.js route handlers`
- جميع `API routes` داخل:
  - `src/app/next_api/**`

### 3.3 قاعدة البيانات
- `PostgreSQL`
- الوصول عبر `@supabase/postgrest-js`
- عميل قاعدة البيانات موجود في:
  - `src/lib/postgrest.ts`

### 3.4 المصادقة
- JWT عبر:
  - `src/lib/auth.ts`
- `AuthProvider` موجود في:
  - `src/components/auth/AuthProvider.tsx`

### 3.5 السمات واللغة
- `ThemeProvider`
- `LanguageProvider`
- دعم `dark/light mode`
- دعم لغات متعددة على مستوى بوابة السائق وبعض الواجهات

---

## 4. بنية المشروع

## 4.1 ملفات الجذر المهمة

- `README.md`
- `CHIRON_FIXES_DOCUMENTATION.md`
- `CHIRON_STATE_MACHINE.md`
- `DEPLOYMENT_GUIDE.md`
- `DISTRIBUTOR_LOGIN_GUIDE.md`
- `DRIVER_PORTAL_USER_GUIDE.md`
- `database-migration.sql`
- `database-table-rewrite.sql`

## 4.2 مجلد التطبيق
- `src/app/**`

هذا المج��د يحتوي على:
- الصفحات
- `layout.tsx`
- الملفات الخاصة بالخطأ
- `API routes`

## 4.3 مجلد المكونات
- `src/components/**`

يحتوي على:
- مكونات الواجهة
- مكونات المصادقة
- مكونات الإدارة
- مكونات السائق
- مكونات الشركة
- مكونات الهبوط `landing`

## 4.4 مجلد المكتبات
- `src/lib/**`

يحتوي على:
- المصادقة
- `Chiron`
- `CRUD`
- أدوات `API`
- مولد PDF
- أدوات التحويل

---

## 5. نقطة الدخول العامة للتطبيق

## 5.1 `src/app/layout.tsx`

هذا الملف هو الغلاف الرئيسي لكل التطبيق، ويقوم بما يلي:

- استيراد `globals.css`
- تفعيل `ThemeProvider`
- تفعيل `AuthProvider`
- تفعيل `LanguageProvider`
- تشغيل `Toaster`
- تشغيل `GlobalClientEffects`
- تشغيل `CookieBanner`

### التسلسل الفعلي للتغليف

`ThemeProvider` → `AuthProvider` → `LanguageProvider` → `children`

هذا يعني أن:
- الثيم متاح في كل المشروع
- حالة المستخدم متاحة في كل المشروع
- اللغة متاحة في الأجزاء التي تعتمد على `LanguageContext`

## 5.2 `src/app/page.tsx`

الصفحة الرئيسية الحالية لا تحتوي منطق منفصل، بل تعرض:

- `src/components/landing/LandingPage`

وهذا يعني أن صفحة الهبوط هي الواجهة الرئيسية العامة للمشروع.

---

## 6. الأدوار داخل النظام

## 6.1 `admin`
أعلى مستوى صلاحية، ويستطيع:
- إدارة المستخدمين
- إدارة الشركات
- إدارة الموزعين
- مراجعة طلبات الموافقة
- مراجعة طلبات تسجيل السائقين
- إدارة الرسائل والإشعارات
- إدارة العقود
- إدارة `GDPR`
- إدارة تكامل `Chiron`

## 6.2 `driver`
السائق يستطيع:
- تسجيل الدخول عبر `driver-login`
- تشغيل الرحلات
- مشاهدة ملفه
- رؤية إشعاراته
- رؤية رسائله
- مراجعة ملخص رحلاته
- إصدار فواتير مرتبطة برحلاته حسب التدفق المتاح

## 6.3 `distributor`
الموزع وسيط تشغيلي يستطيع:
- إدارة شركاته
- إضافة شركات وسائقين ومركبات
- بعض التعديلات تمر عبر `approval_requests`
- لا يملك صلاحيات `admin`

## 6.4 `company` أو `manager`
يمثل الشركة أو مديرها، ويستطيع:
- الدخول إلى لوحة الشركة
- إدارة السائقين
- إدارة المركبات
- متابعة الكيان الخاص بالشركة

---

## 7. نظام المصادقة

## 7.1 الملفات الرئيسية
- `src/lib/auth.ts`
- `src/lib/api-client.ts`
- `src/lib/api-utils.ts`
- `src/components/auth/AuthProvider.tsx`
- `src/config/auth-config.ts`

## 7.2 كيف يعمل النظام

### في الخادم
- يتم توليد JWT عبر `generateToken`
- يتم التحقق عبر `verifyToken`
- يتم إنشاء `admin token` بواسطة:
  - `generateAdminUserToken`

### في الواجهة
- `AuthProvider` يجلب المستخدم الحالي عبر:
  - `/next_api/auth/user`
- عند نجاح الجلب، يتم التوجيه حسب `userType`

### قواعد التوجيه الحالية
- `distributor` → `/distributor/dashboard`
- `driver` → `/driver/taximeter`
- `manager` أو `company` أو `owner` → `/company/dashboard`
- غير ذلك → `/dashboard`

## 7.3 ملفات `auth` الجاهزة
- `src/app/login/page.tsx`
- `src/app/driver-login/page.tsx`
- `src/components/auth/LoginForm.tsx`
- `src/components/auth/RegisterForm.tsx`
- `src/components/auth/DriverRegisterForm.tsx`
- `src/components/auth/CompanyLoginForm.tsx`
- `src/components/auth/ResetPasswordForm.tsx`
- `src/components/auth/GoogleLoginButton.tsx`

---

## 8. اللغة والثيم

## 8.1 `ThemeProvider`
المشروع يدعم:
- `light`
- `dark`
- `system`

## 8.2 `LanguageContext`
الملف:
- `src/contexts/LanguageContext.tsx`

اللغات المدعومة:
- `fr`
- `nl`
- `ar`

### كيف تحفظ اللغة
- `localStorage`
- `cookie`
- وتنعكس على:
  - `document.documentElement.lang`
  - `document.documentElement.dir`

---

## 9. هيكل الصفحات والمسارات

## 9.1 صفحات عامة
- `/`
- `/login`
- `/driver-login`
- `/landing`
- `/faq`
- `/privacy-policy`
- `/sign-contract/[token]`
- `/invoice/[token]`
- `/invoices`
- `/trips`
- `/taximeter`

## 9.2 صفحات الإدارة
- `/admin/users`
- `/admin/companies`
- `/admin/distributors`
- `/admin/drivers`
- `/admin/vehicles`
- `/admin/trips`
- `/admin/messages`
- `/admin/notifications`
- `/admin/approval-requests`
- `/admin/chiron-sync`
- `/admin/gdpr`
- `/admin/ad-slots`
- `/admin/test-trips`

## 9.3 صفحات الشركة
- `/company/dashboard`

## 9.4 صفحات الموزع
- `/distributor/dashboard`

## 9.5 صفحات السائق
- `/driver/profile`
- `/driver/taximeter`
- `/driver/trips`
- `/driver/summary`
- `/driver/messages`
- `/driver/notifications`
- `/driver/test`

---

## 10. أهم مكونات الواجهة

## 10.1 مكونات عامة
- `src/components/ThemeToggle.tsx`
- `src/components/GlobalClientEffects.tsx`
- `src/components/PWAInstallPrompt.tsx`
- `src/components/DriverSplashScreen.tsx`

## 10.2 مكونات الهبوط
- `src/components/landing/LandingPage.tsx`
- `src/components/landing/LandingNav.tsx`
- `src/components/landing/HomepageAdSlotSection.tsx`
- `src/components/landing/DriverGuideSection.tsx`

## 10.3 مكونات الشركة
- `src/components/company/CompanyDashboard.tsx`
- `src/components/company/DriversTab.tsx`
- `src/components/company/VehiclesTab.tsx`

## 10.4 مكونات السائق
- `src/components/driver/DriverDashboard.tsx`
- `src/components/driver/DriverProfilePage.tsx`

## 10.5 مكونات الإدارة
- `src/components/admin/CompaniesPageClient.tsx`
- `src/components/admin/ApprovalRequestsPageClient.tsx`
- `src/components/admin/AdminMessagesPageClient.tsx`
- `src/components/admin/AdminNotificationsPageClient.tsx`
- `src/components/admin/ChironSyncPageClient.tsx`
- `src/components/admin/GdprAdminClient.tsx`

---

## 11. طبقة `API`

كل الوصول من الواجهة إلى البيانات يمر عبر:
- `src/lib/api-client.ts`

وهذا العميل يرسل الطلبات إلى:
- `/next_api/**`

### الصيغ الأساسية
- `api.get`
- `api.post`
- `api.put`
- `api.delete`

### التعامل مع المصادقة
العميل يدعم:
- إعادة المحاولة عند انتهاء `token`
- `refresh token`
- إعادة التوجيه إلى صفحة الدخول عند الحاجة

---

## 12. طبقة الخادم والـ middleware الداخلي

## 12.1 `requestMiddleware`
الموجود في:
- `src/lib/api-utils.ts`

وظيفته:
- تمرير الطلبات
- التحقق من `token` عند الحاجة
- إرفاق:
  - `context.token`
  - `context.payload`

## 12.2 `CrudOperations`
الموجود في:
- `src/lib/crud-operations.ts`

هو الغلاف القياسي للوصول إلى الجداول عبر:
- `.findMany`
- `.findById`
- `.create`
- `.update`
- `.delete`

### مبدأ العمل
كل `API route` غالباً ينشئ كائناً من:
- `new CrudOperations("table_name", token)`

---

## 13. قاعدة البيانات: نظرة تنظيمية

قاعدة البيانات تحتوي `71` جدولاً.  
يمكن تقسيمها إلى مجالات وظيفية كما يلي.

---

## 14. مجال المستخدمين والمصادقة

## 14.1 `users`
الجدول المركزي للحسابات.

أهم الأعمدة:
- `id`
- `email`
- `password`
- `role`
- `user_type`
- `auth_provider`
- `google_id`
- `avatar_url`
- `display_name`

أنواع `user_type`:
- `admin`
- `driver`
- `manager`
- `distributor`

## 14.2 جداول مرتبطة بالمصادقة
- `sessions`
- `refresh_tokens`
- `user_passcode`
- `user_oauth_providers`
- `refresh_tokens`

### الاستخدام
- إدارة الجلسات
- إعادة التحديث
- رموز التحقق
- الربط مع مزودي OAuth

---

## 15. مجال الشركات

## 15.1 `companies`
أهم كيان تشغيلي في النظام.

أهم الأعمدة:
- `name`
- `vat_number`
- `kbo_number`
- `address`
- `email`
- `phone`
- `chiron_mode`
- `chiron_test_client_id`
- `chiron_test_client_secret`
- `chiron_prod_client_id`
- `chiron_prod_client_secret`
- `subscription_status`
- `password_hash`

### ملاحظات مهمة
هذا الجدول لا يحتوي فقط بيانات تعريف الشركة، بل يحتوي أيضاً:
- إعدادات التسعير
- إعدادات `Chiron`
- حالة الاشتراك
- بيانات البنك
- بيانات التجميد والتعليق

## 15.2 `company_users`
يربط حسابات المستخدمين بالشركات.

---

## 16. مجال الموزعين

## 16.1 `distributors`
بيانات الموزعين.

أهم الأعمدة:
- `user_id`
- `full_name`
- `email`
- `phone`
- `commission_percentage`
- `is_active`
- `password_hash`

## 16.2 `distributor_companies`
جدول الربط بين الموزعين والشركات.

---

## 17. مجال السائقين

## 17.1 `drivers`
الجدول الأساسي للسائقين.

أهم الأعمدة:
- `user_id`
- `company_id`
- `full_name`
- `phone`
- `driver_license`
- `bestuurderspas_number`
- `status`
- `registration_status`
- `current_trip_id`
- `current_vehicle_id`
- `assigned_vehicle_id`
- `preferred_language`

## 17.2 `driver_profiles`
ملف شخصي إضافي للسائق.

## 17.3 `driver_credentials`
تسجيل دخول بوابة السائق برقم الهاتف وكلمة المرور.

## 17.4 `driver_registration_requests`
طلبات تسجيل السائقين.

## 17.5 `driver_registration_steps`
تتبع التقدم في نموذج التسجيل متعدد الخطوات.

---

## 18. مجال المركبات

## 18.1 `vehicles`
أهم الأعمدة:
- `company_id`
- `brand`
- `model`
- `plate_number`
- `vin`
- `chiron_vehicle_id`
- `documents`
- `status`
- `created_by_distributor_id`

---

## 19. مجال الرحلات

## 19.1 `trips`
أهم جدول تشغيلي في النظام.

أهم الأعمدة:
- `user_id`
- `company_id`
- `driver_id`
- `vehicle_id`
- `start_time`
- `end_time`
- `start_lat`
- `start_lon`
- `end_lat`
- `end_lon`
- `start_address`
- `end_address`
- `distance_km`
- `duration_minutes`
- `price`
- `status`
- `ritnummer`
- `trip_uuid`
- `trip_hash`
- `ride_type`
- `external_source`
- `external_ride_number`
- `payment_method`
- `chiron_sync_state`
- `start_sync_response`
- `arrival_sync_response`
- `start_accepted_at`
- `start_message_id`
- `arrival_allowed`
- `locked_after_completion`
- `record_retention_until`

### دلالات مهمة
هذا الجدول يجمع:
- بيانات الرحلة الداخلية
- بيانات الرحلة الخارجية
- حالة التزام `Chiron`
- عناصر الأثر التدقيقي
- عناصر عدم القابلية للتعديل بعد الإغلاق

## 19.2 `trip_locations`
تتبع الموقع أثناء الرحلة.

## 19.3 `trip_state_transitions`
سجل انتقالات الحالة الخاصة بالرحلة.

## 19.4 `trip_summaries`
تقارير ملخصة على فترات زمنية.

---

## 20. مجال `Chiron`

## 20.1 `chiron_sync_log`
سجل محاولات الإرسال.

## 20.2 `chiron_api_config`
إعدادات `Chiron` لكل بيئة.

## 20.3 جداول مساعدة أخرى
- `chiron_message_log`
- `chiron_oauth_log`
- `chiron_tokens`
- `chiron_validation_log`
- `chiron_validation_rules`
- `chiron_sequence_rules`
- `chiron_coordinate_formatting_log`
- `chiron_error_codes`

### معنى ذلك
المشروع لا يرسل إلى `Chiron` فقط، بل يحتوي بنية تحليل وتشخيص ومراجعة متقدمة.

---

## 21. مجال الفواتير

## 21.1 `invoices`
جدول ضخم ويحتوي نوعين من المستندات:
- فواتير شركات
- فواتير رحلات
- وأحياناً مستندات `vervoerbewijs`

أهم الأعمدة:
- `invoice_number`
- `client_name`
- `items`
- `total_htva`
- `vat_rate`
- `total_tvac`
- `invoice_date`
- `due_date`
- `status`
- `invoice_type`
- `invoice_category`
- `payment_status`
- `issuer_company_id`
- `client_company_id`
- `trip_id`
- `trip_datetime`
- `vehicle_plate_number`
- `ritnummer`
- `document_type`
- `trip_uuid_snapshot`
- `chiron_submission_status_snapshot`

## 21.2 جداول مرتبطة بالفواتير
- `invoice_delivery_log`
- `invoice_edit_history`
- `invoice_share_links`
- `invoice_view_log`

---

## 22. مجال الرسائل والإشعارات

## 22.1 `internal_messages`
الرسائل الداخلية بين الإدارة والسائقين.

## 22.2 `message_replies`
ردود مرتبطة بالرسائل.

## 22.3 `message_recipients`
المستلمون المرتبطون بالرسائل.

## 22.4 `notifications`
إشعارات عامة أو موجهة.

## 22.5 `user_notifications`
إشعارات مرتبطة بالمستخدمين.

---

## 23. مجال الموافقات

## 23.1 `approval_requests`
طلبات الموافقة على:
- تعديل
- حذف
- تسجيل

## 23.2 جداول مرتبطة
- `approval_history`
- `approval_auto_rules`
- `approval_execution_log`
- `approval_statistics`

---

## 24. مجال العقود

## 24.1 `company_contracts`
عقود الاشتراك الخاصة بالشركات.

أهم الأعمدة:
- `contract_number`
- `contract_start_date`
- `contract_end_date`
- `monthly_fee`
- `annual_fee`
- `contract_status`
- `contract_html_template`
- `signature_token`
- `signed_at`
- `next_invoice_generation_date`

## 24.2 `platform_contracts`
عقود المنصات الخارجية مثل:
- `uber`
- `bolt`
- `heetch`

## 24.3 `contract_signatures`
توثيق التوقيعات.

---

## 25. مجال الإعلانات والمحتوى العام

## 25.1 `homepage_ad_slots`
إدارة محتوى HTML داخل الصفحة الرئيسية.

---

## 26. مجال الخصوصية والامتثال `GDPR`

## 26.1 `privacy_policy_versions`
نسخ سياسة الخصوصية.

## 26.2 `user_consents`
سجل موافقات المستخدمين.

## 26.3 `cookie_categories`
تصنيفات ملفات الارتباط.

## 26.4 `data_subject_requests`
طلبات أصحاب البيانات.

## 26.5 `personal_data_breach_incidents`
حوادث اختراق البيانات الشخصية.

## 26.6 `data_transfer_registry`
سجل نقل البيانات خارجياً.

---

## 27. مجال المصروفات

## 27.1 `expenses`
لتتبع مصروفات الشركة.

---

## 28. أهم تدفقات العمل داخل النظام

## 28.1 تدفق تسجيل الدخول العام

### المسار
- الواجهة ترسل ������ `/next_api/auth/login`
- ���� `AuthProvider` ��ج���� ����������������
- ثم يعيد التوجيه حسب نوع المستخدم

### الملفات
- `src/components/auth/AuthProvider.tsx`
- `src/app/next_api/auth/login/route.ts`
- `src/app/next_api/auth/user/route.ts`

---

## 28.2 تدفق تسجيل السائق

### الواجهة
- `src/components/auth/DriverRegisterForm.tsx`

### الخطوات العامة
1. ���������� �������� ������������
2. ���������� ������������ ������������
3. �������������� ����������ت ������������
4. �������������� ������������ ������������
5. ���������� بيانات `Chiron` الاختيارية
6. إدخال المركبة
7. إدخال بيانات الرخص والوثائق
8. إنشاء طلب تسجيل

### الخادم
- `src/app/next_api/driver-registration/route.ts`

### ما الذي يتم إنشاؤه
- شركة أو ربط بشركة
- سجل في `drivers`
- سجل في `vehicles`
- ربط المركبة بالسائق
- سجل في `driver_credentials`
- سجل في `driver_registration_requests`

### الموافقة
- `src/app/next_api/driver-registration/approve/route.ts`

عند الموافقة:
- `registration_status` يصبح `approved`
- `driver_credentials.is_active` يصبح `true`
- يتم ت�������� ������������

---

## 28.3 �������� ���������� ������������

### ��������������
����������:
- `src/app/next_api/trips/start/route.ts`

������:
- ج���� ����������ق
- ���������� ��������������
- ���������� `trip_uuid`
- ������ ���������� ����������ة

### ��������������
����������:
- `src/app/next_api/trips/end/route.ts`

������:
- �������� ������������ ������������
- ���������� `ritnummer`
- ������ ��ل��������
- ���������� `START` ������ `Chiron`
- ���� ���������� `ARRIVAL`
- ���� ق��ل ������������ ع���� ��ل��������

---

## 28.4 �������� `Chiron`

### ���������� ��������������
- `src/lib/chiron-service.ts`

### �������� ��������������������
- ������ �������������� ������ر����
- ������������ ال�������� `TEST` ���� `PRODUCTION`
- ������������ ������ `access token`
- �������� ������������ل
- ������ا�� `vertrek`
- ���������� `aankomst`
- ������������ ���� ������ن������
- ������ ��������������
- ������ ���������� ��������������

### �������������� �������� ��������
�������������� ��������:
- `formatCoordinate`
- `formatDistance`
- `formatPrice`
- `validateTripData`
- `validateRitnummer`
- `validateKboNumber`

### ������������ ���������������� ������������
- `CREATED`
- `START_SENT`
- `START_ACCEPTED`
- `ARRIVAL_SENT`
- `COMPLETED`

�������� �������� ���������� ����:
- `CHIRON_STATE_MACHINE.md`

---

## 28.5 �������� ����������������

### ����������
- `src/app/next_api/invoices/route.ts`

### ��������������
- ���������� ������������
- ������ ����������������
- ���������� ����������������
- ������ ����������������
- ���������� ���������� ������������������ ������������

### ��������������
������������ �������� ����ن:
- `invoice_category = company`
- `invoice_category = trip`

��������������:
- `PDFGenerator.generateStructuredReference`

---

## 28.6 ت������ ��������������

### ����������
- `src/app/next_api/messages/route.ts`

### ��������������
- ������ ��������������
- ���������� ������ل��
- ���������� ���������� ������������������
- ���������� �������� ��������������
- ������ �������������� �������������� ��������������������

---

## 28.7 �������� ������������������

### ����������
- `src/app/next_api/notifications/route.ts`

### ��������������
- ������ ������������������ ������������
- ���������� ����������
- ���������� ����������
- ������ ����������

---

## 28.8 تد���� ���������� ��������������

### ����������
- `src/app/next_api/companies/route.ts`

### �������� ������ ����������

#### ������ ������ `admin`
- ���������� ����������
- ���������� ����������
- ������ ����������

#### ������ ������ `distributor`
- �������� ��������������
- �������������� ������������ ���� ������������ ������ `approval_requests`

---

## 28.9 �������� ���������� ����������������

### ����������
- `src/app/next_api/distributors/route.ts`

### ��������������
- ���������� �������� ������������ ���� ������ `distributor`
- ���������� ������ ��������
- ���������� ��������
- ������ �������� ���� ������ ��������������

---

## 28.10 �������� ������������

### ����������
- `src/app/next_api/contracts/route.ts`

### ��������������
- ���������� ������
- ���������� HTML ����������
- ���������� ����������
- ������ ���������� ��������������
- ���������� �������� ������������

---

## 28.11 �������� `GDPR`

### ���������� API ����������������
- `src/app/next_api/gdpr/privacy-policy/route.ts`
- `src/app/next_api/gdpr/admin/breach-incidents/route.ts`
- `src/app/next_api/gdpr/admin/data-subject-requests/route.ts`
- `src/app/next_api/gdpr/admin/data-transfers/route.ts`

### �������������� ����������������
- `src/components/admin/GdprAdminClient.tsx`

### ���� ������ ������������
- ���������� ������������
- ���������� ����������������
- ���������� ������ ����������������
- ������������ ����������������

---

## 29. �������� ������������

### ����������
- `src/components/company/CompanyDashboard.tsx`

### ���� ����������
- �������������� ������������
- ������ ����������������
- ������ ����������������
- ا�������������� ������������
- ��������������:
  - `Drivers`
  - `Vehicles`

### �������� ����������������
- `/next_api/company-portal`

---

## 30. �������� ������������

### ����������
- `src/components/driver/DriverDashboard.tsx`

### ���� ��ع������
- �������� ��������������
- ������������������ ��������������
- معلوم���� ������������
- �������������� الم��������
- �������� ��������ا�� ����������ة
- ���������� ������������

### �������� ��ه��
������ ���� �������� ������������ ���������������� ����ا������ ������������ �������� ���� ������ ���� �������� ���������� ������.

---

## 31. ������������ ���������������� �������� landing

��������ح�� ���������������� ������������ ����:
- `src/components/landing/LandingPage.tsx`

����������:
- ��������ف ��������������
- ������������ ��������������
- �������������� ������������������
- ���������� �������������� ��������������

---

## 32. �������������� ���� `PWA`

�������������� ���������� ���������� �������� `PWA` ������:
- `public/manifest.json`
- `public/sw.js`
- `src/components/PWAInstallPrompt.tsx`

������ ���� `layout.tsx` ���������� ��������������:
- `appleWebApp`
- `manifest`
- `icons`

---

## 33. �������������� ���� ا������������ ����������������

م�� �������� ������������ ���������������� ������������ �������� �������������������� ������ �������������� �������� ������������ �������������� ���������� ������ ���� ��������:
- `viewport` ����������
- `overscroll-none`
- ������������ ������:
  - `MobileStatusBar`
  - `DriverSplashScreen`
- ���������� ������������ ���������� ���������� ���������� �������� ������ ������������

---

## 34. �������������� ������������������ ���������������� ������������

## 34.1 `CHIRON_FIXES_DOCUMENTATION.md`
��������:
- �������������� ���������� ��������������������
- ���������� ������س������ ������������
- ���� `CH1205`
- ���� `CH1208`
- ���� `CH1210`

## 34.2 `CHIRON_STATE_MACHINE.md`
�������� �������� ���������� ������������ ��������.

## 34.3 `DEPLOYMENT_GUIDE.md`
�������� ���������� ������ �������� ������.

## 34.4 `DISTRIBUTOR_LOGIN_GUIDE.md`
�������� �������� �������� ���������������� ��������������������.

## 34.5 `DRIVER_PORTAL_USER_GUIDE.md`
�������� �������������� ���������� ������������.

---

## 35. ������������ �������������������� ������������

���� خ������ �������������� ������������������ �������������� ���������� ������ �������������� ������:

- `NEXT_PUBLIC_ENABLE_AUTH`
- `JWT_SECRET`
- `POSTGREST_URL`
- `POSTGREST_SCHEMA`
- `POSTGREST_API_KEY`
- `SCHEMA_ADMIN_USER`
- `RESEND_KEY`
- `NEXT_PUBLIC_ZOER_HOST`

### ��ل����������
- ���������������� ���������� ������ `JWT_SECRET`
- ���������� ���������������� ���������� ������ �������������� `PostgREST`
- ������������ ق�� ي���� ������ `Resend`
- `Auth` �������� ������������ ���� ������������ ������:
  - `NEXT_PUBLIC_ENABLE_AUTH`

---

## 36. �������� ���������� �������������� ���� ��������������

1. �������� ���������� ������ �������������� �������� `API`
2. ������ ������ ��������������
3. ���������� ���������� ������������ ������������ ��������
4. ������ `Chiron` ����������
5. �������� �������������� ��������������
6. ������ `GDPR`
7. ������ `PWA`
8. ������ ������������ ������������ ������������
9. �������� `approval workflow`
10. ���������� ������������ ���������� �������� �������������� ��������������

---

## 37. �������� �������������� ����������������

## 37.1 ���������� ��������������
��ا������ ���������������� ������������ ������������ ���������� ������������ ���� �������������� ������ ���������������� �������������� ������ ����������.

## 37.2 ���������� `Chiron`
���� ���������� ���� ���������� �������������� ���� ������������ ���������������� ���������������������� ������������������ ���� �������� ع����:
- ����������س��
- ��������������
- ����������������
- �������� ��������������

## 37.3 �������� ��������������
���� ���������� ���� `users` ���� `drivers` ���� `companies` ���� ���������� ������:
- ��س������ ������������
- ��������������
- �������������� ��������ج������
- ���������� ���� ���������� ��������

## 37.4 ���������� ���������� ���������� ��������������
���������� ������ ���������� ������������ ������ ���������������� ������ �������� ������:

���������� ���������� �������������� ������������ �������� ������������ �������� ������ ������ ������������ �������� ���� �������� إ����:
- ���������� ������������
- ���������� `index`
- ���������� `constraint`
- ���������� ���������� ���������������� ����������������
- ������ `API routes`
- ������ ������������ ���������� ������ ���������� ���������� ����������

---

## 38. �������������� �������������� ������ ���������� �������� ���� ���������� ��������������

������ ������ ���������� ���� ���������� �������� �������������� �������� ���������� ���� �������� ���������������� ������������������ ����:

### ��������و���� ������������
1. �������������� `DDL` ������������ ������ �������� ����������
2. �������� �������� �������� ��������
3. ������ ���������������� ���� ������������ إ���� ������������
4. ������������ ����:
   - ������ ��������������
   - ���������� ��������������
   - `indexes`
   - `unique constraints`
   - `check constraints`
5. ���������� ����م���� ��������ا���� ������ ������������
6. ���������� ���� �������� ���������� ���������� ������ ���������� ���������� ������ ������

### �������������� ������������ ������������
- `users`
- `drivers`
- `companies`
- `vehicles`
- `trips`
- `trip_locations`
- `trip_state_transitions`
- `invoices`
- `driver_registration_requests`
- `approval_requests`
- `notifications`
- `internal_messages`

### ����������
������ �������������� �������������� ������������ ����:
- ����������
- `API routes`
- ���������� الد����ل
- ��������������
- `Chiron`
- ������������ل
- ���������� ������������

---

## 39. �������������� ������������ ��������ا������ ������������

## 39.1 ���������� ������������ ������م����������
- `users`
- `sessions`
- `refresh_tokens`
- `user_passcode`

## 39.2 ��������ئ��
- `drivers`
- `driver_profiles`
- `driver_credentials`
- `driver_registration_requests`
- `driver_registration_steps`

## 39.3 ������������
- `companies`
- `company_users`
- `company_contracts`

## 39.4 ������������
- `distributors`
- `distributor_companies`

## 39.5 ��������������
- `trips`
- `trip_locations`
- `trip_state_transitions`
- `trip_summaries`

## 39.6 ����������������
- `invoices`
- `invoice_edit_history`
- `invoice_share_links`
- `invoice_delivery_log`
- `invoice_view_log`

## 39.7 �������������� ��������������������
- `internal_messages`
- `message_replies`
- `message_recipients`
- `notifications`
- `user_notifications`

## 39.8 الموافقات
- `approval_requests`
- `approval_history`

## 39.9 الامتثال
- `privacy_policy_versions`
- `user_consents`
- `cookie_categories`
- `data_subject_requests`
- `personal_data_breach_incidents`
- `data_transfer_registry`

---

## 40. ملخص أهم ملفات المنطق التي يجب فهمها قبل أي تعديل كبير

إذا أردت لاحقاً إصلاح المشروع أو نقله أو إعادة كتابة أجزاء منه، فأهم الملفات التي يجب مراجعتها أولاً هي:

### البنية الأساسية
- `src/app/layout.tsx`
- `src/app/page.tsx`

### المصادقة
- `src/lib/auth.ts`
- `src/lib/api-client.ts`
- `src/lib/api-utils.ts`
- `src/components/auth/AuthProvider.tsx`

### قاعدة البيانات
- `src/lib/crud-operations.ts`
- `src/lib/postgrest.ts`
- `src/lib/create-response.ts`

### السائق
- `src/components/auth/DriverRegisterForm.tsx`
- `src/app/next_api/driver-registration/route.ts`
- `src/app/next_api/driver-registration/approve/route.ts`

### الرحلات و`Chiron`
- `src/app/next_api/trips/start/route.ts`
- `src/app/next_api/trips/end/route.ts`
- `src/lib/chiron-service.ts`

### الفواتير
- `src/app/next_api/invoices/route.ts`

### الرسائل والإشعارات
- `src/app/next_api/messages/route.ts`
- `src/app/next_api/notifications/route.ts`

### الشركات والموزعين
- `src/app/next_api/companies/route.ts`
- `src/app/next_api/distributors/route.ts`

### الامتثال
- `src/components/admin/GdprAdminClient.tsx`

---

## 41. كيف تقرأ المشروع بسرعة إذا أردت استكماله لاحقاً

### الترتيب الأفضل للفهم
1. `src/app/layout.tsx`
2. `src/components/auth/AuthProvider.tsx`
3. `src/lib/api-client.ts`
4. `src/lib/crud-operations.ts`
5. `src/lib/chiron-service.ts`
6. `src/app/next_api/driver-registration/route.ts`
7. `src/app/next_api/trips/end/route.ts`
8. `src/app/next_api/invoices/route.ts`
9. `src/app/next_api/messages/route.ts`
10. `src/components/company/CompanyDashboard.tsx`
11. `src/components/driver/DriverDashboard.tsx`
12. `src/components/admin/GdprAdminClient.tsx`

---

## 42. الخلاصة النهائية

هذا المشروع هو نظام تشغيل حقيقي متعدد المجالات، وليس مجرد لوحة تقارير.  
المكونات الأساسية فيه هي:

- مصادقة متعددة الأدوار
- إدارة شركات وموزعين وسائقين
- إدارة مركبات
- إدارة رحلات
- تكامل `Chiron`
- إصدار فواتير
- رسائل وإشعارات
- عقود
- امتثال `GDPR`

### أهم ما يميزه
- البنية غنية
- قاعدة البيانات واسعة
- تدفقات التشغيل مترابطة
- منطق `Chiron` حساس جداً
- أي إعادة بناء للجداول يجب أن تتم بخطة ترحيل دقيقة بدون تعديل عشوائي

### التوصية العملية
إذا كانت المشكلة الأساسية عندك ما تزال في الجداول داخل المنصة، فالأولوية ليست حذف الجداول أو إعادة إنشائها مباشرة، بل:
1. توثيق البنية الحالية
2. تحديد الجداول المتأثرة فقط
3. استخراج `DDL`
4 الاستخدام البر. مقارنةمجي الفعلي
5. تنفيذ `safe table rewrite` تدريجي

---

## 43. ملحق سريع: أهم الجداول حسب الأولوية

### أولوية قصوى
- `users`
- `companies`
- `drivers`
- `vehicles`
- `trips`
- `invoices`

### أولوية عالية
- `driver_registration_requests`
- `approval_requests`
- `internal_messages`
- `notifications`
- `company_contracts`
- `platform_contracts`

### أولوية امتثال وتدقيق
- `trip_state_transitions`
- `chiron_sync_log`
- `privacy_policy_versions`
- `user_consents`
- `data_subject_requests`
- `personal_data_breach_incidents`

---

## 44. الملفات التي تم الاعتماد عليها في هذا التوثيق

تم بناء هذا التوثيق بالاعتماد على مراجعة مباشرة للملفات التالية:

- `README.md`
- `CHIRON_FIXES_DOCUMENTATION.md`
- `CHIRON_STATE_MACHINE.md`
- `DEPLOYMENT_GUIDE.md`
- `DISTRIBUTOR_LOGIN_GUIDE.md`
- `DRIVER_PORTAL_USER_GUIDE.md`
- `src/app/layout.tsx`
- `src/app/page.tsx`
- `src/lib/auth.ts`
- `src/lib/chiron-service.ts`
- `src/lib/user-register.ts`
- `src/components/auth/AuthProvider.tsx`
- `src/components/auth/DriverRegisterForm.tsx`
- `src/components/company/CompanyDashboard.tsx`
- `src/components/driver/DriverDashboard.tsx`
- `src/components/admin/ChironSyncPageClient.tsx`
- `src/components/admin/GdprAdminClient.tsx`
- `src/app/next_api/driver-registration/route.ts`
- `src/app/next_api/driver-registration/approve/route.ts`
- `src/app/next_api/trips/start/route.ts`
- `src/app/next_api/trips/end/route.ts`
- `src/app/next_api/invoices/route.ts`
- `src/app/next_api/messages/route.ts`
- `src/app/next_api/notifications/route.ts`
- `src/app/next_api/companies/route.ts`
- `src/app/next_api/distributors/route.ts`
- `src/app/next_api/contracts/route.ts`
- `src/app/next_api/gdpr/privacy-policy/route.ts`
- `src/config/auth-config.ts`
- `src/contexts/LanguageContext.tsx`

وكذلك تم الاستناد إلى بنية الجداول الحالية في قاعدة البيانات.

