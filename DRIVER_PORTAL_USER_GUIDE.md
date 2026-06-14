
# Driver Portal User Guide
## دليل استخدام بوابة السائق
## Guide d'utilisation du Portail Chauffeur
## Handleiding Chauffeursportaal

Version: 1.0  
Applies to routes: `/driver-login`, `/driver/taximeter`, `/driver/trips`, `/driver/summary`, `/driver/messages`, `/driver/notifications`

---

## 1) Arabic (العربية)

### 1.1 نظرة عامة
هذا الدليل يشرح استخدام بوابة السائق خطوة بخطوة، من تسجيل الدخول حتى إنهاء الرحلة، إصدار الفاتورة، ومراجعة الإشعارات والرسائل.

### 1.2 متطلبات قبل البدء
- حساب سائق مفعل.
- رقم الهاتف وكلمة المرور الصحيحة.
- اتصال إنترنت مستقر.
- تفعيل GPS/Location في الهاتف عند استخدام صفحة العداد `/driver/taximeter`.
- يفضّل إضافة التطبيق للشاشة الرئيسية (PWA).

### 1.3 تسجيل الدخول
المسار: `/driver-login`

الخطوات:
1. افتح صفحة تسجيل الدخول.
2. أدخل رقم الهاتف في حقل `phone`.
3. أدخل كلمة المرور في حقل `password`.
4. اضغط زر تسجيل الدخول.
5. عند نجاح التحقق سيتم الانتقال تلقائياً إلى `/driver/taximeter`.

ملاحظات مهمة:
- إذا بقيت في نفس الصفحة، تأكد من صحة الهاتف/كلمة المرور وأن الحساب نوعه `driver`.
- تأكد أن المتصفح يسمح بحفظ Cookies.
- لا تضف مسافات قبل/بعد رقم الهاتف.

### 1.4 الصفحة الرئيسية للسائق (Layout)
المسارات داخل `/driver/*`:
- `taximeter`: إدارة الرحلة الحالية.
- `trips`: سجل الرحلات + الفواتير.
- `summary`: التقارير والإحصائيات.
- `messages`: الرسائل مع الإدارة.
- `notifications`: التنبيهات.
- `test`: صفحة اختبار داخلية.

من الأعلى:
- اسم السائق واسم الشركة.
- زر تبديل اللغة (NL / FR).
- زر `ThemeToggle`.
- زر `logout`.

### 1.5 بدء رحلة جديدة (Taximeter)
المسار: `/driver/taximeter`

#### اختيار نوع الرحلة
الخيارات:
- `INTERNAL` (تاكسي داخلي)
- `BOLT`
- `UBER`
- `HEETCH`

#### للرحلة الداخلية `INTERNAL`
1. أدخل عنوان البداية.
2. أدخل عنوان الوجهة.
3. أدخل اسم الراكب (اختياري).
4. اختر طريقة الدفع.
5. اضغط حساب السعر.
6. راجع السعر المقترح والمسافة والمدة.
7. اضغط بدء الرحلة.

#### للرحلات الخارجية
1. اختر المنصة (`BOLT` أو `UBER` أو `HEETCH`).
2. أدخل رقم الرحلة الخارجي (إن وجد).
3. أدخل بيانات الراكب.
4. اضغط بدء الرحلة.

### 1.6 أثناء الرحلة
- يعرض النظام حالة الرحلة النشطة.
- في `INTERNAL` يتم تتبع المسافة والمدة.
- يمكن فتح الملاحة عبر:
  - Waze
  - Google Maps

### 1.7 إنهاء الرحلة
1. اضغط إنهاء الرحلة.
2. أدخل السعر النهائي.
3. أكّد الإرسال.
4. إذا كان الإنترنت متاحاً يتم إرسال الرحلة فوراً.
5. إذا لا يوجد إنترنت، تحفظ الرحلة محلياً مؤقتاً.

