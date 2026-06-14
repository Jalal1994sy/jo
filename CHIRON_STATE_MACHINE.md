
# Chiron State Machine - حل مشكلة CH1210

## 📋 نظرة عامة

تم تطبيق State Machine لكل رحلة لضمان عدم حدوث خطأ CH1210 (Message order violation) عند المزامنة مع Chiron API.

## 🔄 حالات الرحلة (Trip States)

```
CREATED
  ↓
START_SENT
  ↓ (HTTP 2xx من Chiron)
START_ACCEPTED
  ↓
ARRIVAL_SENT
  ↓ (HTTP 2xx من Chiron)
COMPLETED
```

## ✅ القواعد الذهبية

### 1. لا ترسل ARRIVAL قبل START_ACCEPTED
```typescript
if (trip.chiron_sync_state !== 'START_ACCEPTED') {
  throw new Error('CH1210 Prevention: Cannot send ARRIVAL before START is accepted');
}
```

### 2. لا ترسل START مرتين
```typescript
if (trip.chiron_sync_state === 'START_SENT' || trip.chiron_sync_state === 'START_ACCEPTED') {
  throw new Error('CH1210 Prevention: START already sent for this trip');
}
```

### 3. لا ترسل ARRIVAL مرتين
```typescript
if (trip.chiron_sync_state === 'ARRIVAL_SENT' || trip.chiron_sync_state === 'COMPLETED') {
  throw new Error('CH1210 Prevention: ARRIVAL already sent for this trip');
}
```

### 4. تحقق من HTTP 2xx قبل الانتقال للحالة التالية
```typescript
if (response.httpStatus >= 200 && response.httpStatus < 300) {
  // ✅ نجح - انتقل للحالة التالية
} else {
  // ❌ فشل - ارجع للحالة السابقة
}
```

## 🛠️ الدوال الجديدة

### 1. `sendTripStart(tripId, companyId, tripData)`
- ترسل رسالة START فقط
- تحدث الحالة من `CREATED` إلى `START_SENT`
- عند النجاح: تحدث إلى `START_ACCEPTED` وتحفظ `start_accepted_at`
- عند الفشل: ترجع إلى `CREATED`

### 2. `sendTripArrival(tripId, companyId, tripData)`
- ترسل رسالة ARRIVAL فقط
- **تتحقق أولاً** من أن الحالة = `START_ACCEPTED`
- تحدث الحالة من `START_ACCEPTED` إلى `ARRIVAL_SENT`
- عند النجاح: تحدث إلى `COMPLETED`
- عند الفشل: ترجع إلى `START_ACCEPTED`

### 3. `sendTrip(companyId, tripData)` (محدثة)
- تستدعي `sendTripStart()` أولاً
- تنتظر قبول START
- ثم تستدعي `sendTripArrival()`
- تضمن التسلسل الصحيح تلقائياً

## 📊 حقول قاعدة البيانات الجديدة

تم استخدام الحقول الموجودة في جدول `trips`:

| الحقل | النوع | الوصف |
|------|------|-------|
| `chiron_sync_state` | varchar(20) | الحالة الحالية للمزامنة |
| `start_sync_response` | jsonb | استجابة Chiron لرسالة START |
| `arrival_sync_response` | jsonb | استجابة Chiron لرسالة ARRIVAL |
| `start_accepted_at` | timestamp | تاريخ قبول START من Chiron |
| `arrival_sent_at` | timestamp | تاريخ إرسال ARRIVAL |

## 🧪 اختبار القبول (Acceptance Test)

تم تحديث `runAcceptanceTest()` لاستخدام State Machine:

```typescript
// ✅ إرسال رحلة واحدة في كل مرة
for (let i = 0; i < 5; i++) {
  await ChironService.sendTrip(companyId, tripData);
  // ينتظر قبول START قبل ARRIVAL تلقائياً
}

// ❌ لا batch ولا parallel
```

## 📝 مثال على التسلسل الصحيح

```typescript
// إنشاء رحلة
const trip = await tripsCrud.create({
  chiron_sync_state: 'CREATED',
  // ... بيانات أخرى
});

// الخطوة 1: إرسال START
await ChironService.sendTripStart(trip.id, companyId, {
  driver_id, vehicle_id, start_time, start_lat, start_lon, ritnummer
});
// الحالة الآن: START_ACCEPTED ✅

// الخطوة 2: إرسال ARRIVAL (بعد قبول START)
await ChironService.sendTripArrival(trip.id, companyId, {
  driver_id, vehicle_id, start_time, end_time,
  start_lat, start_lon, end_lat, end_lon,
  distance_km, price, ritnummer
});
// الحالة الآن: COMPLETED ✅
```

## ⚠️ معالجة الأخطاء

### إذا فشل START:
```
CREATED → START_SENT → (فشل) → CREATED
```
- يمكن إعادة المحاولة لاحقاً

### إذا فشل ARRIVAL:
```
START_ACCEPTED → ARRIVAL_SENT → (فشل) → START_ACCEPTED
```
- يمكن إعادة إرسال ARRIVAL فقط (START مقبول بالفعل)

## 🔍 التحقق من الحالة

```typescript
// قبل إرسال ARRIVAL
const trip = await tripsCrud.findById(tripId);

if (trip.chiron_sync_state !== 'START_ACCEPTED') {
  throw new Error('Cannot send ARRIVAL: START not accepted yet');
}

if (!trip.start_accepted_at) {
  throw new Error('START acceptance timestamp is missing');
}
```

## 📌 ملاحظات مهمة

1. **لا تعتمد على الوقت** - استخدم `chiron_sync_state` و `start_accepted_at`
2. **تحقق من HTTP Status** - فقط 2xx يعني نجاح
3. **احفظ الاستجابات** - `start_sync_response` و `arrival_sync_response` للتدقيق
4. **رحلة واحدة في كل مرة** - لا batch ولا parallel في الاختبار البلدي

## ✅ الخلاصة

- ✅ تم حل مشكلة CH1210 بالكامل
- ✅ State Machine يضمن الترتيب الصحيح
- ✅ لا يمكن إرسال ARRIVAL قبل قبول START
- ✅ لا يمكن إرسال رسالة مرتين
- ✅ معالجة أخطاء شاملة مع إمكانية إعادة المحاولة
