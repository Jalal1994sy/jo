
# دليل نقل المشروع إلى سيرفر خاص
## دليل شامل خطوة بخطوة

---

## 📋 جدول المحتويات

1. [المتطلبات الأساسية](#المتطلبات-الأساسية)
2. [تصدير قاعدة البيانات](#تصدير-قاعدة-البيانات)
3. [نسخ ملفات المشروع](#نسخ-ملفات-المشروع)
4. [إعداد السيرفر الجديد](#إعداد-السيرفر-الجديد)
5. [استيراد قاعدة البيانات](#استيراد-قاعدة-البيانات)
6. [تكوين المشروع](#تكوين-المشروع)
7. [نشر التطبيق](#نشر-التطبيق)
8. [التحقق من النقل](#التحقق-من-النقل)
9. [استكشاف الأخطاء](#استكشاف-الأخطاء)

---

## 1️⃣ المتطلبات الأساسية

### على السيرفر الجديد:

- **نظام التشغيل**: Ubuntu 20.04+ أو Debian 11+
- **Node.js**: الإصدار 18.x أو أحدث
- **PostgreSQL**: الإصدار 14+ مع امتداد PostGIS
- **pnpm**: مدير الحزم
- **Git**: للتحكم في الإصدارات
- **Nginx**: كخادم ويب عكسي (اختياري)
- **PM2**: لإدارة عمليات Node.js (اختياري)

### تثبيت المتطلبات:

```bash
# تحديث النظام
sudo apt update && sudo apt upgrade -y

# تثبيت Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# تثبيت pnpm
npm install -g pnpm

# تثبيت PostgreSQL 14 مع PostGIS
sudo apt install -y postgresql-14 postgresql-14-postgis-3

# تثبيت Git
sudo apt install -y git

# تثبيت Nginx (اختياري)
sudo apt install -y nginx

# تثبيت PM2 (اختياري)
npm install -g pm2
```

---

## 2️⃣ تصدير قاعدة البيانات

### الخطوة 1: تصدير البيانات والهيكل

على السيرفر الحالي، قم بتصدير قاعدة البيانات بالكامل:

```bash
# تصدير قاعدة البيانات بالكامل (البيانات + الهيكل)
pg_dump -h <CURRENT_HOST> \
        -U <CURRENT_USER> \
        -d <DATABASE_NAME> \
        -F c \
        -b \
        -v \
        -f taxi_system_backup.dump

# أو استخدام تنسيق SQL نصي
pg_dump -h <CURRENT_HOST> \
        -U <CURRENT_USER> \
        -d <DATABASE_NAME> \
        --clean \
        --if-exists \
        --create \
        -f taxi_system_backup.sql
```

### الخطوة 2: تصدير الأدوار والصلاحيات

```bash
# تصدير الأدوار (roles)
pg_dumpall -h <CURRENT_HOST> \
           -U <CURRENT_USER> \
           --roles-only \
           -f taxi_system_roles.sql
```

### الخطوة 3: التحقق من ملفات النسخ الاحتياطي

```bash
# التحقق من حجم الملفات
ls -lh taxi_system_backup.dump
ls -lh taxi_system_backup.sql
ls -lh taxi_system_roles.sql

# التحقق من محتوى ملف SQL
head -n 50 taxi_system_backup.sql
```

---

## 3️⃣ نسخ ملفات المشروع

### الخطوة 1: إنشاء أرشيف للمشروع

```bash
# على السيرفر الحالي
cd /path/to/your/project

# إنشاء أرشيف مضغوط (باستثناء node_modules و .next)
tar -czf taxi_system_project.tar.gz \
    --exclude='node_modules' \
    --exclude='.next' \
    --exclude='.env.local' \
    --exclude='*.log' \
    .
```

### الخطوة 2: نقل الملفات إلى السيرفر الجديد

```bash
# استخدام SCP لنقل الملفات
scp taxi_system_backup.dump user@new-server:/home/user/
scp taxi_system_backup.sql user@new-server:/home/user/
scp taxi_system_roles.sql user@new-server:/home/user/
scp taxi_system_project.tar.gz user@new-server:/home/user/

# أو استخدام rsync (أسرع للملفات الكبيرة)
rsync -avz --progress \
      taxi_system_backup.dump \
      taxi_system_backup.sql \
      taxi_system_roles.sql \
      taxi_system_project.tar.gz \
      user@new-server:/home/user/
```

---

## 4️⃣ إعداد السيرفر الجديد

### الخطوة 1: إعداد PostgreSQL

```bash
# تسجيل الدخول كمستخدم postgres
sudo -u postgres psql

# إنشاء مستخدم قاعدة البيانات
CREATE USER taxi_admin WITH PASSWORD 'your_secure_password';

# إنشاء قاعدة البيانات
CREATE DATABASE taxi_system OWNER taxi_admin;

# منح الصلاحيات
GRANT ALL PRIVILEGES ON DATABASE taxi_system TO taxi_admin;

# تفعيل امتداد PostGIS
\c taxi_system
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

# الخروج
\q
```

### الخطوة 2: تكوين PostgreSQL للاتصالات الخارجية (إذا لزم الأمر)

```bash
# تحرير ملف postgresql.conf
sudo nano /etc/postgresql/14/main/postgresql.conf

# تعديل السطر التالي:
listen_addresses = '*'  # أو عنوان IP محدد

# تحرير ملف pg_hba.conf
sudo nano /etc/postgresql/14/main/pg_hba.conf

# إضافة السطر التالي (استبدل بعنوان IP الخاص بك):
host    all             all             0.0.0.0/0               md5

# إعادة تشغيل PostgreSQL
sudo systemctl restart postgresql
```

---

## 5️⃣ استيراد قاعدة البيانات

### الخطوة 1: استيراد الأدوار

```bash
# على السيرفر الجديد
sudo -u postgres psql -f /home/user/taxi_system_roles.sql
```

### الخطوة 2: استيراد البيانات

#### الطريقة 1: استخدام ملف dump

```bash
# استيراد من ملف dump
pg_restore -h localhost \
           -U taxi_admin \
           -d taxi_system \
           -v \
           /home/user/taxi_system_backup.dump

# إدخال كلمة المرور عند الطلب
```

#### الطريقة 2: استخدام ملف SQL

```bash
# استيراد من ملف SQL
psql -h localhost \
     -U taxi_admin \
     -d taxi_system \
     -f /home/user/taxi_system_backup.sql
```

### الخطوة 3: التحقق من الاستيراد

```bash
# تسجيل الدخول إلى قاعدة البيانات
psql -h localhost -U taxi_admin -d taxi_system

# التحقق من الجداول
\dt

# التحقق من عدد السجلات في جدول مهم
SELECT COUNT(*) FROM companies;
SELECT COUNT(*) FROM drivers;
SELECT COUNT(*) FROM trips;

# التحقق من امتدادات PostGIS
SELECT PostGIS_version();

# الخروج
\q
```

---

## 6️⃣ تكوين المشروع

### الخطوة 1: فك ضغط ملفات المشروع

```bash
# على السيرفر الجديد
cd /var/www  # أو المسار المفضل لديك
sudo mkdir -p taxi-system
sudo chown $USER:$USER taxi-system
cd taxi-system

# فك الضغط
tar -xzf /home/user/taxi_system_project.tar.gz
```

### الخطوة 2: إنشاء ملف متغيرات البيئة

```bash
# إنشاء ملف .env.local
nano .env.local
```

أضف المحتوى التالي (استبدل القيم بقيمك الفعلية):

```env
# Database Configuration
POSTGREST_URL=http://localhost:3000
POSTGREST_SCHEMA=app20251225073911jaqqaxdfir_v1
POSTGREST_API_KEY=your_postgrest_api_key_here

# PostgreSQL Direct Connection (للنسخ الاحتياطي والصيانة)
DATABASE_URL=postgresql://taxi_admin:your_secure_password@localhost:5432/taxi_system

# Next.js Configuration
NEXT_PUBLIC_APP_URL=https://yourdomain.com
NODE_ENV=production

# Authentication
JWT_SECRET=your_jwt_secret_here_minimum_32_characters
JWT_REFRESH_SECRET=your_jwt_refresh_secret_here_minimum_32_characters

# Email Configuration (Resend)
RESEND_KEY=your_resend_api_key_here

# Chiron API Configuration (Test Environment)
CHIRON_TEST_CLIENT_ID=your_test_client_id
CHIRON_TEST_CLIENT_SECRET=your_test_client_secret
CHIRON_TEST_AUTH_URL=https://mow-acc.api.vlaanderen.be/oauth/token
CHIRON_TEST_API_URL=https://mow-acc.api.vlaanderen.be/chiron/taxirit

# Chiron API Configuration (Production Environment)
CHIRON_PROD_CLIENT_ID=your_prod_client_id
CHIRON_PROD_CLIENT_SECRET=your_prod_client_secret
CHIRON_PROD_AUTH_URL=https://mow.api.vlaanderen.be/oauth/token
CHIRON_PROD_API_URL=https://mow.api.vlaanderen.be/chiron/taxirit

# Google OAuth (اختياري)
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# Zoer Host (للإشعارات والبريد الإلكتروني)
NEXT_PUBLIC_ZOER_HOST=https://api.zoer.ai
```

### الخطوة 3: تثبيت الاعتماديات

```bash
# تثبيت الحزم
pnpm install

# بناء المشروع
pnpm build
```

---

## 7️⃣ نشر التطبيق

### الطريقة 1: استخدام PM2 (موصى به)

```bash
# إنشاء ملف ecosystem.config.js
nano ecosystem.config.js
```

أضف المحتوى التالي:

```javascript
module.exports = {
  apps: [{
    name: 'taxi-system',
    script: 'node_modules/next/dist/bin/next',
    args: 'start -p 3000',
    cwd: '/var/www/taxi-system',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
  }]
};
```

```bash
# إنشاء مجلد السجلات
mkdir -p logs

# بدء التطبيق
pm2 start ecosystem.config.js

# حفظ التكوين
pm2 save

# تفعيل بدء التشغيل التلقائي
pm2 startup
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $USER --hp /home/$USER

# التحقق من الحالة
pm2 status
pm2 logs taxi-system
```

### الطريقة 2: استخدام systemd

```bash
# إنشاء ملف خدمة
sudo nano /etc/systemd/system/taxi-system.service
```

أضف المحتوى التالي:

```ini
[Unit]
Description=Taxi System Next.js Application
After=network.target postgresql.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/taxi-system
Environment="NODE_ENV=production"
Environment="PORT=3000"
ExecStart=/usr/bin/node /var/www/taxi-system/node_modules/next/dist/bin/next start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
# تفعيل وبدء الخدمة
sudo systemctl daemon-reload
sudo systemctl enable taxi-system
sudo systemctl start taxi-system

# التحقق من الحالة
sudo systemctl status taxi-system
```

### الخطوة 4: إعداد Nginx كخادم عكسي

```bash
# إنشاء ملف تكوين Nginx
sudo nano /etc/nginx/sites-available/taxi-system
```

أضف المحتوى التالي:

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    # إعادة التوجيه إلى HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    # شهادات SSL (استخدم Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    # تكوين SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # الحد الأقصى لحجم الملف المرفوع
    client_max_body_size 10M;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # تخزين مؤقت للملفات الثابتة
    location /_next/static {
        proxy_pass http://localhost:3000;
        proxy_cache_valid 200 60m;
        add_header Cache-Control "public, immutable";
    }

    # السجلات
    access_log /var/log/nginx/taxi-system-access.log;
    error_log /var/log/nginx/taxi-system-error.log;
}
```

```bash
# تفعيل الموقع
sudo ln -s /etc/nginx/sites-available/taxi-system /etc/nginx/sites-enabled/

# اختبار التكوين
sudo nginx -t

# إعادة تحميل Nginx
sudo systemctl reload nginx
```

### الخطوة 5: الحصول على شهادة SSL (Let's Encrypt)

```bash
# تثبيت Certbot
sudo apt install -y certbot python3-certbot-nginx

# الحصول على الشهادة
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# التجديد التلقائي
sudo certbot renew --dry-run
```

---

## 8️⃣ التحقق من النقل

### الخطوة 1: اختبار الاتصال بقاعدة البيانات

```bash
# من داخل مجلد المشروع
node -e "
const { createPostgrestClient } = require('./src/lib/postgrest.ts');
const client = createPostgrestClient();
client.from('companies').select('*').limit(1).then(console.log);
"
```

### الخطوة 2: اختبار التطبيق

```bash
# فتح المتصفح والانتقال إلى
https://yourdomain.com

# اختبار تسجيل الدخول
# اختبار إنشاء رحلة جديدة
# اختبار عرض البيانات
```

### الخطوة 3: التحقق من السجلات

```bash
# سجلات PM2
pm2 logs taxi-system

# سجلات Nginx
sudo tail -f /var/log/nginx/taxi-system-access.log
sudo tail -f /var/log/nginx/taxi-system-error.log

# سجلات PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-14-main.log
```

---

## 9️⃣ استكشاف الأخطاء

### مشكلة: فشل الاتصال بقاعدة البيانات

```bash
# التحقق من تشغيل PostgreSQL
sudo systemctl status postgresql

# التحقق من الاتصال
psql -h localhost -U taxi_admin -d taxi_system -c "SELECT 1;"

# التحقق من ملف pg_hba.conf
sudo nano /etc/postgresql/14/main/pg_hba.conf
```

### مشكلة: خطأ في بناء المشروع

```bash
# حذف المجلدات المؤقتة
rm -rf .next node_modules

# إعادة التثبيت
pnpm install

# إعادة البناء
pnpm build
```

### مشكلة: خطأ في الصلاحيات

```bash
# تعيين الصلاحيات الصحيحة
sudo chown -R $USER:$USER /var/www/taxi-system
chmod -R 755 /var/www/taxi-system
```

### مشكلة: امتداد PostGIS غير موجود

```bash
# تثبيت PostGIS
sudo apt install -y postgresql-14-postgis-3

# تفعيل الامتداد
sudo -u postgres psql -d taxi_system -c "CREATE EXTENSION IF NOT EXISTS postgis;"
```

---

## 🔒 أمان إضافي

### 1. جدار الحماية (UFW)

```bash
# تفعيل UFW
sudo ufw enable

# السماح بـ SSH
sudo ufw allow 22/tcp

# السماح بـ HTTP و HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# السماح بـ PostgreSQL (فقط من localhost)
sudo ufw allow from 127.0.0.1 to any port 5432

# التحقق من الحالة
sudo ufw status
```

### 2. النسخ الاحتياطي التلقائي

```bash
# إنشاء سكريبت النسخ الاحتياطي
sudo nano /usr/local/bin/backup-taxi-db.sh
```

أضف المحتوى التالي:

```bash
#!/bin/bash

BACKUP_DIR="/var/backups/taxi-system"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="taxi_system"
DB_USER="taxi_admin"

mkdir -p $BACKUP_DIR

pg_dump -U $DB_USER -d $DB_NAME -F c -f $BACKUP_DIR/taxi_system_$DATE.dump

# حذف النسخ الاحتياطية الأقدم من 30 يوم
find $BACKUP_DIR -name "*.dump" -mtime +30 -delete

echo "Backup completed: taxi_system_$DATE.dump"
```

```bash
# جعل السكريبت قابل للتنفيذ
sudo chmod +x /usr/local/bin/backup-taxi-db.sh

# إضافة مهمة cron (نسخ احتياطي يومي في الساعة 2 صباحاً)
sudo crontab -e

# أضف السطر التالي:
0 2 * * * /usr/local/bin/backup-taxi-db.sh >> /var/log/taxi-backup.log 2>&1
```

---

## 📊 مراقبة الأداء

### استخدام PM2 Monitoring

```bash
# عرض معلومات الأداء
pm2 monit

# عرض معلومات مفصلة
pm2 show taxi-system

# إعادة تشغيل عند استخدام ذاكرة عالية
pm2 start ecosystem.config.js --max-memory-restart 1G
```

---

## ✅ قائمة التحقق النهائية

- [ ] تم تصدير قاعدة البيانات بنجاح
- [ ] تم نقل جميع الملفات إلى السيرفر الجديد
- [ ] تم تثبيت جميع المتطلبات (Node.js, PostgreSQL, PostGIS)
- [ ] تم استيراد قاعدة البيانات بنجاح
- [ ] تم تكوين ملف `.env.local` بشكل صحيح
- [ ] تم بناء المشروع بنجاح (`pnpm build`)
- [ ] التطبيق يعمل على المنفذ 3000
- [ ] Nginx يعمل كخادم عكسي
- [ ] تم الحصول على شهادة SSL
- [ ] تم اختبار تسجيل الدخول
- [ ] تم اختبار إنشاء البيانات
- [ ] تم إعداد النسخ الاحتياطي التلقائي
- [ ] تم تكوين جدار الحماية

---

## 📞 الدعم

إذا واجهت أي مشاكل أثناء النقل:

1. تحقق من السجلات (`pm2 logs`, `nginx logs`, `postgresql logs`)
2. تأكد من صحة متغيرات البيئة
3. تحقق من الصلاحيات والملكية للملفات
4. تأكد من تشغيل جميع الخدمات المطلوبة

---

## 🎉 تهانينا!

لقد نجحت في نقل المشروع بالكامل إلى سيرفر خاص. جميع البيانات والمميزات محفوظة ويعمل التطبيق بشكل مستقل تماماً.