### 1.8 إصدار الفاتورة
- بعد إنهاء الرحلة بنجاح، اختر `Generate Invoice`.
- يتم تنزيل ملف PDF تلقائياً.

### 1.9 صفحة الرحلات
المسار: `/driver/trips`

المميزات:
- فلترة الرحلات: الكل/مكتملة/قيد المعالجة/فاشلة.
- عرض تفاصيل كل رحلة.
- فتح المسار في Maps أو Waze.
- إصدار فاتورة لأي رحلة.

### 1.10 صفحة الملخص
المسار: `/driver/summary`

المميزات:
- فترات تقرير: يومي/أسبوعي/شهري/ربع سنوي/سنوي/مخصص.
- إحصائيات الإيراد، المسافة، عدد الرحلات، طرق الدفع.
- تنزيل تقرير PDF.

### 1.11 الرسائل
المسار: `/driver/messages`

المميزات:
- استقبال رسائل الإدارة.
- فتح المحادثة والرد.
- إنشاء رسالة جديدة للإدارة.
- لا يمكن الرد على الرسالة إذا كانت `resolved` أو `locked`.

### 1.12 الإشعارات
المسار: `/driver/notifications`

المميزات:
- عرض الإشعارات حسب النوع والأولوية.
- تمييز الإشعار كمقروء عند فتحه.
- عدّاد الإشعارات غير المقروءة.

### 1.13 حل المشكلات السريعة
- فشل تسجيل الدخول:
  - تحقق من رقم الهاتف وكلمة المرور.
  - تأكد أن الحساب نشط.
- لا يتم الانتقال بعد تسجيل الدخول:
  - حدّث الصفحة.
  - احذف Cache/Cookies وأعد المحاولة.
- GPS لا يعمل:
  - فعّل Location permission.
  - أعد المحاولة من زر تحديث الموقع.
- لم يتم إرسال الرحلة:
  - تأكد من الاتصال.
  - افحص الرحلات المحفوظة محلياً.

### 1.14 دليل الصور (لقطات شاشة من داخل الموقع)
> أضف اللقطات التالية داخل نفس الملف بعد التقاطها من الموقع الفعلي.

1. شاشة تسجيل الدخول (`/driver-login`)  
   ![Driver Login](./public/docs/driver-guide/01-driver-login.png)

2. اختيار نوع الرحلة (`/driver/taximeter`)  
   ![Ride Type Selection](./public/docs/driver-guide/02-ride-type-selection.png)

3. نموذج إدخال العناوين والسعر المقترح  
   ![Trip Form](./public/docs/driver-guide/03-trip-form.png)

4. الرحلة النشطة  
   ![Active Trip](./public/docs/driver-guide/04-active-trip.png)

5. سجل الرحلات (`/driver/trips`)  
   ![Trips List](./public/docs/driver-guide/05-trips-list.png)

6. صفحة الملخص (`/driver/summary`)  
   ![Summary](./public/docs/driver-guide/06-summary.png)

7. الرسائل (`/driver/messages`)  
   ![Messages](./public/docs/driver-guide/07-messages.png)

8. الإشعارات (`/driver/notifications`)  
   ![Notifications](./public/docs/driver-guide/08-notifications.png)

---

## 2) French (Français)

### 2.1 Vue d'ensemble
Ce guide explique l'utilisation du portail chauffeur étape par étape: connexion, démarrage/fin de trajet, facturation, rapports, messages et notifications.

### 2.2 Prérequis
- Compte chauffeur actif.
- Numéro de téléphone et mot de passe corrects.
- Connexion Internet stable.
- GPS activé pour `/driver/taximeter`.
- Installation PWA recommandée.

### 2.3 Connexion
Route: `/driver-login`

Étapes:
1. Ouvrez la page de connexion.
2. Entrez le numéro de téléphone (`phone`).
3. Entrez le mot de passe (`password`).
4. Cliquez sur le bouton de connexion.
5. En cas de succès, redirection vers `/driver/taximeter`.

### 2.4 Navigation principale
Routes:
- `/driver/taximeter`
- `/driver/trips`
- `/driver/summary`
- `/driver/messages`
- `/driver/notifications`

En-tête:
- Nom du chauffeur et de la société.
- Sélecteur de langue (NL / FR).
- `ThemeToggle`.
- `logout`.

### 2.5 Démarrer un trajet
Route: `/driver/taximeter`

Types:
- `INTERNAL`
- `BOLT`
- `UBER`
- `HEETCH`

Pour `INTERNAL`:
1. Adresse de départ.
2. Adresse d'arrivée.
3. Nom passager (optionnel).
4. Méthode de paiement.
5. Calculer le prix.
6. Vérifier prix/distance/durée.
7. Démarrer le trajet.

Pour plateformes externes:
1. Choisir la plateforme.
2. Saisir le numéro externe (optionnel).
3. Démarrer le trajet.

### 2.6 Pendant le trajet
- Affichage temps réel du trajet actif.
- Calcul distance/durée pour `INTERNAL`.
- Navigation via Waze ou Google Maps.

### 2.7 Fin du trajet
1. Cliquer sur fin du trajet.
2. Saisir le prix final.
3. Confirmer l'envoi.
4. En ligne: envoi immédiat.
5. Hors ligne: sauvegarde locale temporaire.

### 2.8 Facture PDF
- Après la fin du trajet, cliquer `Generate Invoice`.
- Le PDF est téléchargé automatiquement.

### 2.9 Historique des trajets
Route: `/driver/trips`

Fonctions:
- Filtres (tous, terminés, en attente, échoués).
- Détails par trajet.
- Ouverture Maps/Waze.
- Génération facture.

### 2.10 Résumé
Route: `/driver/summary`

Fonctions:
- Périodes multiples.
- Statistiques revenu/distance/volume/paiements.
- Export PDF.

### 2.11 Messages
Route: `/driver/messages`

Fonctions:
- Lire les messages.
- Répondre.
- Créer un nouveau message.
- Pas de réponse possible si `resolved` ou `locked`.

### 2.12 Notifications
Route: `/driver/notifications`

Fonctions:
- Liste des notifications.
- Marquage comme lu.
- Compteur non-lu.

### 2.13 Dépannage rapide
- Connexion refusée: vérifier téléphone, mot de passe, statut compte.
- Pas de redirection: vider cache/cookies et réessayer.
- GPS indisponible: autoriser la localisation et relancer.
- Envoi échoué: vérifier Internet, puis synchroniser.

### 2.14 Plan des captures d'écran
![Driver Login](./public/docs/driver-guide/01-driver-login.png)  
![Ride Type Selection](./public/docs/driver-guide/02-ride-type-selection.png)  
![Trip Form](./public/docs/driver-guide/03-trip-form.png)  
![Active Trip](./public/docs/driver-guide/04-active-trip.png)  
![Trips List](./public/docs/driver-guide/05-trips-list.png)  
![Summary](./public/docs/driver-guide/06-summary.png)  
![Messages](./public/docs/driver-guide/07-messages.png)  
![Notifications](./public/docs/driver-guide/08-notifications.png)

---

## 3) Dutch (Nederlands)

### 3.1 Overzicht
Deze handleiding toont stap voor stap hoe chauffeurs het portaal gebruiken: inloggen, rit starten/stoppen, facturen, rapporten, berichten en meldingen.

### 3.2 Vereisten
- Actief chauffeuraccount.
- Correct telefoonnummer en wachtwoord.
- Stabiele internetverbinding.
- GPS actief voor `/driver/taximeter`.
- PWA-installatie aanbevolen.

### 3.3 Inloggen
Route: `/driver-login`

Stappen:
1. Open de loginpagina.
2. Vul `phone` in.
3. Vul `password` in.
4. Klik op inloggen.
5. Bij succes ga je naar `/driver/taximeter`.

### 3.4 Hoofdnavigatie
Routes:
- `/driver/taximeter`
- `/driver/trips`
- `/driver/summary`
- `/driver/messages`
- `/driver/notifications`

Bovenbalk:
- Chauffeursnaam + bedrijfsnaam.
- Taalwissel (NL / FR).
- `ThemeToggle`.
- `logout`.

### 3.5 Rit starten
Route: `/driver/taximeter`

Rittypes:
- `INTERNAL`
- `BOLT`
- `UBER`
- `HEETCH`

Voor `INTERNAL`:
1. Startadres invullen.
2. Bestemmingsadres invullen.
3. Passagiersnaam (optioneel).
4. Betaalmethode kiezen.
5. Prijs berekenen.
6. Controleer prijs/afstand/tijd.
7. Start rit.

Voor externe platformen:
1. Platform kiezen.
2. Extern ritnummer invullen (optioneel).
3. Start rit.

### 3.6 Tijdens de rit
- Actieve rit wordt live getoond.
- Voor `INTERNAL`: afstand en duur worden bijgewerkt.
- Navigatieknoppen voor Waze/Google Maps.

### 3.7 Rit beëindigen
1. Klik op rit beëindigen.
2. Vul eindprijs in.
3. Bevestig verzenden.
4. Online: direct verzonden.
5. Offline: lokaal tijdelijk opgeslagen.

### 3.8 Factuur downloaden
- Na rit afronden klik `Generate Invoice`.
- PDF wordt automatisch gedownload.

### 3.9 Rittenoverzicht
Route: `/driver/trips`

Functies:
- Filters (alle, voltooid, in behandeling, mislukt).
- Ritdetails bekijken.
- Open route in Maps/Waze.
- Factuur per rit maken.

### 3.10 Samenvatting
Route: `/driver/summary`

Functies:
- Periodefilters.
- Omzet/afstand/rittenstatistieken.
- PDF-rapport downloaden.

### 3.11 Berichten
Route: `/driver/messages`

Functies:
- Berichten van beheer lezen.
- Antwoorden sturen.
- Nieuw bericht maken.
- Geen antwoord mogelijk op `resolved` of `locked`.

### 3.12 Meldingen
Route: `/driver/notifications`

Functies:
- Meldingenlijst met prioriteiten.
- Markeren als gelezen.
- Teller voor ongelezen meldingen.

### 3.13 Snelle probleemoplossing
- Login werkt niet: controleer telefoon/wachtwoord/accountstatus.
- Geen redirect na login: browsercache/cookies wissen.
- GPS-fout: locatietoegang toestaan en opnieuw proberen.
- Rit niet verzonden: internet controleren, later opnieuw synchroniseren.

### 3.14 Screenshot plan
![Driver Login](./public/docs/driver-guide/01-driver-login.png)  
![Ride Type Selection](./public/docs/driver-guide/02-ride-type-selection.png)  
![Trip Form](./public/docs/driver-guide/03-trip-form.png)  
![Active Trip](./public/docs/driver-guide/04-active-trip.png)  
![Trips List](./public/docs/driver-guide/05-trips-list.png)  
![Summary](./public/docs/driver-guide/06-summary.png)  
![Messages](./public/docs/driver-guide/07-messages.png)  
![Notifications](./public/docs/driver-guide/08-notifications.png)

---

## 4) Screenshot Capture Checklist (for your team)

Use this naming convention when capturing screenshots from the live system:

- `01-driver-login.png`
- `02-ride-type-selection.png`
- `03-trip-form.png`
- `04-active-trip.png`
- `05-trips-list.png`
- `06-summary.png`
- `07-messages.png`
- `08-notifications.png`

Suggested storage path:
- `public/docs/driver-guide/`

After adding images to this path, this same file will render a fully illustrated trilingual manual.

