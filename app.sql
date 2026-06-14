
-- Companies table (shared across system, no RLS needed)
CREATE TABLE companies (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    vat_number VARCHAR(50) UNIQUE,
    address TEXT,
    email VARCHAR(255),
    phone VARCHAR(50),
    logo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE companies IS 'Taxi companies registry';

-- Drivers table (extends users table)
CREATE TABLE drivers (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    company_id BIGINT NOT NULL,
    full_name VARCHAR(200) NOT NULL,
    national_id VARCHAR(50),
    driver_license VARCHAR(50),
    capacity_certificate_number VARCHAR(50),
    phone VARCHAR(50),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE drivers IS 'Taxi drivers information linked to user accounts';
COMMENT ON COLUMN drivers.user_id IS 'Reference to users.id (logical relationship)';
COMMENT ON COLUMN drivers.company_id IS 'Reference to companies.id (logical relationship)';

-- Vehicles table
CREATE TABLE vehicles (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL,
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    plate_number VARCHAR(50) NOT NULL UNIQUE,
    vin VARCHAR(100),
    chiron_vehicle_id VARCHAR(100),
    documents JSONB DEFAULT '[]'::jsonb,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE vehicles IS 'Taxi vehicles registry';
COMMENT ON COLUMN vehicles.documents IS 'Array of document objects: [{name, url, type, uploadDate}]';
COMMENT ON COLUMN vehicles.chiron_vehicle_id IS 'Vehicle ID in Chiron system';

-- Trips table
CREATE TABLE trips (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    company_id BIGINT NOT NULL,
    driver_id BIGINT NOT NULL,
    vehicle_id BIGINT NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    start_lat DECIMAL(10, 8),
    start_lon DECIMAL(11, 8),
    end_lat DECIMAL(10, 8),
    end_lon DECIMAL(11, 8),
    start_address TEXT,
    end_address TEXT,
    distance_km DECIMAL(10, 2),
    duration_minutes INTEGER,
    price DECIMAL(10, 2),
    start_fee DECIMAL(10, 2) DEFAULT 2.40,
    price_per_km DECIMAL(10, 2) DEFAULT 1.80,
    waiting_fee DECIMAL(10, 2) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('in_progress', 'completed', 'pending', 'success', 'failed', 'cancelled')),
    chiron_trip_id VARCHAR(100),
    chiron_sync_attempts INTEGER DEFAULT 0,
    last_sync_attempt TIMESTAMP WITH TIME ZONE,
    sync_error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE trips IS 'Taxi trips with Chiron sync status';
COMMENT ON COLUMN trips.status IS 'Trip status: in_progress, completed, pending (waiting sync), success (synced), failed (sync error), cancelled';
COMMENT ON COLUMN trips.chiron_sync_attempts IS 'Number of sync attempts to Chiron API';

-- Expenses table
CREATE TABLE expenses (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    company_id BIGINT NOT NULL,
    type VARCHAR(100) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    expense_date DATE NOT NULL,
    description TEXT,
    receipt_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE expenses IS 'Company expenses tracking';

-- Invoices table
CREATE TABLE invoices (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    company_id BIGINT NOT NULL,
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    client_name VARCHAR(200) NOT NULL,
    client_address TEXT,
    client_vat VARCHAR(50),
    items JSONB NOT NULL,
    total_htva DECIMAL(10, 2) NOT NULL,
    vat_rate DECIMAL(5, 2) DEFAULT 6.00,
    total_tvac DECIMAL(10, 2) NOT NULL,
    pdf_url TEXT,
    invoice_date DATE NOT NULL,
    due_date DATE,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'paid', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE invoices IS 'Generated invoices with Belgian format';
COMMENT ON COLUMN invoices.items IS 'Array of invoice items: [{description, quantity, unitPrice, total}]';
COMMENT ON COLUMN invoices.vat_rate IS 'VAT rate percentage (default 6% for taxi services)';

-- Chiron sync log table
CREATE TABLE chiron_sync_log (
    id BIGSERIAL PRIMARY KEY,
    trip_id BIGINT NOT NULL,
    attempt_number INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('success', 'failed', 'pending')),
    request_payload JSONB,
    response_payload JSONB,
    error_message TEXT,
    http_status_code INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE chiron_sync_log IS 'Log of all Chiron API sync attempts';

-- Create indexes for performance
CREATE INDEX idx_drivers_user_id ON drivers(user_id);
CREATE INDEX idx_drivers_company_id ON drivers(company_id);
CREATE INDEX idx_drivers_status ON drivers(status);

CREATE INDEX idx_vehicles_company_id ON vehicles(company_id);
CREATE INDEX idx_vehicles_plate_number ON vehicles(plate_number);
CREATE INDEX idx_vehicles_status ON vehicles(status);

CREATE INDEX idx_trips_user_id ON trips(user_id);
CREATE INDEX idx_trips_company_id ON trips(company_id);
CREATE INDEX idx_trips_driver_id ON trips(driver_id);
CREATE INDEX idx_trips_vehicle_id ON trips(vehicle_id);
CREATE INDEX idx_trips_status ON trips(status);
CREATE INDEX idx_trips_start_time ON trips(start_time);
CREATE INDEX idx_trips_chiron_trip_id ON trips(chiron_trip_id);

CREATE INDEX idx_expenses_user_id ON expenses(user_id);
CREATE INDEX idx_expenses_company_id ON expenses(company_id);
CREATE INDEX idx_expenses_expense_date ON expenses(expense_date);

CREATE INDEX idx_invoices_user_id ON invoices(user_id);
CREATE INDEX idx_invoices_company_id ON invoices(company_id);
CREATE INDEX idx_invoices_invoice_number ON invoices(invoice_number);
CREATE INDEX idx_invoices_status ON invoices(status);

CREATE INDEX idx_chiron_sync_log_trip_id ON chiron_sync_log(trip_id);
CREATE INDEX idx_chiron_sync_log_status ON chiron_sync_log(status);

-- Enable RLS on user-specific tables
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

-- RLS Policies for drivers table
CREATE POLICY drivers_select_policy ON drivers
    FOR SELECT USING (user_id = uid());

CREATE POLICY drivers_insert_policy ON drivers
    FOR INSERT WITH CHECK (user_id = uid());

CREATE POLICY drivers_update_policy ON drivers
    FOR UPDATE USING (user_id = uid()) WITH CHECK (user_id = uid());

CREATE POLICY drivers_delete_policy ON drivers
    FOR DELETE USING (user_id = uid());

-- RLS Policies for trips table
CREATE POLICY trips_select_policy ON trips
    FOR SELECT USING (user_id = uid());

CREATE POLICY trips_insert_policy ON trips
    FOR INSERT WITH CHECK (user_id = uid());

CREATE POLICY trips_update_policy ON trips
    FOR UPDATE USING (user_id = uid()) WITH CHECK (user_id = uid());

CREATE POLICY trips_delete_policy ON trips
    FOR DELETE USING (user_id = uid());

-- RLS Policies for expenses table
CREATE POLICY expenses_select_policy ON expenses
    FOR SELECT USING (user_id = uid());

CREATE POLICY expenses_insert_policy ON expenses
    FOR INSERT WITH CHECK (user_id = uid());

CREATE POLICY expenses_update_policy ON expenses
    FOR UPDATE USING (user_id = uid()) WITH CHECK (user_id = uid());

CREATE POLICY expenses_delete_policy ON expenses
    FOR DELETE USING (user_id = uid());

-- RLS Policies for invoices table
CREATE POLICY invoices_select_policy ON invoices
    FOR SELECT USING (user_id = uid());

CREATE POLICY invoices_insert_policy ON invoices
    FOR INSERT WITH CHECK (user_id = uid());

CREATE POLICY invoices_update_policy ON invoices
    FOR UPDATE USING (user_id = uid()) WITH CHECK (user_id = uid());

CREATE POLICY invoices_delete_policy ON invoices
    FOR DELETE USING (user_id = uid());

-- Trigger to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_drivers_updated_at BEFORE UPDATE ON drivers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON vehicles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_trips_updated_at BEFORE UPDATE ON trips
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_expenses_updated_at BEFORE UPDATE ON expenses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data for companies (shared data, no authentication needed)
INSERT INTO companies (name, vat_number, address, email, phone) VALUES
('Brussels Taxi Premium', 'BE0123456789', 'Avenue Louise 123, 1050 Brussels', 'info@btpremium.be', '+32 2 123 4567'),
('Green Cab Brussels', 'BE0987654321', 'Rue de la Loi 45, 1040 Brussels', 'contact@greencab.be', '+32 2 987 6543'),
('Euro Taxi Service', 'BE0456789123', 'Boulevard Anspach 78, 1000 Brussels', 'hello@eurotaxi.be', '+32 2 456 7891');

-- Insert sample data for vehicles (shared data, no authentication needed)
INSERT INTO vehicles (company_id, brand, model, plate_number, vin, chiron_vehicle_id, status) VALUES
(1, 'Mercedes-Benz', 'E-Class', '1-ABC-123', 'WDB2110061A123456', 'CHIRON-VEH-001', 'active'),
(1, 'Tesla', 'Model 3', '1-DEF-456', '5YJ3E1EA1KF123456', 'CHIRON-VEH-002', 'active'),
(2, 'Toyota', 'Prius', '1-GHI-789', 'JTDKN3DU5E0123456', 'CHIRON-VEH-003', 'active'),
(2, 'Volkswagen', 'Passat', '1-JKL-012', 'WVWZZZ3CZKE123456', 'CHIRON-VEH-004', 'maintenance'),
(3, 'BMW', '5 Series', '1-MNO-345', 'WBA5A5C50ED123456', 'CHIRON-VEH-005', 'active');

-- Create chiron_settings table for company-specific Chiron API configurations
CREATE TABLE chiron_settings (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL UNIQUE,
    client_id VARCHAR(255) NOT NULL,
    client_secret VARCHAR(255) NOT NULL,
    token TEXT,
    token_expires_at TIMESTAMP WITH TIME ZONE,
    driver_mapping JSONB DEFAULT '{}'::jsonb,
    vehicle_mapping JSONB DEFAULT '{}'::jsonb,
    auth_url VARCHAR(500) DEFAULT 'https://api.chiron-public.brussels/oauth/token',
    api_base_url VARCHAR(500) DEFAULT 'https://api.chiron-public.brussels/v1',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_chiron_settings_company_id ON chiron_settings(company_id);
CREATE INDEX idx_chiron_settings_is_active ON chiron_settings(is_active);

-- Add comments
COMMENT ON TABLE chiron_settings IS 'Company-specific Chiron API configurations for multi-tenant isolation';
COMMENT ON COLUMN chiron_settings.company_id IS 'Reference to companies.id (logical relationship) - each company has unique Chiron credentials';
COMMENT ON COLUMN chiron_settings.client_id IS 'Chiron OAuth2 client ID specific to this company';
COMMENT ON COLUMN chiron_settings.client_secret IS 'Chiron OAuth2 client secret specific to this company';
COMMENT ON COLUMN chiron_settings.token IS 'Cached OAuth2 access token to avoid frequent token requests';
COMMENT ON COLUMN chiron_settings.token_expires_at IS 'Token expiration timestamp for automatic refresh logic';
COMMENT ON COLUMN chiron_settings.driver_mapping IS 'JSON mapping: {internal_driver_id: chiron_capacity_certificate_number}';
COMMENT ON COLUMN chiron_settings.vehicle_mapping IS 'JSON mapping: {internal_vehicle_id: chiron_vehicle_id}';
COMMENT ON COLUMN chiron_settings.auth_url IS 'Chiron OAuth2 token endpoint URL';
COMMENT ON COLUMN chiron_settings.api_base_url IS 'Chiron API base URL for trip submissions';
COMMENT ON COLUMN chiron_settings.is_active IS 'Enable/disable Chiron sync for this company';

-- Add trigger for updated_at
CREATE TRIGGER update_chiron_settings_updated_at
    BEFORE UPDATE ON chiron_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- تعديل جدول companies لإضافة نظام التسعير وإعدادات Chiron
ALTER TABLE companies 
ADD COLUMN pricing_json JSONB DEFAULT '{
  "base_fee": 2.40,
  "km_rate": 1.80,
  "minute_rate": 0.40,
  "minimum_fare": 5.00,
  "night_fee": 2.00,
  "airport_fee": 5.00
}'::jsonb,
ADD COLUMN chiron_mode VARCHAR(20) DEFAULT 'TEST' CHECK (chiron_mode IN ('TEST', 'PRODUCTION')),
ADD COLUMN chiron_test_client_id VARCHAR(255),
ADD COLUMN chiron_test_client_secret VARCHAR(255),
ADD COLUMN chiron_test_auth_url VARCHAR(500) DEFAULT 'https://mow-acc.api.vlaanderen.be/oauth/token',
ADD COLUMN chiron_test_api_url VARCHAR(500) DEFAULT 'https://mow-acc.api.vlaanderen.be/chiron/taxirit',
ADD COLUMN chiron_prod_client_id VARCHAR(255),
ADD COLUMN chiron_prod_client_secret VARCHAR(255),
ADD COLUMN chiron_prod_auth_url VARCHAR(500) DEFAULT 'https://mow.api.vlaanderen.be/oauth/token',
ADD COLUMN chiron_prod_api_url VARCHAR(500) DEFAULT 'https://mow.api.vlaanderen.be/chiron/taxirit';

COMMENT ON COLUMN companies.pricing_json IS 'Company-specific pricing configuration: base_fee, km_rate, minute_rate, minimum_fare, night_fee, airport_fee';
COMMENT ON COLUMN companies.chiron_mode IS 'Current Chiron environment: TEST (for development) or PRODUCTION (after municipality approval)';
COMMENT ON COLUMN companies.chiron_test_client_id IS 'Chiron Test environment OAuth2 Client ID';
COMMENT ON COLUMN companies.chiron_test_client_secret IS 'Chiron Test environment OAuth2 Client Secret';
COMMENT ON COLUMN companies.chiron_test_auth_url IS 'Chiron Test environment OAuth token endpoint';
COMMENT ON COLUMN companies.chiron_test_api_url IS 'Chiron Test environment API base URL';
COMMENT ON COLUMN companies.chiron_prod_client_id IS 'Chiron Production environment OAuth2 Client ID (use only after approval)';
COMMENT ON COLUMN companies.chiron_prod_client_secret IS 'Chiron Production environment OAuth2 Client Secret';
COMMENT ON COLUMN companies.chiron_prod_auth_url IS 'Chiron Production environment OAuth token endpoint';
COMMENT ON COLUMN companies.chiron_prod_api_url IS 'Chiron Production environment API base URL';

-- تعديل جدول chiron_settings لدعم البيئتين
ALTER TABLE chiron_settings
ADD COLUMN chiron_mode VARCHAR(20) DEFAULT 'TEST' CHECK (chiron_mode IN ('TEST', 'PRODUCTION')),
ADD COLUMN test_token TEXT,
ADD COLUMN test_token_expires_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN prod_token TEXT,
ADD COLUMN prod_token_expires_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN chiron_settings.chiron_mode IS 'Active Chiron environment for this company';
COMMENT ON COLUMN chiron_settings.test_token IS 'Cached OAuth2 token for TEST environment';
COMMENT ON COLUMN chiron_settings.test_token_expires_at IS 'TEST token expiration timestamp';
COMMENT ON COLUMN chiron_settings.prod_token IS 'Cached OAuth2 token for PRODUCTION environment';
COMMENT ON COLUMN chiron_settings.prod_token_expires_at IS 'PRODUCTION token expiration timestamp';

-- تعديل جدول trips لإضافة حقول السعر المقترح ورقم الرحلة
ALTER TABLE trips
ADD COLUMN estimated_distance_km NUMERIC(10,2),
ADD COLUMN estimated_duration_min INTEGER,
ADD COLUMN proposed_price NUMERIC(10,2),
ADD COLUMN ritnummer VARCHAR(100) UNIQUE,
ADD COLUMN chiron_environment VARCHAR(20) CHECK (chiron_environment IN ('TEST', 'PRODUCTION'));

COMMENT ON COLUMN trips.estimated_distance_km IS 'Estimated distance calculated before trip start (for price proposal)';
COMMENT ON COLUMN trips.estimated_duration_min IS 'Estimated duration in minutes (for price proposal)';
COMMENT ON COLUMN trips.proposed_price IS 'Proposed price shown to driver before trip start (not a legal taximeter)';
COMMENT ON COLUMN trips.ritnummer IS 'Chiron trip number - must be same for VERTREK (start) and AANKOMST (arrival) messages';
COMMENT ON COLUMN trips.chiron_environment IS 'Chiron environment used for this trip (TEST or PRODUCTION)';

-- إنشاء فهرس لرقم الرحلة
CREATE INDEX idx_trips_ritnummer ON trips(ritnummer);

-- تحديث التعليقات على الجداول
COMMENT ON TABLE companies IS 'Taxi companies with independent pricing and Chiron configurations for multi-tenant system';
COMMENT ON TABLE chiron_settings IS 'Dual-environment Chiron API configurations (TEST and PRODUCTION) for each company';
COMMENT ON TABLE trips IS 'Taxi trips with price estimation (non-legal taximeter) and Chiron sync tracking';

-- Create test trips table for Chiron acceptance testing
CREATE TABLE test_trips (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL,
    ritnummer VARCHAR(100) NOT NULL UNIQUE,
    message_type VARCHAR(20) NOT NULL CHECK (message_type IN ('VERTREK', 'AANKOMST')),
    driver_id BIGINT NOT NULL,
    vehicle_id BIGINT NOT NULL,
    chiron_driver_id VARCHAR(100) NOT NULL,
    chiron_vehicle_id VARCHAR(100) NOT NULL,
    start_lat NUMERIC(10,8),
    start_lon NUMERIC(11,8),
    end_lat NUMERIC(10,8),
    end_lon NUMERIC(11,8),
    start_address TEXT,
    end_address TEXT,
    distance_km NUMERIC(10,2),
    price NUMERIC(10,2),
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    request_payload JSONB,
    response_payload JSONB,
    http_status_code INTEGER,
    sync_status VARCHAR(20) DEFAULT 'pending' CHECK (sync_status IN ('pending', 'success', 'failed')),
    error_message TEXT,
    test_sequence_number INTEGER NOT NULL CHECK (test_sequence_number BETWEEN 1 AND 10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_test_trips_company_id ON test_trips(company_id);
CREATE INDEX idx_test_trips_ritnummer ON test_trips(ritnummer);
CREATE INDEX idx_test_trips_sync_status ON test_trips(sync_status);
CREATE INDEX idx_test_trips_test_sequence ON test_trips(test_sequence_number);

COMMENT ON TABLE test_trips IS 'Test trips for Chiron acceptance testing - 5 VERTREK + 5 AANKOMST messages required by Brussels municipality';
COMMENT ON COLUMN test_trips.ritnummer IS 'Chiron trip number - must be same for VERTREK and AANKOMST pair';
COMMENT ON COLUMN test_trips.message_type IS 'Message type: VERTREK (start) or AANKOMST (arrival)';
COMMENT ON COLUMN test_trips.chiron_driver_id IS 'Driver capacity certificate number used in Chiron';
COMMENT ON COLUMN test_trips.chiron_vehicle_id IS 'Vehicle ID registered in Chiron system';
COMMENT ON COLUMN test_trips.test_sequence_number IS 'Test sequence: 1-5 for VERTREK messages, 6-10 for AANKOMST messages';
COMMENT ON COLUMN test_trips.sync_status IS 'Sync status with Chiron Test API';

-- Create acceptance test report table
CREATE TABLE acceptance_test_reports (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL,
    report_date DATE NOT NULL,
    total_messages INTEGER DEFAULT 10,
    success_count INTEGER DEFAULT 0,
    failed_count INTEGER DEFAULT 0,
    vertrek_count INTEGER DEFAULT 0,
    aankomst_count INTEGER DEFAULT 0,
    test_trip_ids JSONB DEFAULT '[]'::jsonb,
    report_status VARCHAR(20) DEFAULT 'in_progress' CHECK (report_status IN ('in_progress', 'completed', 'failed')),
    report_pdf_url TEXT,
    submitted_to_municipality BOOLEAN DEFAULT false,
    submission_date TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_acceptance_reports_company_id ON acceptance_test_reports(company_id);
CREATE INDEX idx_acceptance_reports_status ON acceptance_test_reports(report_status);

COMMENT ON TABLE acceptance_test_reports IS 'Acceptance test reports for municipality approval - tracks 10 required test messages';
COMMENT ON COLUMN acceptance_test_reports.test_trip_ids IS 'Array of test_trips.id that are included in this report';
COMMENT ON COLUMN acceptance_test_reports.report_status IS 'Report generation status';
COMMENT ON COLUMN acceptance_test_reports.submitted_to_municipality IS 'Whether report has been submitted to Brussels municipality';

-- إضافة حقل user_type لتمييز أنواع المستخدمين
ALTER TABLE users ADD COLUMN IF NOT EXISTS user_type VARCHAR(20) DEFAULT 'admin';

-- إضافة قيد للتحقق من قيم user_type
ALTER TABLE users ADD CONSTRAINT users_user_type_check 
    CHECK (user_type IN ('admin', 'driver', 'manager'));

-- تحديث السائقين الحاليين
UPDATE users 
SET user_type = 'driver' 
WHERE id IN (SELECT DISTINCT user_id FROM drivers);

-- إنشاء فهرس لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_users_user_type ON users(user_type);

COMMENT ON COLUMN users.user_type IS 'User type: admin (system admin), driver (taxi driver), manager (company manager)';

-- جدول بيانات تسجيل دخول السائقين
CREATE TABLE driver_credentials (
    id BIGSERIAL PRIMARY KEY,
    driver_id BIGINT NOT NULL UNIQUE,
    phone VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- إنشاء فهارس لتحسين الأداء
CREATE INDEX idx_driver_credentials_driver_id ON driver_credentials(driver_id);
CREATE INDEX idx_driver_credentials_phone ON driver_credentials(phone);
CREATE INDEX idx_driver_credentials_is_active ON driver_credentials(is_active);

-- إضافة تعليقات توضيحية
COMMENT ON TABLE driver_credentials IS 'Driver login credentials - stores phone and hashed password for driver app authentication';
COMMENT ON COLUMN driver_credentials.driver_id IS 'Reference to drivers.id (logical relationship)';
COMMENT ON COLUMN driver_credentials.phone IS 'Driver phone number used as login username';
COMMENT ON COLUMN driver_credentials.password_hash IS 'Bcrypt hashed password for secure authentication';
COMMENT ON COLUMN driver_credentials.is_active IS 'Whether driver login is enabled';
COMMENT ON COLUMN driver_credentials.last_login_at IS 'Timestamp of last successful login';

-- إضافة حقل رقم KBO للشركة (مطلوب في رسائل Chiron)
ALTER TABLE companies 
ADD COLUMN kbo_number VARCHAR(50) UNIQUE;

COMMENT ON COLUMN companies.kbo_number IS 'Belgian company registration number (KBO/BCE) - required for Chiron API submissions';

-- إنشاء فهرس لتسريع البحث برقم KBO
CREATE INDEX idx_companies_kbo_number ON companies(kbo_number);

-- تعديل جدول الفواتير لدعم جميع الميزات المطلوبة
ALTER TABLE invoices 
    -- تغيير نسبة VAT الافتراضية إلى 21%
    ALTER COLUMN vat_rate SET DEFAULT 21.00,
    
    -- إضافة حقل نوع الفاتورة
    ADD COLUMN invoice_type VARCHAR(50) DEFAULT 'one_time',
    
    -- إضافة حقل التكرار (للفواتير المتكررة)
    ADD COLUMN recurrence_period VARCHAR(20),
    
    -- إضافة حقل تاريخ الفاتورة التالية (للفواتير المتكررة)
    ADD COLUMN next_invoice_date DATE,
    
    -- إضافة حقل لتتبع الفاتورة الأصلية (للفواتير المتكررة)
    ADD COLUMN parent_invoice_id BIGINT,
    
    -- إضافة حقل لحالة الإرسال
    ADD COLUMN sent_at TIMESTAMP WITH TIME ZONE,
    
    -- إضافة حقل لعدد محاولات الإرسال
    ADD COLUMN send_attempts INTEGER DEFAULT 0,
    
    -- إضافة حقل لآخر خطأ في الإرسال
    ADD COLUMN send_error TEXT,
    
    -- إضافة حقل رقم الهاتف للعميل
    ADD COLUMN client_phone VARCHAR(50),
    
    -- إضافة حقل البريد الإلكتروني للعميل
    ADD COLUMN client_email VARCHAR(255),
    
    -- إضافة قيود للتحقق من صحة البيانات
    ADD CONSTRAINT invoices_invoice_type_check 
        CHECK (invoice_type IN ('one_time', 'subscription', 'recurring')),
    
    ADD CONSTRAINT invoices_recurrence_period_check 
        CHECK (recurrence_period IS NULL OR recurrence_period IN ('monthly', 'quarterly', 'yearly'));

-- إنشاء فهرس لنوع الفاتورة
CREATE INDEX idx_invoices_invoice_type ON invoices(invoice_type);

-- إنشاء فهرس لتاريخ الفاتورة التالية
CREATE INDEX idx_invoices_next_invoice_date ON invoices(next_invoice_date);

-- إنشاء فهرس للفاتورة الأصلية
CREATE INDEX idx_invoices_parent_invoice_id ON invoices(parent_invoice_id);

-- إضافة تعليقات توضيحية
COMMENT ON COLUMN invoices.invoice_type IS 'نوع الفاتورة: one_time (مرة واحدة), subscription (اشتراك), recurring (متكررة)';
COMMENT ON COLUMN invoices.recurrence_period IS 'فترة التكرار: monthly (شهري), quarterly (ربع سنوي), yearly (سنوي)';
COMMENT ON COLUMN invoices.next_invoice_date IS 'تاريخ الفاتورة التالية للفواتير المتكررة';
COMMENT ON COLUMN invoices.parent_invoice_id IS 'معرف الفاتورة الأصلية للفواتير المتكررة';
COMMENT ON COLUMN invoices.sent_at IS 'تاريخ ووقت إرسال الفاتورة';
COMMENT ON COLUMN invoices.send_attempts IS 'عدد محاولات إرسال الفاتورة';
COMMENT ON COLUMN invoices.send_error IS 'رسالة الخطأ في حالة فشل الإرسال';
COMMENT ON COLUMN invoices.client_phone IS 'رقم هاتف العميل';
COMMENT ON COLUMN invoices.client_email IS 'البريد الإلكتروني للعميل';

-- دالة لتوليد رقم الفاتورة تلقائياً
CREATE OR REPLACE FUNCTION generate_invoice_number(p_company_id BIGINT)
RETURNS VARCHAR(50) AS $$
DECLARE
    v_year VARCHAR(4);
    v_month VARCHAR(2);
    v_sequence INTEGER;
    v_invoice_number VARCHAR(50);
BEGIN
    -- الحصول على السنة والشهر الحاليين
    v_year := TO_CHAR(CURRENT_DATE, 'YYYY');
    v_month := TO_CHAR(CURRENT_DATE, 'MM');
    
    -- الحصول على آخر رقم تسلسلي للشركة في الشهر الحالي
    SELECT COALESCE(MAX(
        CAST(
            SUBSTRING(invoice_number FROM '[0-9]+$') AS INTEGER
        )
    ), 0) + 1
    INTO v_sequence
    FROM invoices
    WHERE company_id = p_company_id
    AND invoice_number LIKE 'INV-' || v_year || v_month || '-%';
    
    -- تكوين رقم الفاتورة
    v_invoice_number := 'INV-' || v_year || v_month || '-' || LPAD(v_sequence::TEXT, 4, '0');
    
    RETURN v_invoice_number;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generate_invoice_number(BIGINT) IS 'دالة لتوليد رقم فاتورة تلقائي بصيغة INV-YYYYMM-0001';

-- دالة لإنشاء الفواتير المتكررة تلقائياً
CREATE OR REPLACE FUNCTION create_recurring_invoices()
RETURNS void AS $$
DECLARE
    v_invoice RECORD;
    v_new_invoice_id BIGINT;
    v_new_invoice_number VARCHAR(50);
    v_new_invoice_date DATE;
BEGIN
    -- البحث عن الفواتير المتكررة التي حان موعد إنشائها
    FOR v_invoice IN
        SELECT *
        FROM invoices
        WHERE invoice_type IN ('subscription', 'recurring')
        AND next_invoice_date <= CURRENT_DATE
        AND status != 'cancelled'
    LOOP
        -- توليد رقم فاتورة جديد
        v_new_invoice_number := generate_invoice_number(v_invoice.company_id);
        
        -- تحديد تاريخ الفاتورة الجديدة
        v_new_invoice_date := v_invoice.next_invoice_date;
        
        -- إنشاء الفاتورة الجديدة
        INSERT INTO invoices (
            user_id,
            company_id,
            invoice_number,
            client_name,
            client_address,
            client_vat,
            client_phone,
            client_email,
            items,
            total_htva,
            vat_rate,
            total_tvac,
            invoice_date,
            due_date,
            status,
            invoice_type,
            recurrence_period,
            parent_invoice_id
        ) VALUES (
            v_invoice.user_id,
            v_invoice.company_id,
            v_new_invoice_number,
            v_invoice.client_name,
            v_invoice.client_address,
            v_invoice.client_vat,
            v_invoice.client_phone,
            v_invoice.client_email,
            v_invoice.items,
            v_invoice.total_htva,
            v_invoice.vat_rate,
            v_invoice.total_tvac,
            v_new_invoice_date,
            v_new_invoice_date + INTERVAL '30 days',
            'draft',
            v_invoice.invoice_type,
            v_invoice.recurrence_period,
            COALESCE(v_invoice.parent_invoice_id, v_invoice.id)
        ) RETURNING id INTO v_new_invoice_id;
        
        -- تحديث تاريخ الفاتورة التالية في الفاتورة الأصلية
        UPDATE invoices
        SET next_invoice_date = CASE
            WHEN recurrence_period = 'monthly' THEN next_invoice_date + INTERVAL '1 month'
            WHEN recurrence_period = 'quarterly' THEN next_invoice_date + INTERVAL '3 months'
            WHEN recurrence_period = 'yearly' THEN next_invoice_date + INTERVAL '1 year'
        END
        WHERE id = v_invoice.id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_recurring_invoices() IS 'دالة لإنشاء الفواتير المتكررة تلقائياً بناءً على الجدول الزمني المحدد';

-- تعديل القيمة الافتراضية لنسبة VAT من 6% إلى 21%
ALTER TABLE invoices 
ALTER COLUMN vat_rate SET DEFAULT 21.00;

-- تحديث التعليق لتوضيح النسبة الجديدة
COMMENT ON COLUMN invoices.vat_rate IS 'VAT rate percentage (default 21% for Belgian standard rate)';

-- إضافة حقل اسم العميل إلى جدول الشركات
ALTER TABLE companies ADD COLUMN client_name VARCHAR(200);

COMMENT ON COLUMN companies.client_name IS 'اسم العميل الرسمي للشركة - يستخدم في الفواتير والمراسلات';

-- إضافة حقل اسم الراكب في جدول الرحلات
ALTER TABLE trips ADD COLUMN passenger_name VARCHAR(200);

-- إضافة حقل الرحلة الحالية للسائق
ALTER TABLE drivers ADD COLUMN current_trip_id BIGINT;

-- إنشاء جدول لتتبع موقع السيارة أثناء الرحلة (لعرض الحركة على الخريطة)
CREATE TABLE trip_locations (
    id BIGSERIAL PRIMARY KEY,
    trip_id BIGINT NOT NULL,
    driver_id BIGINT NOT NULL,
    latitude NUMERIC(10,8) NOT NULL,
    longitude NUMERIC(11,8) NOT NULL,
    speed_kmh NUMERIC(5,2),
    heading NUMERIC(5,2),
    accuracy_meters NUMERIC(6,2),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- إنشاء فهارس لتحسين الأداء
CREATE INDEX idx_trip_locations_trip_id ON trip_locations(trip_id);
CREATE INDEX idx_trip_locations_driver_id ON trip_locations(driver_id);
CREATE INDEX idx_trip_locations_recorded_at ON trip_locations(recorded_at);
CREATE INDEX idx_drivers_current_trip_id ON drivers(current_trip_id);

-- إضافة تعليقات توضيحية
COMMENT ON COLUMN trips.passenger_name IS 'اسم الراكب (اختياري) - يظهر في شاشة الرحلة الجارية';
COMMENT ON COLUMN drivers.current_trip_id IS 'معرف الرحلة الحالية للسائق - NULL إذا لم يكن في رحلة';
COMMENT ON TABLE trip_locations IS 'تتبع موقع السيارة أثناء الرحلة لعرض الحركة على الخريطة في الوقت الفعلي';
COMMENT ON COLUMN trip_locations.trip_id IS 'معرف الرحلة المرتبطة';
COMMENT ON COLUMN trip_locations.driver_id IS 'معرف السائق';
COMMENT ON COLUMN trip_locations.latitude IS 'خط العرض';
COMMENT ON COLUMN trip_locations.longitude IS 'خط الطول';
COMMENT ON COLUMN trip_locations.speed_kmh IS 'السرعة بالكيلومتر في الساعة';
COMMENT ON COLUMN trip_locations.heading IS 'اتجاه الحركة بالدرجات (0-360)';
COMMENT ON COLUMN trip_locations.accuracy_meters IS 'دقة الموقع بالأمتار';
COMMENT ON COLUMN trip_locations.recorded_at IS 'وقت تسجيل الموقع';

-- جدول ربط الرحلات بالفواتير
CREATE TABLE trip_invoices (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    trip_id BIGINT NOT NULL,
    invoice_id BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(trip_id)
);

-- إضافة فهارس لتحسين الأداء
CREATE INDEX idx_trip_invoices_user_id ON trip_invoices(user_id);
CREATE INDEX idx_trip_invoices_trip_id ON trip_invoices(trip_id);
CREATE INDEX idx_trip_invoices_invoice_id ON trip_invoices(invoice_id);

-- تفعيل RLS
ALTER TABLE trip_invoices ENABLE ROW LEVEL SECURITY;

-- سياسات RLS
CREATE POLICY trip_invoices_select_policy ON trip_invoices
    FOR SELECT USING (user_id = uid());

CREATE POLICY trip_invoices_insert_policy ON trip_invoices
    FOR INSERT WITH CHECK (user_id = uid());

CREATE POLICY trip_invoices_update_policy ON trip_invoices
    FOR UPDATE USING (user_id = uid()) WITH CHECK (user_id = uid());

CREATE POLICY trip_invoices_delete_policy ON trip_invoices
    FOR DELETE USING (user_id = uid());

-- إضافة حقول جديدة لجدول invoices لدعم اللغة الهولندية
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS invoice_language VARCHAR(10) DEFAULT 'nl';
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50);
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS payment_reference VARCHAR(100);
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS bank_account VARCHAR(100);

-- تعليقات على الحقول الجديدة
COMMENT ON COLUMN invoices.invoice_language IS 'لغة الفاتورة: nl (هولندي), fr (فرنسي), en (إنجليزي)';
COMMENT ON COLUMN invoices.payment_method IS 'طريقة الدفع: cash (نقدي), card (بطاقة), bank_transfer (تحويل بنكي)';
COMMENT ON COLUMN invoices.payment_reference IS 'مرجع الدفع أو رقم المعاملة';
COMMENT ON COLUMN invoices.bank_account IS 'رقم الحساب البنكي للشركة (IBAN)';

COMMENT ON TABLE trip_invoices IS 'ربط الرحلات بالفواتير - كل رحلة يمكن أن يكون لها فاتورة واحدة';
COMMENT ON COLUMN trip_invoices.user_id IS 'معرف المستخدم (السائق أو المدير)';
COMMENT ON COLUMN trip_invoices.trip_id IS 'معرف الرحلة المرتبطة بالفاتورة';
COMMENT ON COLUMN trip_invoices.invoice_id IS 'معرف الفاتورة';

-- إضافة حقول جديدة لجدول الفواتير لدعم نظام الضرائب المزدوج ومعلومات الدفع

-- إضافة حقل تصنيف الفاتورة (رحلة أو شركة)
ALTER TABLE invoices 
ADD COLUMN invoice_category VARCHAR(20) DEFAULT 'trip' CHECK (invoice_category IN ('trip', 'company'));

-- إضافة حقل BIC Code
ALTER TABLE invoices 
ADD COLUMN bic_code VARCHAR(20);

-- إضافة حقل QR Code URL
ALTER TABLE invoices 
ADD COLUMN qr_code_url TEXT;

-- إضافة تعليقات توضيحية
COMMENT ON COLUMN invoices.invoice_category IS 'تصنيف الفاتورة: trip (فاتورة رحلة - ضريبة 6%), company (فاتورة شركة - ضريبة 21%)';
COMMENT ON COLUMN invoices.bic_code IS 'رمز BIC للحساب البنكي (مثال: ARSPBE22)';
COMMENT ON COLUMN invoices.qr_code_url IS 'رابط QR Code المتوافق مع Bancontact للدفع السريع';

-- إنشاء فهرس لتصنيف الفواتير
CREATE INDEX idx_invoices_category ON invoices(invoice_category);

-- تحديث القيم الافتراضية للفواتير الموجودة
UPDATE invoices 
SET invoice_category = 'trip' 
WHERE invoice_category IS NULL;

-- إضافة حقول معلومات الدفع البنكية إلى جدول companies
ALTER TABLE companies 
ADD COLUMN bank_account_iban VARCHAR(34),
ADD COLUMN bank_account_bic VARCHAR(11),
ADD COLUMN bank_account_holder VARCHAR(200);

-- إضافة تعليقات توضيحية للحقول الجديدة
COMMENT ON COLUMN companies.bank_account_iban IS 'رقم الحساب البنكي IBAN للشركة - يستخدم في الفواتير والدفع عبر Bancontact';
COMMENT ON COLUMN companies.bank_account_bic IS 'رمز BIC للبنك - يستخدم مع IBAN في التحويلات البنكية';
COMMENT ON COLUMN companies.bank_account_holder IS 'اسم صاحب الحساب البنكي - يظهر في الفواتير';

-- تحديث البيانات الافتراضية للشركة الموجودة (إذا كانت موجودة)
-- يمكن تعديل هذه القيم لاحقاً من صفحة الإعدادات
UPDATE companies 
SET 
    bank_account_iban = 'BE16973450355674',
    bank_account_bic = 'ARSPBE22',
    bank_account_holder = name
WHERE id = 1;

-- حذف جدول trip_invoices لأن الرحلات والفواتير مستقلة تماماً
DROP TABLE IF EXISTS trip_invoices CASCADE;

-- تحديث جدول companies لإضافة إعدادات التسعير الديناميكي
ALTER TABLE companies 
DROP COLUMN IF EXISTS pricing_json;

ALTER TABLE companies
ADD COLUMN base_rate_per_km NUMERIC(10,2) DEFAULT 2.00,
ADD COLUMN base_rate_per_minute NUMERIC(10,2) DEFAULT 0.50,
ADD COLUMN minimum_fare NUMERIC(10,2) DEFAULT 10.00,
ADD COLUMN airport_surcharge NUMERIC(10,2) DEFAULT 5.00,
ADD COLUMN night_surcharge_percentage NUMERIC(5,2) DEFAULT 20.00,
ADD COLUMN peak_hour_surcharge_percentage NUMERIC(5,2) DEFAULT 15.00,
ADD COLUMN night_start_hour INTEGER DEFAULT 22,
ADD COLUMN night_end_hour INTEGER DEFAULT 6,
ADD COLUMN peak_hours JSONB DEFAULT '[{"start": "07:00", "end": "09:00"}, {"start": "17:00", "end": "19:00"}]'::jsonb;

COMMENT ON COLUMN companies.base_rate_per_km IS 'السعر الأساسي لكل كيلومتر - يستخدم لحساب السعر المقترح';
COMMENT ON COLUMN companies.base_rate_per_minute IS 'السعر الأساسي لكل دقيقة - يستخدم لحساب السعر المقترح';
COMMENT ON COLUMN companies.minimum_fare IS 'الحد الأدنى لسعر الرحلة';
COMMENT ON COLUMN companies.airport_surcharge IS 'رسوم إضافية للرحلات من/إلى المطار';
COMMENT ON COLUMN companies.night_surcharge_percentage IS 'نسبة الزيادة للرحلات الليلية (%)';
COMMENT ON COLUMN companies.peak_hour_surcharge_percentage IS 'نسبة الزيادة لساعات الذروة (%)';
COMMENT ON COLUMN companies.night_start_hour IS 'ساعة بداية الفترة الليلية (0-23)';
COMMENT ON COLUMN companies.night_end_hour IS 'ساعة نهاية الفترة الليلية (0-23)';
COMMENT ON COLUMN companies.peak_hours IS 'ساعات الذروة - مصفوفة JSON تحتوي على فترات الذروة';

-- تحديث جدول trips لدعم نظام التسعير الجديد
ALTER TABLE trips
DROP COLUMN IF EXISTS start_fee,
DROP COLUMN IF EXISTS price_per_km,
DROP COLUMN IF EXISTS waiting_fee;

ALTER TABLE trips
ADD COLUMN initial_proposed_price NUMERIC(10,2),
ADD COLUMN driver_adjusted_price NUMERIC(10,2),
ADD COLUMN price_adjustment_reason VARCHAR(200),
ADD COLUMN is_airport_trip BOOLEAN DEFAULT false,
ADD COLUMN is_night_trip BOOLEAN DEFAULT false,
ADD COLUMN is_peak_hour_trip BOOLEAN DEFAULT false,
ADD COLUMN actual_distance_km NUMERIC(10,2),
ADD COLUMN actual_duration_minutes INTEGER;

COMMENT ON COLUMN trips.initial_proposed_price IS 'السعر المقترح الأولي المحسوب تلقائياً من النظام بناءً على المسافة والوقت';
COMMENT ON COLUMN trips.driver_adjusted_price IS 'السعر المعدل من قبل السائق (إذا قام بتعديل السعر المقترح)';
COMMENT ON COLUMN trips.price_adjustment_reason IS 'سبب تعديل السعر من قبل السائق';
COMMENT ON COLUMN trips.is_airport_trip IS 'هل الرحلة من/إلى المطار (لتطبيق رسوم المطار)';
COMMENT ON COLUMN trips.is_night_trip IS 'هل الرحلة في الفترة الليلية (لتطبيق رسوم ليلية)';
COMMENT ON COLUMN trips.is_peak_hour_trip IS 'هل الرحلة في ساعات الذروة (لتطبيق رسوم الذروة)';
COMMENT ON COLUMN trips.actual_distance_km IS 'المسافة الفعلية المقطوعة (قد تختلف عن المسافة المقدرة)';
COMMENT ON COLUMN trips.actual_duration_minutes IS 'المدة الفعلية للرحلة بالدقائق (قد تختلف عن المدة المقدرة)';

-- تحديث تعليق عمود price ليعكس النظام الجديد
COMMENT ON COLUMN trips.price IS 'السعر النهائي للرحلة (إما السعر المقترح الأولي أو السعر المعدل من السائق)';

-- إنشاء فهرس لتحسين أداء الاستعلامات
CREATE INDEX IF NOT EXISTS idx_trips_is_airport_trip ON trips(is_airport_trip);
CREATE INDEX IF NOT EXISTS idx_trips_is_night_trip ON trips(is_night_trip);
CREATE INDEX IF NOT EXISTS idx_trips_is_peak_hour_trip ON trips(is_peak_hour_trip);

-- تحديث جدول invoices لإزالة الارتباط بالرحلات
COMMENT ON TABLE invoices IS 'الفواتير المستقلة - لا علاقة لها بجدول الرحلات، يتم إنشاؤها يدوياً أو تلقائياً حسب الحاجة';

-- إضافة حقل طريقة الدفع في جدول الرحلات
ALTER TABLE trips ADD COLUMN payment_method VARCHAR(50);
COMMENT ON COLUMN trips.payment_method IS 'طريقة الدفع التي اختارها السائق: cash (نقدي), card (بطاقة), bank_transfer (تحويل بنكي), bancontact (بانكونتاكت)';

-- إضافة فهرس لطريقة الدفع
CREATE INDEX idx_trips_payment_method ON trips(payment_method);

-- جدول العقود السنوية للشركات
CREATE TABLE company_contracts (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL,
    contract_number VARCHAR(50) NOT NULL UNIQUE,
    contract_type VARCHAR(50) DEFAULT 'annual_subscription',
    contract_start_date DATE NOT NULL,
    contract_end_date DATE NOT NULL,
    contract_duration_months INTEGER DEFAULT 12,
    monthly_fee NUMERIC(10,2) NOT NULL,
    annual_fee NUMERIC(10,2) NOT NULL,
    contract_status VARCHAR(50) DEFAULT 'pending_signature' CHECK (contract_status IN ('pending_signature', 'active', 'suspended', 'expired', 'cancelled')),
    contract_html_template TEXT NOT NULL,
    contract_pdf_url TEXT,
    auto_renew BOOLEAN DEFAULT TRUE,
    renewal_notice_days INTEGER DEFAULT 90,
    suspension_reason TEXT,
    suspended_at TIMESTAMP WITH TIME ZONE,
    suspended_by_user_id BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE company_contracts IS 'عقود الاشتراك السنوية للشركات مع إمكانية التوقيع الإلكتروني والتعليق';
COMMENT ON COLUMN company_contracts.company_id IS 'معرف الشركة المرتبطة بالعقد';
COMMENT ON COLUMN company_contracts.contract_number IS 'رقم العقد الفريد';
COMMENT ON COLUMN company_contracts.contract_type IS 'نوع العقد: annual_subscription (اشتراك سنوي)';
COMMENT ON COLUMN company_contracts.contract_start_date IS 'تاريخ بداية العقد';
COMMENT ON COLUMN company_contracts.contract_end_date IS 'تاريخ نهاية العقد';
COMMENT ON COLUMN company_contracts.contract_duration_months IS 'مدة العقد بالأشهر (افتراضي 12 شهر)';
COMMENT ON COLUMN company_contracts.monthly_fee IS 'الرسوم الشهرية';
COMMENT ON COLUMN company_contracts.annual_fee IS 'الرسوم السنوية الإجمالية';
COMMENT ON COLUMN company_contracts.contract_status IS 'حالة العقد: pending_signature (بانتظار التوقيع), active (نشط), suspended (معلق), expired (منتهي), cancelled (ملغي)';
COMMENT ON COLUMN company_contracts.contract_html_template IS 'نص العقد القانوني بصيغة HTML - يحتوي على شروط العقد الكاملة';
COMMENT ON COLUMN company_contracts.contract_pdf_url IS 'رابط ملف PDF للعقد الموقع';
COMMENT ON COLUMN company_contracts.auto_renew IS 'التجديد التلقائي للعقد';
COMMENT ON COLUMN company_contracts.renewal_notice_days IS 'عدد الأيام للإشعار قبل التجديد (افتراضي 90 يوم)';
COMMENT ON COLUMN company_contracts.suspension_reason IS 'سبب تعليق العقد (مثل: التخلف عن السداد)';
COMMENT ON COLUMN company_contracts.suspended_at IS 'تاريخ ووقت تعليق العقد';
COMMENT ON COLUMN company_contracts.suspended_by_user_id IS 'معرف المستخدم الذي قام بتعليق العقد';

CREATE INDEX idx_company_contracts_company_id ON company_contracts(company_id);
CREATE INDEX idx_company_contracts_status ON company_contracts(contract_status);
CREATE INDEX idx_company_contracts_end_date ON company_contracts(contract_end_date);

-- جدول توقيعات العقود
CREATE TABLE contract_signatures (
    id BIGSERIAL PRIMARY KEY,
    contract_id BIGINT NOT NULL,
    company_id BIGINT NOT NULL,
    signer_name VARCHAR(200) NOT NULL,
    signer_email VARCHAR(255) NOT NULL,
    signer_position VARCHAR(100),
    signature_data TEXT,
    signature_ip VARCHAR(50),
    signature_user_agent TEXT,
    signed_at TIMESTAMP WITH TIME ZONE NOT NULL,
    signature_method VARCHAR(50) DEFAULT 'electronic' CHECK (signature_method IN ('electronic', 'digital_certificate', 'manual')),
    verification_code VARCHAR(100),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE contract_signatures IS 'توقيعات العقود الإلكترونية للشركات';
COMMENT ON COLUMN contract_signatures.contract_id IS 'معرف العقد المرتبط';
COMMENT ON COLUMN contract_signatures.company_id IS 'معرف الشركة';
COMMENT ON COLUMN contract_signatures.signer_name IS 'اسم الموقع';
COMMENT ON COLUMN contract_signatures.signer_email IS 'البريد الإلكتروني للموقع';
COMMENT ON COLUMN contract_signatures.signer_position IS 'منصب الموقع في الشركة';
COMMENT ON COLUMN contract_signatures.signature_data IS 'بيانات التوقيع (صورة أو بيانات رقمية)';
COMMENT ON COLUMN contract_signatures.signature_ip IS 'عنوان IP للموقع';
COMMENT ON COLUMN contract_signatures.signature_user_agent IS 'معلومات المتصفح للموقع';
COMMENT ON COLUMN contract_signatures.signed_at IS 'تاريخ ووقت التوقيع';
COMMENT ON COLUMN contract_signatures.signature_method IS 'طريقة التوقيع: electronic (إلكتروني), digital_certificate (شهادة رقمية), manual (يدوي)';
COMMENT ON COLUMN contract_signatures.verification_code IS 'رمز التحقق من التوقيع';
COMMENT ON COLUMN contract_signatures.is_verified IS 'هل تم التحقق من التوقيع';

CREATE INDEX idx_contract_signatures_contract_id ON contract_signatures(contract_id);
CREATE INDEX idx_contract_signatures_company_id ON contract_signatures(company_id);
CREATE INDEX idx_contract_signatures_signed_at ON contract_signatures(signed_at);

-- إضافة حقول حالة الاشتراك في جدول الشركات
ALTER TABLE companies ADD COLUMN subscription_status VARCHAR(50) DEFAULT 'pending_contract' CHECK (subscription_status IN ('pending_contract', 'active', 'suspended', 'expired', 'cancelled'));
ALTER TABLE companies ADD COLUMN current_contract_id BIGINT;
ALTER TABLE companies ADD COLUMN subscription_suspended_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE companies ADD COLUMN suspension_reason TEXT;
ALTER TABLE companies ADD COLUMN last_payment_date DATE;
ALTER TABLE companies ADD COLUMN next_payment_due_date DATE;
ALTER TABLE companies ADD COLUMN payment_overdue_days INTEGER DEFAULT 0;

COMMENT ON COLUMN companies.subscription_status IS 'حالة الاشتراك: pending_contract (بانتظار العقد), active (نشط), suspended (معلق), expired (منتهي), cancelled (ملغي)';
COMMENT ON COLUMN companies.current_contract_id IS 'معرف العقد الحالي النشط';
COMMENT ON COLUMN companies.subscription_suspended_at IS 'تاريخ ووقت تعليق الاشتراك';
COMMENT ON COLUMN companies.suspension_reason IS 'سبب تعليق الاشتراك (مثل: التخلف عن السداد)';
COMMENT ON COLUMN companies.last_payment_date IS 'تاريخ آخر دفعة';
COMMENT ON COLUMN companies.next_payment_due_date IS 'تاريخ استحقاق الدفعة القادمة';
COMMENT ON COLUMN companies.payment_overdue_days IS 'عدد أيام التأخير في السداد';

CREATE INDEX idx_companies_subscription_status ON companies(subscription_status);
CREATE INDEX idx_companies_current_contract_id ON companies(current_contract_id);
CREATE INDEX idx_companies_next_payment_due ON companies(next_payment_due_date);

-- جدول سجل تعليق الاشتراكات
CREATE TABLE subscription_suspension_log (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL,
    contract_id BIGINT,
    suspension_type VARCHAR(50) NOT NULL CHECK (suspension_type IN ('payment_overdue', 'contract_violation', 'manual', 'other')),
    suspension_reason TEXT NOT NULL,
    suspended_by_user_id BIGINT NOT NULL,
    suspended_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    reactivated_at TIMESTAMP WITH TIME ZONE,
    reactivated_by_user_id BIGINT,
    reactivation_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE subscription_suspension_log IS 'سجل تعليق وإعادة تفعيل اشتراكات الشركات';
COMMENT ON COLUMN subscription_suspension_log.company_id IS 'معرف الشركة';
COMMENT ON COLUMN subscription_suspension_log.contract_id IS 'معرف العقد المرتبط';
COMMENT ON COLUMN subscription_suspension_log.suspension_type IS 'نوع التعليق: payment_overdue (تأخر في السداد), contract_violation (مخالفة العقد), manual (يدوي), other (أخرى)';
COMMENT ON COLUMN subscription_suspension_log.suspension_reason IS 'سبب التعليق';
COMMENT ON COLUMN subscription_suspension_log.suspended_by_user_id IS 'معرف المستخدم الذي قام بالتعليق';
COMMENT ON COLUMN subscription_suspension_log.suspended_at IS 'تاريخ ووقت التعليق';
COMMENT ON COLUMN subscription_suspension_log.reactivated_at IS 'تاريخ ووقت إعادة التفعيل';
COMMENT ON COLUMN subscription_suspension_log.reactivated_by_user_id IS 'معرف المستخدم الذي قام بإعادة التفعيل';
COMMENT ON COLUMN subscription_suspension_log.reactivation_notes IS 'ملاحظات إعادة التفعيل';

CREATE INDEX idx_suspension_log_company_id ON subscription_suspension_log(company_id);
CREATE INDEX idx_suspension_log_contract_id ON subscription_suspension_log(contract_id);
CREATE INDEX idx_suspension_log_suspended_at ON subscription_suspension_log(suspended_at);

-- تعديل جدول company_contracts لدعم التوقيع الإلكتروني
ALTER TABLE company_contracts 
ADD COLUMN signature_token VARCHAR(100) UNIQUE,
ADD COLUMN signature_link_sent_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN signature_link_expires_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN signed_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN signer_ip VARCHAR(50),
ADD COLUMN signer_user_agent TEXT,
ADD COLUMN last_invoice_generated_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN next_invoice_generation_date DATE;

COMMENT ON COLUMN company_contracts.signature_token IS 'رمز فريد لرابط التوقيع الإلكتروني';
COMMENT ON COLUMN company_contracts.signature_link_sent_at IS 'تاريخ ووقت إرسال رابط التوقيع للعميل';
COMMENT ON COLUMN company_contracts.signature_link_expires_at IS 'تاريخ انتهاء صلاحية رابط التوقيع (عادة 7 أيام)';
COMMENT ON COLUMN company_contracts.signed_at IS 'تاريخ ووقت توقيع العقد من قبل العميل';
COMMENT ON COLUMN company_contracts.signer_ip IS 'عنوان IP للموقع';
COMMENT ON COLUMN company_contracts.signer_user_agent IS 'معلومات المتصفح للموقع';
COMMENT ON COLUMN company_contracts.last_invoice_generated_at IS 'تاريخ آخر فاتورة تم إنشاؤها تلقائياً';
COMMENT ON COLUMN company_contracts.next_invoice_generation_date IS 'تاريخ إنشاء الفاتورة الشهرية القادمة';

-- تعديل جدول invoices لدعم حالات الفاتورة المتقدمة
ALTER TABLE invoices 
DROP CONSTRAINT IF EXISTS invoices_status_check,
ADD COLUMN payment_status VARCHAR(20) DEFAULT 'pending',
ADD COLUMN paid_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN payment_confirmation_number VARCHAR(100),
ADD COLUMN overdue_days INTEGER DEFAULT 0,
ADD COLUMN reminder_sent_count INTEGER DEFAULT 0,
ADD COLUMN last_reminder_sent_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN contract_id BIGINT,
ADD COLUMN is_auto_generated BOOLEAN DEFAULT false,
ADD COLUMN generation_month INTEGER,
ADD COLUMN generation_year INTEGER;

-- إضافة قيد جديد لحالة الفاتورة
ALTER TABLE invoices 
ADD CONSTRAINT invoices_status_check 
CHECK (status IN ('draft', 'sent', 'paid', 'cancelled', 'overdue'));

-- إضافة قيد لحالة الدفع
ALTER TABLE invoices 
ADD CONSTRAINT invoices_payment_status_check 
CHECK (payment_status IN ('pending', 'paid', 'overdue', 'cancelled', 'refunded'));

COMMENT ON COLUMN invoices.payment_status IS 'حالة الدفع: pending (قيد الانتظار), paid (مدفوع), overdue (متأخر), cancelled (ملغي), refunded (مسترد)';
COMMENT ON COLUMN invoices.paid_at IS 'تاريخ ووقت الدفع الفعلي';
COMMENT ON COLUMN invoices.payment_confirmation_number IS 'رقم تأكيد الدفع أو رقم المعاملة البنكية';
COMMENT ON COLUMN invoices.overdue_days IS 'عدد أيام التأخير في السداد';
COMMENT ON COLUMN invoices.reminder_sent_count IS 'عدد مرات إرسال تذكير الدفع';
COMMENT ON COLUMN invoices.last_reminder_sent_at IS 'تاريخ آخر تذكير تم إرساله';
COMMENT ON COLUMN invoices.contract_id IS 'معرف العقد المرتبط (للفواتير الشهرية التلقائية)';
COMMENT ON COLUMN invoices.is_auto_generated IS 'هل تم إنشاء الفاتورة تلقائياً من العقد';
COMMENT ON COLUMN invoices.generation_month IS 'شهر إنشاء الفاتورة (1-12) للفواتير الشهرية';
COMMENT ON COLUMN invoices.generation_year IS 'سنة إنشاء الفاتورة للفواتير الشهرية';

-- إنشاء فهارس لتحسين الأداء
CREATE INDEX idx_company_contracts_signature_token ON company_contracts(signature_token);
CREATE INDEX idx_company_contracts_next_invoice_date ON company_contracts(next_invoice_generation_date);
CREATE INDEX idx_invoices_payment_status ON invoices(payment_status);
CREATE INDEX idx_invoices_contract_id ON invoices(contract_id);
CREATE INDEX idx_invoices_is_auto_generated ON invoices(is_auto_generated);
CREATE INDEX idx_invoices_overdue_days ON invoices(overdue_days);
CREATE INDEX idx_invoices_generation_period ON invoices(generation_year, generation_month);

-- جدول لتتبع سجل إرسال الفواتير
CREATE TABLE invoice_delivery_log (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL,
    delivery_method VARCHAR(50) NOT NULL CHECK (delivery_method IN ('email', 'sms', 'whatsapp', 'postal')),
    recipient_email VARCHAR(255),
    recipient_phone VARCHAR(50),
    delivery_status VARCHAR(20) DEFAULT 'pending' CHECK (delivery_status IN ('pending', 'sent', 'delivered', 'failed', 'bounced')),
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_invoice_delivery_log_invoice_id ON invoice_delivery_log(invoice_id);
CREATE INDEX idx_invoice_delivery_log_delivery_status ON invoice_delivery_log(delivery_status);
CREATE INDEX idx_invoice_delivery_log_sent_at ON invoice_delivery_log(sent_at);

COMMENT ON TABLE invoice_delivery_log IS 'سجل إرسال الفواتير للعملاء عبر البريد الإلكتروني أو الرسائل النصية';
COMMENT ON COLUMN invoice_delivery_log.invoice_id IS 'معرف الفاتورة';
COMMENT ON COLUMN invoice_delivery_log.delivery_method IS 'طريقة الإرسال: email (بريد إلكتروني), sms (رسالة نصية), whatsapp (واتساب), postal (بريد عادي)';
COMMENT ON COLUMN invoice_delivery_log.recipient_email IS 'البريد الإلكتروني للمستلم';
COMMENT ON COLUMN invoice_delivery_log.recipient_phone IS 'رقم هاتف المستلم';
COMMENT ON COLUMN invoice_delivery_log.delivery_status IS 'حالة التسليم: pending (قيد الانتظار), sent (تم الإرسال), delivered (تم التسليم), failed (فشل), bounced (مرتد)';
COMMENT ON COLUMN invoice_delivery_log.sent_at IS 'تاريخ ووقت الإرسال';
COMMENT ON COLUMN invoice_delivery_log.delivered_at IS 'تاريخ ووقت التسليم الفعلي';
COMMENT ON COLUMN invoice_delivery_log.error_message IS 'رسالة الخطأ في حالة فشل الإرسال';
COMMENT ON COLUMN invoice_delivery_log.retry_count IS 'عدد محاولات إعادة الإرسال';

-- جدول لتتبع سجل تعديلات الفواتير
CREATE TABLE invoice_edit_history (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL,
    edited_by_user_id BIGINT NOT NULL,
    field_name VARCHAR(100) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    edit_reason TEXT,
    edited_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_invoice_edit_history_invoice_id ON invoice_edit_history(invoice_id);
CREATE INDEX idx_invoice_edit_history_edited_by ON invoice_edit_history(edited_by_user_id);
CREATE INDEX idx_invoice_edit_history_edited_at ON invoice_edit_history(edited_at);

COMMENT ON TABLE invoice_edit_history IS 'سجل تعديلات الفواتير لتتبع جميع التغييرات';
COMMENT ON COLUMN invoice_edit_history.invoice_id IS 'معرف الفاتورة';
COMMENT ON COLUMN invoice_edit_history.edited_by_user_id IS 'معرف المستخدم الذي قام بالتعديل';
COMMENT ON COLUMN invoice_edit_history.field_name IS 'اسم الحقل الذي تم تعديله';
COMMENT ON COLUMN invoice_edit_history.old_value IS 'القيمة القديمة';
COMMENT ON COLUMN invoice_edit_history.new_value IS 'القيمة الجديدة';
COMMENT ON COLUMN invoice_edit_history.edit_reason IS 'سبب التعديل';
COMMENT ON COLUMN invoice_edit_history.edited_at IS 'تاريخ ووقت التعديل';

-- جدول لجدولة المهام التلقائية (إنشاء الفواتير الشهرية)
CREATE TABLE scheduled_tasks (
    id BIGSERIAL PRIMARY KEY,
    task_type VARCHAR(50) NOT NULL CHECK (task_type IN ('generate_monthly_invoice', 'send_payment_reminder', 'check_overdue_invoices', 'renew_contract')),
    entity_type VARCHAR(50) NOT NULL CHECK (entity_type IN ('contract', 'invoice', 'company')),
    entity_id BIGINT NOT NULL,
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
    execution_started_at TIMESTAMP WITH TIME ZONE,
    execution_completed_at TIMESTAMP WITH TIME ZONE,
    result_data JSONB,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_scheduled_tasks_task_type ON scheduled_tasks(task_type);
CREATE INDEX idx_scheduled_tasks_entity ON scheduled_tasks(entity_type, entity_id);
CREATE INDEX idx_scheduled_tasks_scheduled_for ON scheduled_tasks(scheduled_for);
CREATE INDEX idx_scheduled_tasks_status ON scheduled_tasks(status);

COMMENT ON TABLE scheduled_tasks IS 'جدولة المهام التلقائية مثل إنشاء الفواتير الشهرية وإرسال التذكيرات';
COMMENT ON COLUMN scheduled_tasks.task_type IS 'نوع المهمة: generate_monthly_invoice (إنشاء فاتورة شهرية), send_payment_reminder (إرسال تذكير دفع), check_overdue_invoices (فحص الفواتير المتأخرة), renew_contract (تجديد عقد)';
COMMENT ON COLUMN scheduled_tasks.entity_type IS 'نوع الكيان: contract (عقد), invoice (فاتورة), company (شركة)';
COMMENT ON COLUMN scheduled_tasks.entity_id IS 'معرف الكيان المرتبط';
COMMENT ON COLUMN scheduled_tasks.scheduled_for IS 'تاريخ ووقت تنفيذ المهمة';
COMMENT ON COLUMN scheduled_tasks.status IS 'حالة المهمة: pending (قيد الانتظار), processing (قيد المعالجة), completed (مكتملة), failed (فشلت), cancelled (ملغية)';
COMMENT ON COLUMN scheduled_tasks.execution_started_at IS 'تاريخ ووقت بدء التنفيذ';
COMMENT ON COLUMN scheduled_tasks.execution_completed_at IS 'تاريخ ووقت انتهاء التنفيذ';
COMMENT ON COLUMN scheduled_tasks.result_data IS 'بيانات نتيجة التنفيذ (JSON)';
COMMENT ON COLUMN scheduled_tasks.error_message IS 'رسالة الخطأ في حالة الفشل';
COMMENT ON COLUMN scheduled_tasks.retry_count IS 'عدد محاولات إعادة التنفيذ';
COMMENT ON COLUMN scheduled_tasks.max_retries IS 'الحد الأقصى لمحاولات إعادة التنفيذ';

-- إضافة حقل المرجع المنظم البلجيكي (OGM) إلى جدول الفواتير
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS structured_reference VARCHAR(20);

-- إضافة فهرس للمرجع المنظم لضمان عدم التكرار
CREATE UNIQUE INDEX IF NOT EXISTS idx_invoices_structured_reference ON invoices(structured_reference) WHERE structured_reference IS NOT NULL;

-- إضافة تعليق توضيحي
COMMENT ON COLUMN invoices.structured_reference IS 'المرجع المنظم البلجيكي (OGM) بصيغة +++XXX/XXXX/XXXXX+++ - يستخدم للدفع عبر Bancontact والتحويلات البنكية';

-- Enable PostGIS extension for advanced geospatial calculations
CREATE EXTENSION IF NOT EXISTS postgis;

-- Add geography columns to trips table for accurate distance calculations
ALTER TABLE trips 
ADD COLUMN IF NOT EXISTS start_location geography(POINT, 4326),
ADD COLUMN IF NOT EXISTS end_location geography(POINT, 4326);

-- Add geography column to trip_locations for real-time tracking
ALTER TABLE trip_locations 
ADD COLUMN IF NOT EXISTS location geography(POINT, 4326);

-- Create spatial indexes for fast proximity searches
CREATE INDEX IF NOT EXISTS idx_trips_start_location_gist 
ON trips USING GIST (start_location);

CREATE INDEX IF NOT EXISTS idx_trips_end_location_gist 
ON trips USING GIST (end_location);

CREATE INDEX IF NOT EXISTS idx_trip_locations_location_gist 
ON trip_locations USING GIST (location);

-- Create function to calculate actual distance from GPS points
CREATE OR REPLACE FUNCTION calculate_trip_actual_distance(p_trip_id BIGINT)
RETURNS NUMERIC AS $$
DECLARE
    total_distance NUMERIC := 0;
    prev_location geography;
    curr_location geography;
BEGIN
    -- Calculate total distance by summing distances between consecutive GPS points
    FOR curr_location IN 
        SELECT location 
        FROM trip_locations 
        WHERE trip_id = p_trip_id 
        ORDER BY recorded_at ASC
    LOOP
        IF prev_location IS NOT NULL THEN
            -- ST_Distance returns distance in meters, convert to kilometers
            total_distance := total_distance + (ST_Distance(prev_location, curr_location) / 1000.0);
        END IF;
        prev_location := curr_location;
    END LOOP;
    
    RETURN ROUND(total_distance, 2);
END;
$$ LANGUAGE plpgsql;

-- Create function to find nearest destinations
CREATE OR REPLACE FUNCTION find_nearest_destinations(
    p_latitude NUMERIC,
    p_longitude NUMERIC,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    destination_address TEXT,
    distance_km NUMERIC,
    trip_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.end_address,
        ROUND((ST_Distance(
            ST_MakePoint(p_longitude, p_latitude)::geography,
            t.end_location
        ) / 1000.0)::NUMERIC, 2) AS distance_km,
        COUNT(*) AS trip_count
    FROM trips t
    WHERE t.end_location IS NOT NULL
        AND t.end_address IS NOT NULL
        AND t.status = 'completed'
    GROUP BY t.end_address, t.end_location
    ORDER BY ST_Distance(
        ST_MakePoint(p_longitude, p_latitude)::geography,
        t.end_location
    ) ASC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update geography columns
CREATE OR REPLACE FUNCTION update_trip_geography()
RETURNS TRIGGER AS $$
BEGIN
    -- Update start location if coordinates are provided
    IF NEW.start_lat IS NOT NULL AND NEW.start_lon IS NOT NULL THEN
        NEW.start_location := ST_SetSRID(ST_MakePoint(NEW.start_lon, NEW.start_lat), 4326)::geography;
    END IF;
    
    -- Update end location if coordinates are provided
    IF NEW.end_lat IS NOT NULL AND NEW.end_lon IS NOT NULL THEN
        NEW.end_location := ST_SetSRID(ST_MakePoint(NEW.end_lon, NEW.end_lat), 4326)::geography;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_trip_geography
    BEFORE INSERT OR UPDATE ON trips
    FOR EACH ROW
    EXECUTE FUNCTION update_trip_geography();

-- Create trigger to automatically update trip_locations geography
CREATE OR REPLACE FUNCTION update_trip_location_geography()
RETURNS TRIGGER AS $$
BEGIN
    NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_trip_location_geography
    BEFORE INSERT OR UPDATE ON trip_locations
    FOR EACH ROW
    EXECUTE FUNCTION update_trip_location_geography();

-- Update existing records with geography data
UPDATE trips 
SET start_location = ST_SetSRID(ST_MakePoint(start_lon, start_lat), 4326)::geography
WHERE start_lat IS NOT NULL AND start_lon IS NOT NULL AND start_location IS NULL;

UPDATE trips 
SET end_location = ST_SetSRID(ST_MakePoint(end_lon, end_lat), 4326)::geography
WHERE end_lat IS NOT NULL AND end_lon IS NOT NULL AND end_location IS NULL;

UPDATE trip_locations 
SET location = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
WHERE location IS NULL;

-- Create index for faster destination suggestions
CREATE INDEX IF NOT EXISTS idx_trips_end_address_completed 
ON trips (end_address) 
WHERE status = 'completed' AND end_address IS NOT NULL;

-- Add comment explaining the new system
COMMENT ON COLUMN trips.start_location IS 'موقع البداية الجغرافي (PostGIS geography) - يستخدم لحسابات المسافة الدقيقة';
COMMENT ON COLUMN trips.end_location IS 'موقع النهاية الجغرافي (PostGIS geography) - يستخدم لحسابات المسافة الدقيقة';
COMMENT ON COLUMN trip_locations.location IS 'الموقع الجغرافي (PostGIS geography) - يستخدم لحساب المسافة الفعلية المقطوعة';
COMMENT ON FUNCTION calculate_trip_actual_distance(BIGINT) IS 'حساب المسافة الفعلية للرحلة بناءً على نقاط GPS المسجلة';
COMMENT ON FUNCTION find_nearest_destinations(NUMERIC, NUMERIC, INTEGER) IS 'البحث عن أقرب الوجهات بناءً على الموقع الحالي - مرتبة من الأقرب إلى الأبعد';

-- إضافة حقول الوقت والعناوين التفصيلية لجدول الرحلات الاختبارية
ALTER TABLE test_trips 
ADD COLUMN IF NOT EXISTS start_time TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS end_time TIMESTAMP WITH TIME ZONE;

-- تحديث التعليقات لتوضيح الحقول الجديدة
COMMENT ON COLUMN test_trips.start_time IS 'وقت بداية الرحلة الاختبارية - يظهر في ورقة الاختبار المقدمة للبلدية';
COMMENT ON COLUMN test_trips.end_time IS 'وقت نهاية الرحلة الاختبارية - يظهر في ورقة الاختبار المقدمة للبلدية';
COMMENT ON COLUMN test_trips.start_address IS 'عنوان نقطة البداية التفصيلي - يظهر في ورقة الاختبار المقدمة للبلدية';
COMMENT ON COLUMN test_trips.end_address IS 'عنوان نقطة الوصول التفصيلي - يظهر في ورقة الاختبار المقدمة للبلدية';

-- إنشاء فهارس لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_test_trips_start_time ON test_trips(start_time);
CREATE INDEX IF NOT EXISTS idx_test_trips_end_time ON test_trips(end_time);

-- إزالة القيد القديم
ALTER TABLE test_trips DROP CONSTRAINT test_trips_message_type_check;

-- إضافة قيد جديد يقبل الأحرف الكبيرة والصغيرة
ALTER TABLE test_trips ADD CONSTRAINT test_trips_message_type_check 
    CHECK (message_type IN ('vertrek', 'aankomst', 'VERTREK', 'AANKOMST'));

-- تحديث التعليق لتوضيح القيم المقبولة
COMMENT ON COLUMN test_trips.message_type IS 'Message type: VERTREK/vertrek (start) or AANKOMST/aankomst (arrival) - case insensitive';

-- إضافة حقل لغة العقد إلى جدول company_contracts
ALTER TABLE company_contracts 
ADD COLUMN contract_language VARCHAR(10) DEFAULT 'nl';

-- إضافة قيد للتحقق من اللغات المدعومة
ALTER TABLE company_contracts
ADD CONSTRAINT company_contracts_contract_language_check 
CHECK (contract_language IN ('nl', 'fr', 'en'));

-- إضافة تعليق توضيحي
COMMENT ON COLUMN company_contracts.contract_language IS 'لغة العقد وواجهة التوقيع: nl (هولندية), fr (فرنسية), en (إنجليزية)';

-- إنشاء فهرس لتحسين الأداء
CREATE INDEX idx_company_contracts_language ON company_contracts(contract_language);

-- حذف جدول chiron_settings القديم لأن جميع الإعدادات الآن في جدول companies
DROP TABLE IF EXISTS chiron_settings CASCADE;

-- التأكد من وجود جميع الأعمدة المطلوبة في جدول companies
-- (الأعمدة موجودة بالفعل، هذا فقط للتوثيق)

-- إعدادات Chiron في جدول companies تتضمن:
-- - chiron_mode: البيئة النشطة (TEST أو PRODUCTION)
-- 
-- بيئة الاختبار (TEST):
-- - chiron_test_client_id
-- - chiron_test_client_secret  
-- - chiron_test_auth_url (افتراضي: https://mow-acc.api.vlaanderen.be/oauth/token)
-- - chiron_test_api_url (افتراضي: https://mow-acc.api.vlaanderen.be/chiron/taxirit)
--
-- بيئة الإنتاج (PRODUCTION):
-- - chiron_prod_client_id
-- - chiron_prod_client_secret
-- - chiron_prod_auth_url (افتراضي: https://mow.api.vlaanderen.be/oauth/token)
-- - chiron_prod_api_url (افتراضي: https://mow.api.vlaanderen.be/chiron/taxirit)

-- إضافة حقل driver_id إلى جدول acceptance_test_reports
ALTER TABLE acceptance_test_reports 
ADD COLUMN driver_id BIGINT;

-- إضافة فهرس على driver_id لتحسين الأداء
CREATE INDEX idx_acceptance_reports_driver_id ON acceptance_test_reports(driver_id);

-- تحديث التعليق على الجدول
COMMENT ON TABLE acceptance_test_reports IS 'تقارير اختبار القبول للحصول على موافقة البلدية - يتتبع 10 رسائل اختبار مطلوبة (5 بداية + 5 وصول). السائق يمكنه فقط عرض وتحميل آخر تقرير، ولا يمكنه إنشاء تقارير جديدة (يجب أن يطلبها من المسؤول)';

-- تحديث التعليق على حقل driver_id
COMMENT ON COLUMN acceptance_test_reports.driver_id IS 'معرف السائق المرتبط بهذا التقرير - السائق يمكنه فقط عرض وتحميل آخر تقرير خاص به';

-- إضافة حقول جديدة لجدول trips لدعم الرحلات من المنصات الخارجية
ALTER TABLE trips 
ADD COLUMN ride_type VARCHAR(20) DEFAULT 'INTERNAL' CHECK (ride_type IN ('INTERNAL', 'EXTERNAL')),
ADD COLUMN external_source VARCHAR(20) CHECK (external_source IS NULL OR external_source IN ('BOLT', 'UBER', 'HEETCH')),
ADD COLUMN external_ride_number VARCHAR(100),
ADD COLUMN currency VARCHAR(3) DEFAULT 'EUR';

-- إضافة تعليقات توضيحية للحقول الجديدة
COMMENT ON COLUMN trips.ride_type IS 'نوع الرحلة: INTERNAL (رحلة داخلية عبر نظام التاكسي), EXTERNAL (رحلة من منصة خارجية)';
COMMENT ON COLUMN trips.external_source IS 'مصدر الرحلة الخارجية: BOLT, UBER, HEETCH - NULL للرحلات الداخلية';
COMMENT ON COLUMN trips.external_ride_number IS 'رقم الرحلة في المنصة الخارجية (مثل: BOLT-2025-001) - اختياري';
COMMENT ON COLUMN trips.currency IS 'عملة الرحلة - افتراضياً EUR';

-- إنشاء فهارس لتحسين الأداء
CREATE INDEX idx_trips_ride_type ON trips(ride_type);
CREATE INDEX idx_trips_external_source ON trips(external_source);
CREATE INDEX idx_trips_external_ride_number ON trips(external_ride_number);

-- تحديث التعليق على الجدول
COMMENT ON TABLE trips IS 'رحلات التاكسي - تدعم الرحلات الداخلية (INTERNAL) والرحلات من المنصات الخارجية (EXTERNAL: Bolt, Uber, Heetch) - النظام يعمل كوسيط نقل بيانات إلى Chiron';

-- إضافة حقول جديدة لتوضيح الفرق بين شركة المصدر والشركة العميل
ALTER TABLE invoices 
ADD COLUMN issuer_company_id BIGINT,
ADD COLUMN client_company_id BIGINT;

-- إضافة تعليقات توضيحية
COMMENT ON COLUMN invoices.issuer_company_id IS 'معرف الشركة المصدرة للفاتورة (شركتك) - مصدر الفاتورة';
COMMENT ON COLUMN invoices.client_company_id IS 'معرف الشركة العميل (الشركة التي تم اختيارها) - المستلم للفاتورة';
COMMENT ON COLUMN invoices.company_id IS 'معرف الشركة المرتبطة بالمستخدم (للتوافق مع النظام الحالي)';

-- إنشاء فهارس للحقول الجديدة
CREATE INDEX idx_invoices_issuer_company_id ON invoices(issuer_company_id);
CREATE INDEX idx_invoices_client_company_id ON invoices(client_company_id);

-- تحديث التعليق على الجدول
COMMENT ON TABLE invoices IS 'الفواتير المستقلة - issuer_company_id هي شركتك (المصدر)، client_company_id هي الشركة العميل (المستلم)';

-- إضافة فهارس لتحسين أداء الاستعلامات على جدول الفواتير
CREATE INDEX IF NOT EXISTS idx_invoices_issuer_company_id ON invoices(issuer_company_id);
CREATE INDEX IF NOT EXISTS idx_invoices_client_company_id ON invoices(client_company_id);

-- إضافة تعليقات توضيحية للحقول
COMMENT ON COLUMN invoices.issuer_company_id IS 'معرف الشركة المصدرة للفاتورة (شركتك) - يجب أن يكون company_id للمستخدم الحالي';
COMMENT ON COLUMN invoices.client_company_id IS 'معرف الشركة العميل المستلم للفاتورة - الشركة التي تم اختيارها من قائمة الشركات';

-- جدول معلومات عقود المنصات الخارجية (Uber, Bolt, Heetch) لكل شركة
CREATE TABLE platform_contracts (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL,
    platform_name VARCHAR(20) NOT NULL CHECK (platform_name IN ('UBER', 'BOLT', 'HEETCH')),
    contract_number VARCHAR(100) NOT NULL,
    contractor_name VARCHAR(200) NOT NULL,
    contract_start_date DATE,
    contract_end_date DATE,
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(company_id, platform_name)
);

CREATE INDEX idx_platform_contracts_company_id ON platform_contracts(company_id);
CREATE INDEX idx_platform_contracts_platform_name ON platform_contracts(platform_name);
CREATE INDEX idx_platform_contracts_is_active ON platform_contracts(is_active);

COMMENT ON TABLE platform_contracts IS 'معلومات عقود المنصات الخارجية (Uber, Bolt, Heetch) لكل شركة - تستخدم لملء بيانات Chiron تلقائياً';
COMMENT ON COLUMN platform_contracts.company_id IS 'معرف الشركة';
COMMENT ON COLUMN platform_contracts.platform_name IS 'اسم المنصة: UBER, BOLT, HEETCH';
COMMENT ON COLUMN platform_contracts.contract_number IS 'رقم العقد مع المنصة (Contractnummer) - يرسل إلى Chiron';
COMMENT ON COLUMN platform_contracts.contractor_name IS 'اسم المتعاقد (Contractant) - عادة اسم المنصة - يرسل إلى Chiron';
COMMENT ON COLUMN platform_contracts.contract_start_date IS 'تاريخ بداية العقد';
COMMENT ON COLUMN platform_contracts.contract_end_date IS 'تاريخ نهاية العقد';
COMMENT ON COLUMN platform_contracts.is_active IS 'هل العقد نشط حالياً';
COMMENT ON COLUMN platform_contracts.notes IS 'ملاحظات إضافية عن العقد';

-- جدول الإشعارات الرئيسي
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(50) DEFAULT 'announcement',
    priority VARCHAR(20) DEFAULT 'normal',
    target_audience VARCHAR(50) DEFAULT 'all_drivers',
    target_company_id BIGINT,
    icon_url TEXT,
    action_url TEXT,
    is_active BOOLEAN DEFAULT true,
    scheduled_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_by_user_id BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT notifications_notification_type_check CHECK (notification_type IN ('news', 'announcement', 'update', 'alert', 'promotion')),
    CONSTRAINT notifications_priority_check CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    CONSTRAINT notifications_target_audience_check CHECK (target_audience IN ('all_drivers', 'specific_company', 'active_drivers'))
);

-- جدول تتبع قراءة الإشعارات لكل مستخدم
CREATE TABLE user_notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    notification_id BIGINT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, notification_id)
);

-- إنشاء الفهارس لتحسين الأداء
CREATE INDEX idx_notifications_type ON notifications(notification_type);
CREATE INDEX idx_notifications_priority ON notifications(priority);
CREATE INDEX idx_notifications_target_audience ON notifications(target_audience);
CREATE INDEX idx_notifications_target_company_id ON notifications(target_company_id);
CREATE INDEX idx_notifications_is_active ON notifications(is_active);
CREATE INDEX idx_notifications_scheduled_at ON notifications(scheduled_at);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

CREATE INDEX idx_user_notifications_user_id ON user_notifications(user_id);
CREATE INDEX idx_user_notifications_notification_id ON user_notifications(notification_id);
CREATE INDEX idx_user_notifications_is_read ON user_notifications(is_read);
CREATE INDEX idx_user_notifications_user_read ON user_notifications(user_id, is_read);

-- تفعيل RLS على جدول user_notifications
ALTER TABLE user_notifications ENABLE ROW LEVEL SECURITY;

-- سياسات RLS لجدول user_notifications
CREATE POLICY user_notifications_select_policy ON user_notifications
    FOR SELECT USING (user_id = uid());

CREATE POLICY user_notifications_insert_policy ON user_notifications
    FOR INSERT WITH CHECK (user_id = uid());

CREATE POLICY user_notifications_update_policy ON user_notifications
    FOR UPDATE USING (user_id = uid()) WITH CHECK (user_id = uid());

CREATE POLICY user_notifications_delete_policy ON user_notifications
    FOR DELETE USING (user_id = uid());

-- إضافة تعليقات توضيحية
COMMENT ON TABLE notifications IS 'الإشعارات التي يتم إرسالها من لوحة التحكم لجميع السائقين أو لشركة معينة';
COMMENT ON COLUMN notifications.title IS 'عنوان الإشعار';
COMMENT ON COLUMN notifications.message IS 'نص الإشعار الكامل';
COMMENT ON COLUMN notifications.notification_type IS 'نوع الإشعار: news (أخبار), announcement (إعلان), update (تحديث), alert (تنبيه), promotion (عرض ترويجي)';
COMMENT ON COLUMN notifications.priority IS 'أولوية الإشعار: low (منخفضة), normal (عادية), high (عالية), urgent (عاجلة)';
COMMENT ON COLUMN notifications.target_audience IS 'الجمهور المستهدف: all_drivers (جميع السائقين), specific_company (شركة معينة), active_drivers (السائقين النشطين فقط)';
COMMENT ON COLUMN notifications.target_company_id IS 'معرف الشركة المستهدفة (إذا كان target_audience = specific_company)';
COMMENT ON COLUMN notifications.icon_url IS 'رابط أيقونة الإشعار (اختياري)';
COMMENT ON COLUMN notifications.action_url IS 'رابط الإجراء عند النقر على الإشعار (اختياري)';
COMMENT ON COLUMN notifications.is_active IS 'هل الإشعار نشط ويظهر للمستخدمين';
COMMENT ON COLUMN notifications.scheduled_at IS 'وقت جدولة الإشعار (اختياري - للإشعارات المجدولة)';
COMMENT ON COLUMN notifications.expires_at IS 'وقت انتهاء صلاحية الإشعار (اختياري)';
COMMENT ON COLUMN notifications.created_by_user_id IS 'معرف المستخدم الذي أنشأ الإشعار';

COMMENT ON TABLE user_notifications IS 'تتبع حالة قراءة الإشعارات لكل مستخدم';
COMMENT ON COLUMN user_notifications.user_id IS 'معرف المستخدم (السائق)';
COMMENT ON COLUMN user_notifications.notification_id IS 'معرف الإشعار';
COMMENT ON COLUMN user_notifications.is_read IS 'هل تم قراءة الإشعار';
COMMENT ON COLUMN user_notifications.read_at IS 'تاريخ ووقت قراءة الإشعار';

-- جدول الموزعين
CREATE TABLE distributors (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    full_name VARCHAR(200) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(50),
    commission_percentage NUMERIC(5,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_distributors_user_id ON distributors(user_id);
CREATE INDEX idx_distributors_email ON distributors(email);
CREATE INDEX idx_distributors_is_active ON distributors(is_active);

COMMENT ON TABLE distributors IS 'الموزعين - وسطاء يمكنهم إدارة عدة شركات';
COMMENT ON COLUMN distributors.user_id IS 'معرف المستخدم المرتبط بالموزع';
COMMENT ON COLUMN distributors.commission_percentage IS 'نسبة العمولة للموزع (%)';
COMMENT ON COLUMN distributors.is_active IS 'هل الموزع نشط';

-- جدول ربط الموزع بالشركات
CREATE TABLE distributor_companies (
    id BIGSERIAL PRIMARY KEY,
    distributor_id BIGINT NOT NULL,
    company_id BIGINT NOT NULL,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    assigned_by_user_id BIGINT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(distributor_id, company_id)
);

CREATE INDEX idx_distributor_companies_distributor_id ON distributor_companies(distributor_id);
CREATE INDEX idx_distributor_companies_company_id ON distributor_companies(company_id);
CREATE INDEX idx_distributor_companies_is_active ON distributor_companies(is_active);

COMMENT ON TABLE distributor_companies IS 'ربط الموزعين بالشركات التي يديرونها';
COMMENT ON COLUMN distributor_companies.distributor_id IS 'معرف الموزع';
COMMENT ON COLUMN distributor_companies.company_id IS 'معرف الشركة';
COMMENT ON COLUMN distributor_companies.assigned_by_user_id IS 'معرف المسؤول الذي قام بالتعيين';

-- جدول طلبات الموافقة
CREATE TABLE approval_requests (
    id BIGSERIAL PRIMARY KEY,
    request_type VARCHAR(50) NOT NULL CHECK (request_type IN ('update', 'delete')),
    entity_type VARCHAR(50) NOT NULL CHECK (entity_type IN ('company', 'vehicle', 'driver', 'invoice', 'expense')),
    entity_id BIGINT NOT NULL,
    requested_by_user_id BIGINT NOT NULL,
    distributor_id BIGINT,
    request_data JSONB NOT NULL,
    current_data JSONB,
    request_reason TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
    reviewed_by_user_id BIGINT,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    review_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_approval_requests_request_type ON approval_requests(request_type);
CREATE INDEX idx_approval_requests_entity_type ON approval_requests(entity_type);
CREATE INDEX idx_approval_requests_entity_id ON approval_requests(entity_id);
CREATE INDEX idx_approval_requests_requested_by ON approval_requests(requested_by_user_id);
CREATE INDEX idx_approval_requests_distributor_id ON approval_requests(distributor_id);
CREATE INDEX idx_approval_requests_status ON approval_requests(status);
CREATE INDEX idx_approval_requests_created_at ON approval_requests(created_at);

COMMENT ON TABLE approval_requests IS 'طلبات الموافقة على التعديلات والحذف من الموزعين';
COMMENT ON COLUMN approval_requests.request_type IS 'نوع الطلب: update (تعديل), delete (حذف)';
COMMENT ON COLUMN approval_requests.entity_type IS 'نوع الكيان: company (شركة), vehicle (مركبة), driver (سائق), invoice (فاتورة), expense (مصروف)';
COMMENT ON COLUMN approval_requests.entity_id IS 'معرف الكيان المراد تعديله أو حذفه';
COMMENT ON COLUMN approval_requests.requested_by_user_id IS 'معرف المستخدم الذي قدم الطلب';
COMMENT ON COLUMN approval_requests.distributor_id IS 'معرف الموزع (إذا كان الطلب من موزع)';
COMMENT ON COLUMN approval_requests.request_data IS 'البيانات المطلوب تعديلها (JSON)';
COMMENT ON COLUMN approval_requests.current_data IS 'البيانات الحالية قبل التعديل (JSON)';
COMMENT ON COLUMN approval_requests.request_reason IS 'سبب الطلب';
COMMENT ON COLUMN approval_requests.status IS 'حالة الطلب: pending (قيد الانتظار), approved (موافق عليه), rejected (مرفوض), cancelled (ملغي)';
COMMENT ON COLUMN approval_requests.reviewed_by_user_id IS 'معرف المسؤول الذي راجع الطلب';
COMMENT ON COLUMN approval_requests.reviewed_at IS 'تاريخ ووقت المراجعة';
COMMENT ON COLUMN approval_requests.review_notes IS 'ملاحظات المراجعة';

-- جدول سجل الموافقات
CREATE TABLE approval_history (
    id BIGSERIAL PRIMARY KEY,
    approval_request_id BIGINT NOT NULL,
    action VARCHAR(50) NOT NULL CHECK (action IN ('submitted', 'approved', 'rejected', 'cancelled', 'executed')),
    performed_by_user_id BIGINT NOT NULL,
    action_notes TEXT,
    action_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_approval_history_request_id ON approval_history(approval_request_id);
CREATE INDEX idx_approval_history_action ON approval_history(action);
CREATE INDEX idx_approval_history_performed_by ON approval_history(performed_by_user_id);
CREATE INDEX idx_approval_history_created_at ON approval_history(created_at);

COMMENT ON TABLE approval_history IS 'سجل تاريخ جميع الإجراءات على طلبات الموافقة';
COMMENT ON COLUMN approval_history.approval_request_id IS 'معرف طلب الموافقة';
COMMENT ON COLUMN approval_history.action IS 'الإجراء: submitted (تم التقديم), approved (تمت الموافقة), rejected (تم الرفض), cancelled (تم الإلغاء), executed (تم التنفيذ)';
COMMENT ON COLUMN approval_history.performed_by_user_id IS 'معرف المستخدم الذي قام بالإجراء';
COMMENT ON COLUMN approval_history.action_notes IS 'ملاحظات الإجراء';
COMMENT ON COLUMN approval_history.action_data IS 'بيانات إضافية عن الإجراء (JSON)';

-- تحديث جدول المستخدمين لإضافة دور الموزع
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_user_type_check;
ALTER TABLE users ADD CONSTRAINT users_user_type_check 
    CHECK (user_type IN ('admin', 'driver', 'manager', 'distributor'));

COMMENT ON COLUMN users.user_type IS 'User type: admin (system admin), driver (taxi driver), manager (company manager), distributor (موزع)';

-- جدول صلاحيات الموزع
CREATE TABLE distributor_permissions (
    id BIGSERIAL PRIMARY KEY,
    distributor_id BIGINT NOT NULL,
    permission_type VARCHAR(50) NOT NULL CHECK (permission_type IN (
        'add_company', 'add_vehicle', 'add_driver',
        'view_invoices', 'view_expenses', 'view_reports',
        'manage_contracts', 'view_analytics'
    )),
    is_granted BOOLEAN DEFAULT true,
    granted_by_user_id BIGINT NOT NULL,
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    UNIQUE(distributor_id, permission_type)
);

CREATE INDEX idx_distributor_permissions_distributor_id ON distributor_permissions(distributor_id);
CREATE INDEX idx_distributor_permissions_permission_type ON distributor_permissions(permission_type);
CREATE INDEX idx_distributor_permissions_is_granted ON distributor_permissions(is_granted);

COMMENT ON TABLE distributor_permissions IS 'صلاحيات الموزعين - تحديد ما يمكن للموزع القيام به';
COMMENT ON COLUMN distributor_permissions.distributor_id IS 'معرف الموزع';
COMMENT ON COLUMN distributor_permissions.permission_type IS 'نوع الصلاحية';
COMMENT ON COLUMN distributor_permissions.is_granted IS 'هل الصلاحية ممنوحة';
COMMENT ON COLUMN distributor_permissions.granted_by_user_id IS 'معرف المسؤول الذي منح الصلاحية';

-- إضافة حقل distributor_id للجداول الرئيسية لتتبع من أضاف البيانات
ALTER TABLE companies ADD COLUMN IF NOT EXISTS created_by_distributor_id BIGINT;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS created_by_distributor_id BIGINT;
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS created_by_distributor_id BIGINT;

CREATE INDEX idx_companies_created_by_distributor ON companies(created_by_distributor_id);
CREATE INDEX idx_vehicles_created_by_distributor ON vehicles(created_by_distributor_id);
CREATE INDEX idx_drivers_created_by_distributor ON drivers(created_by_distributor_id);

COMMENT ON COLUMN companies.created_by_distributor_id IS 'معرف الموزع الذي أنشأ الشركة (NULL إذا أنشأها المسؤول)';
COMMENT ON COLUMN vehicles.created_by_distributor_id IS 'معرف الموزع الذي أنشأ المركبة (NULL إذا أنشأها المسؤول)';
COMMENT ON COLUMN drivers.created_by_distributor_id IS 'معرف الموزع الذي أنشأ السائق (NULL إذا أنشأه المسؤول)';

-- جدول جلسات تسجيل دخول الموزعين
CREATE TABLE distributor_sessions (
    id BIGSERIAL PRIMARY KEY,
    distributor_id BIGINT NOT NULL,
    token TEXT NOT NULL UNIQUE,
    ip_address VARCHAR(50),
    user_agent TEXT,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_distributor_sessions_distributor_id ON distributor_sessions(distributor_id);
CREATE INDEX idx_distributor_sessions_token ON distributor_sessions(token);
CREATE INDEX idx_distributor_sessions_is_active ON distributor_sessions(is_active);
CREATE INDEX idx_distributor_sessions_expires_at ON distributor_sessions(expires_at);

COMMENT ON TABLE distributor_sessions IS 'جلسات تسجيل دخول الموزعين - منفصلة عن جلسات المسؤولين';
COMMENT ON COLUMN distributor_sessions.distributor_id IS 'معرف الموزع';
COMMENT ON COLUMN distributor_sessions.token IS 'رمز الجلسة الفريد (JWT)';
COMMENT ON COLUMN distributor_sessions.ip_address IS 'عنوان IP للموزع';
COMMENT ON COLUMN distributor_sessions.user_agent IS 'معلومات المتصفح';
COMMENT ON COLUMN distributor_sessions.expires_at IS 'تاريخ انتهاء صلاحية الجلسة';
COMMENT ON COLUMN distributor_sessions.is_active IS 'هل الجلسة نشطة';
COMMENT ON COLUMN distributor_sessions.last_activity_at IS 'آخر نشاط للموزع';

-- جدول سجل نشاطات الموزعين
CREATE TABLE distributor_activity_log (
    id BIGSERIAL PRIMARY KEY,
    distributor_id BIGINT NOT NULL,
    activity_type VARCHAR(50) NOT NULL CHECK (activity_type IN (
        'login', 'logout', 'create_company', 'create_driver', 'create_vehicle',
        'request_update', 'request_delete', 'view_invoice', 'view_report'
    )),
    entity_type VARCHAR(50),
    entity_id BIGINT,
    activity_details JSONB,
    ip_address VARCHAR(50),
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_distributor_activity_log_distributor_id ON distributor_activity_log(distributor_id);
CREATE INDEX idx_distributor_activity_log_activity_type ON distributor_activity_log(activity_type);
CREATE INDEX idx_distributor_activity_log_created_at ON distributor_activity_log(created_at);
CREATE INDEX idx_distributor_activity_log_entity ON distributor_activity_log(entity_type, entity_id);

COMMENT ON TABLE distributor_activity_log IS 'سجل جميع نشاطات الموزعين لأغراض المراقبة والتدقيق';
COMMENT ON COLUMN distributor_activity_log.distributor_id IS 'معرف الموزع';
COMMENT ON COLUMN distributor_activity_log.activity_type IS 'نوع النشاط: login (تسجيل دخول), create_company (إنشاء شركة), request_update (طلب تعديل), إلخ';
COMMENT ON COLUMN distributor_activity_log.entity_type IS 'نوع الكيان المرتبط بالنشاط';
COMMENT ON COLUMN distributor_activity_log.entity_id IS 'معرف الكيان';
COMMENT ON COLUMN distributor_activity_log.activity_details IS 'تفاصيل إضافية عن النشاط (JSON)';

-- إضافة حقل password_hash لجدول distributors
ALTER TABLE distributors ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);
ALTER TABLE distributors ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE distributors ADD COLUMN IF NOT EXISTS failed_login_attempts INTEGER DEFAULT 0;
ALTER TABLE distributors ADD COLUMN IF NOT EXISTS account_locked_until TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN distributors.password_hash IS 'كلمة المرور المشفرة للموزع (bcrypt)';
COMMENT ON COLUMN distributors.last_login_at IS 'تاريخ آخر تسجيل دخول';
COMMENT ON COLUMN distributors.failed_login_attempts IS 'عدد محاولات تسجيل الدخول الفاشلة';
COMMENT ON COLUMN distributors.account_locked_until IS 'تاريخ قفل الحساب (إذا تجاوز محاولات تسجيل الدخول)';

-- إضافة فهارس إضافية لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_companies_created_by_distributor_active ON companies(created_by_distributor_id) 
    WHERE created_by_distributor_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_drivers_created_by_distributor_active ON drivers(created_by_distributor_id) 
    WHERE created_by_distributor_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_vehicles_created_by_distributor_active ON vehicles(created_by_distributor_id) 
    WHERE created_by_distributor_id IS NOT NULL;

-- إضافة فهرس مركب لطلبات الموافقة
CREATE INDEX IF NOT EXISTS idx_approval_requests_distributor_status ON approval_requests(distributor_id, status);

-- إضافة فهرس لتسريع استعلامات الفواتير حسب الشركة
CREATE INDEX IF NOT EXISTS idx_invoices_company_status ON invoices(company_id, status);

-- إضافة جدول لتتبع التغييرات المطبقة فعلياً بعد الموافقة
CREATE TABLE approval_execution_log (
    id BIGSERIAL PRIMARY KEY,
    approval_request_id BIGINT NOT NULL,
    executed_by_user_id BIGINT NOT NULL,
    execution_type VARCHAR(50) NOT NULL CHECK (execution_type IN ('update', 'delete', 'restore')),
    entity_type VARCHAR(50) NOT NULL CHECK (entity_type IN ('company', 'vehicle', 'driver', 'invoice', 'expense')),
    entity_id BIGINT NOT NULL,
    previous_data JSONB,
    new_data JSONB,
    execution_status VARCHAR(20) DEFAULT 'success' CHECK (execution_status IN ('success', 'failed', 'rolled_back')),
    error_message TEXT,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_approval_execution_log_request_id ON approval_execution_log(approval_request_id);
CREATE INDEX idx_approval_execution_log_entity ON approval_execution_log(entity_type, entity_id);
CREATE INDEX idx_approval_execution_log_executed_by ON approval_execution_log(executed_by_user_id);
CREATE INDEX idx_approval_execution_log_executed_at ON approval_execution_log(executed_at);
CREATE INDEX idx_approval_execution_log_status ON approval_execution_log(execution_status);

COMMENT ON TABLE approval_execution_log IS 'سجل تنفيذ طلبات الموافقة - يتتبع التغييرات الفعلية المطبقة على البيانات';
COMMENT ON COLUMN approval_execution_log.approval_request_id IS 'معرف طلب الموافقة المرتبط';
COMMENT ON COLUMN approval_execution_log.executed_by_user_id IS 'معرف المسؤول الذي نفذ التغيير';
COMMENT ON COLUMN approval_execution_log.execution_type IS 'نوع التنفيذ: update (تعديل), delete (حذف), restore (استعادة)';
COMMENT ON COLUMN approval_execution_log.entity_type IS 'نوع الكيان المتأثر';
COMMENT ON COLUMN approval_execution_log.entity_id IS 'معرف الكيان';
COMMENT ON COLUMN approval_execution_log.previous_data IS 'البيانات قبل التنفيذ (JSON) - للتراجع إذا لزم الأمر';
COMMENT ON COLUMN approval_execution_log.new_data IS 'البيانات بعد التنفيذ (JSON)';
COMMENT ON COLUMN approval_execution_log.execution_status IS 'حالة التنفيذ: success (نجح), failed (فشل), rolled_back (تم التراجع)';
COMMENT ON COLUMN approval_execution_log.error_message IS 'رسالة الخطأ في حالة الفشل';

-- إضافة حقول إضافية لجدول approval_requests لتسهيل العرض
ALTER TABLE approval_requests ADD COLUMN IF NOT EXISTS entity_name VARCHAR(200);
ALTER TABLE approval_requests ADD COLUMN IF NOT EXISTS priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent'));
ALTER TABLE approval_requests ADD COLUMN IF NOT EXISTS auto_approve_eligible BOOLEAN DEFAULT false;

COMMENT ON COLUMN approval_requests.entity_name IS 'اسم الكيان (مثل: اسم الشركة، رقم لوحة المركبة) - لتسهيل العرض في القائمة';
COMMENT ON COLUMN approval_requests.priority IS 'أولوية الطلب: low (منخفضة), normal (عادية), high (عالية), urgent (عاجلة)';
COMMENT ON COLUMN approval_requests.auto_approve_eligible IS 'هل الطلب مؤهل للموافقة التلقائية (بناءً على قواعد محددة)';

-- إضافة فهارس إضافية لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_approval_requests_priority ON approval_requests(priority);
CREATE INDEX IF NOT EXISTS idx_approval_requests_entity_name ON approval_requests(entity_name);
CREATE INDEX IF NOT EXISTS idx_approval_requests_pending_high_priority ON approval_requests(status, priority) 
    WHERE status = 'pending' AND priority IN ('high', 'urgent');

-- إضافة جدول لقواعد الموافقة التلقائية
CREATE TABLE approval_auto_rules (
    id BIGSERIAL PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL CHECK (entity_type IN ('company', 'vehicle', 'driver', 'invoice', 'expense')),
    request_type VARCHAR(50) NOT NULL CHECK (request_type IN ('update', 'delete')),
    conditions JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_by_user_id BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_approval_auto_rules_entity_type ON approval_auto_rules(entity_type);
CREATE INDEX idx_approval_auto_rules_is_active ON approval_auto_rules(is_active);

COMMENT ON TABLE approval_auto_rules IS 'قواعد الموافقة التلقائية - تحدد متى يمكن الموافقة تلقائياً على طلبات معينة';
COMMENT ON COLUMN approval_auto_rules.rule_name IS 'اسم القاعدة';
COMMENT ON COLUMN approval_auto_rules.entity_type IS 'نوع الكيان المطبق عليه القاعدة';
COMMENT ON COLUMN approval_auto_rules.request_type IS 'نوع الطلب المطبق عليه القاعدة';
COMMENT ON COLUMN approval_auto_rules.conditions IS 'شروط القاعدة (JSON) - مثل: {"field": "amount", "operator": "<", "value": 100}';
COMMENT ON COLUMN approval_auto_rules.is_active IS 'هل القاعدة نشطة';

-- إضافة جدول لإحصائيات طلبات الموافقة
CREATE TABLE approval_statistics (
    id BIGSERIAL PRIMARY KEY,
    distributor_id BIGINT,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    total_requests INTEGER DEFAULT 0,
    approved_requests INTEGER DEFAULT 0,
    rejected_requests INTEGER DEFAULT 0,
    pending_requests INTEGER DEFAULT 0,
    cancelled_requests INTEGER DEFAULT 0,
    average_approval_time_hours NUMERIC(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_approval_statistics_distributor_id ON approval_statistics(distributor_id);
CREATE INDEX idx_approval_statistics_period ON approval_statistics(period_start, period_end);

COMMENT ON TABLE approval_statistics IS 'إحصائيات طلبات الموافقة - لتتبع أداء الموزعين والنظام';
COMMENT ON COLUMN approval_statistics.distributor_id IS 'معرف الموزع (NULL للإحصائيات العامة)';
COMMENT ON COLUMN approval_statistics.period_start IS 'تاريخ بداية الفترة';
COMMENT ON COLUMN approval_statistics.period_end IS 'تاريخ نهاية الفترة';
COMMENT ON COLUMN approval_statistics.average_approval_time_hours IS 'متوسط وقت الموافقة بالساعات';

-- إضافة حقول State Machine لجدول trips لمنع خطأ CH1210
ALTER TABLE trips 
ADD COLUMN chiron_sync_state VARCHAR(20) DEFAULT 'CREATED',
ADD COLUMN start_sync_response JSONB,
ADD COLUMN arrival_sync_response JSONB,
ADD COLUMN start_accepted_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN arrival_sent_at TIMESTAMP WITH TIME ZONE;

-- إضافة قيد للتحقق من حالات المزامنة الصحيحة
ALTER TABLE trips 
ADD CONSTRAINT trips_chiron_sync_state_check 
CHECK (chiron_sync_state IN ('CREATED', 'START_SENT', 'START_ACCEPTED', 'ARRIVAL_SENT', 'COMPLETED', 'FAILED'));

-- إنشاء فهرس لحالة المزامنة لتحسين الأداء
CREATE INDEX idx_trips_chiron_sync_state ON trips(chiron_sync_state);

-- إنشاء فهرس مركب لتتبع الرحلات التي تحتاج إرسال ARRIVAL
CREATE INDEX idx_trips_ready_for_arrival ON trips(chiron_sync_state, start_accepted_at) 
WHERE chiron_sync_state = 'START_ACCEPTED';

-- تحديث التعليقات
COMMENT ON COLUMN trips.chiron_sync_state IS 'حالة المزامنة مع Chiron: CREATED (تم الإنشاء), START_SENT (تم إرسال START), START_ACCEPTED (تم قبول START من Chiron), ARRIVAL_SENT (تم إرسال ARRIVAL), COMPLETED (مكتملة), FAILED (فشلت)';
COMMENT ON COLUMN trips.start_sync_response IS 'استجابة Chiron الكاملة لرسالة START (JSON) - يجب التحقق من HTTP 2xx قبل الانتقال لـ START_ACCEPTED';
COMMENT ON COLUMN trips.arrival_sync_response IS 'استجابة Chiron الكاملة لرسالة ARRIVAL (JSON)';
COMMENT ON COLUMN trips.start_accepted_at IS 'تاريخ ووقت قبول START من Chiron - يجب أن يكون موجوداً قبل إرسال ARRIVAL';
COMMENT ON COLUMN trips.arrival_sent_at IS 'تاريخ ووقت إرسال ARRIVAL إلى Chiron';

-- جدول قواعد التحقق من صحة البيانات لـ Chiron API
CREATE TABLE chiron_validation_rules (
    id BIGSERIAL PRIMARY KEY,
    field_name VARCHAR(100) NOT NULL UNIQUE,
    field_type VARCHAR(50) NOT NULL,
    min_decimal_places INTEGER,
    max_decimal_places INTEGER,
    min_value NUMERIC(20,10),
    max_value NUMERIC(20,10),
    regex_pattern TEXT,
    is_required BOOLEAN DEFAULT true,
    error_code VARCHAR(20),
    validation_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chiron_validation_rules_field_type_check 
        CHECK (field_type IN ('decimal', 'integer', 'string', 'coordinate', 'datetime'))
);

COMMENT ON TABLE chiron_validation_rules IS 'قواعد التحقق من صحة البيانات المرسلة إلى Chiron API - تضمن التنسيق الصحيح لجميع الحقول';
COMMENT ON COLUMN chiron_validation_rules.field_name IS 'اسم الحقل في Chiron API (مثل: afstand، kostprijs، breedtegraad)';
COMMENT ON COLUMN chiron_validation_rules.field_type IS 'نوع البيانات: decimal (عشري)، integer (صحيح)، string (نص)، coordinate (إحداثيات)، datetime (تاريخ ووقت)';
COMMENT ON COLUMN chiron_validation_rules.min_decimal_places IS 'الحد الأدنى لعدد الخانات العشرية المطلوبة';
COMMENT ON COLUMN chiron_validation_rules.max_decimal_places IS 'الحد الأقصى لعدد الخانات العشرية المسموح بها';
COMMENT ON COLUMN chiron_validation_rules.min_value IS 'القيمة الدنيا المسموح بها';
COMMENT ON COLUMN chiron_validation_rules.max_value IS 'القيمة القصوى المسموح بها';
COMMENT ON COLUMN chiron_validation_rules.regex_pattern IS 'نمط التحقق من صحة النص (Regular Expression)';
COMMENT ON COLUMN chiron_validation_rules.error_code IS 'رمز الخطأ من Chiron (مثل: CH1205، CH1208)';
COMMENT ON COLUMN chiron_validation_rules.validation_message IS 'رسالة التحقق من الصحة بالعربية';

CREATE INDEX idx_chiron_validation_rules_field_name ON chiron_validation_rules(field_name);
CREATE INDEX idx_chiron_validation_rules_error_code ON chiron_validation_rules(error_code);

-- إدراج قواعد التحقق الأساسية من الدليل التقني
INSERT INTO chiron_validation_rules (field_name, field_type, min_decimal_places, max_decimal_places, min_value, max_value, error_code, validation_message) VALUES
('afstand', 'decimal', 0, 3, 0, 9999.999, 'CH1205', 'المسافة يجب أن تحتوي على 3 خانات عشرية كحد أقصى'),
('kostprijs', 'decimal', 0, 2, 0, 99999.99, 'CH1205', 'التكلفة يجب أن تحتوي على خانتين عشريتين كحد أقصى'),
('breedtegraad_vertrek', 'coordinate', 3, 8, 49.0, 52.0, 'CH1208', 'خط العرض لنقطة البداية يجب أن يحتوي على 3 خانات عشرية على الأقل'),
('lengtegraad_vertrek', 'coordinate', 3, 8, 2.0, 7.0, 'CH1208', 'خط الطول لنقطة البداية يجب أن يحتوي على 3 خانات عشرية على الأقل'),
('breedtegraad_aankomst', 'coordinate', 3, 8, 49.0, 52.0, 'CH1208', 'خط العرض لنقطة الوصول يجب أن يحتوي على 3 خانات عشرية على الأقل'),
('lengtegraad_aankomst', 'coordinate', 3, 8, 2.0, 7.0, 'CH1208', 'خط الطول لنقطة الوصول يجب أن يحتوي على 3 خانات عشرية على الأقل'),
('ritnummer', 'string', NULL, NULL, NULL, NULL, 'CH1201', 'رقم الرحلة مطلوب ويجب أن يكون فريداً'),
('kbo_nummer', 'string', NULL, NULL, NULL, NULL, 'CH1202', 'رقم KBO مطلوب ويجب أن يكون صحيحاً'),
('nummerplaat', 'string', NULL, NULL, NULL, NULL, 'CH1203', 'رقم لوحة المركبة مطلوب'),
('capaciteitsbewijs', 'string', NULL, NULL, NULL, NULL, 'CH1204', 'رقم شهادة القدرة للسائق مطلوب');

-- جدول رموز أخطاء Chiron وحلولها
CREATE TABLE chiron_error_codes (
    id BIGSERIAL PRIMARY KEY,
    error_code VARCHAR(20) NOT NULL UNIQUE,
    error_category VARCHAR(50) NOT NULL,
    error_description_nl TEXT NOT NULL,
    error_description_ar TEXT NOT NULL,
    solution_steps TEXT NOT NULL,
    prevention_tips TEXT,
    is_critical BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chiron_error_codes_category_check 
        CHECK (error_category IN ('validation', 'authentication', 'business_logic', 'technical', 'data_format'))
);

COMMENT ON TABLE chiron_error_codes IS 'قاعدة بيانات شاملة لجميع رموز أخطاء Chiron API مع الحلول والوقاية';
COMMENT ON COLUMN chiron_error_codes.error_code IS 'رمز الخطأ من Chiron (مثل: CH1205، CH1208، CH1210)';
COMMENT ON COLUMN chiron_error_codes.error_category IS 'تصنيف الخطأ: validation (تحقق من الصحة)، authentication (مصادقة)، business_logic (منطق الأعمال)، technical (تقني)، data_format (تنسيق البيانات)';
COMMENT ON COLUMN chiron_error_codes.error_description_nl IS 'وصف الخطأ بالهولندية (من الدليل التقني)';
COMMENT ON COLUMN chiron_error_codes.error_description_ar IS 'وصف الخطأ بالعربية';
COMMENT ON COLUMN chiron_error_codes.solution_steps IS 'خطوات الحل التفصيلية';
COMMENT ON COLUMN chiron_error_codes.prevention_tips IS 'نصائح لتجنب الخطأ في المستقبل';
COMMENT ON COLUMN chiron_error_codes.is_critical IS 'هل الخطأ حرج ويمنع إكمال العملية';

CREATE INDEX idx_chiron_error_codes_error_code ON chiron_error_codes(error_code);
CREATE INDEX idx_chiron_error_codes_category ON chiron_error_codes(error_category);
CREATE INDEX idx_chiron_error_codes_is_critical ON chiron_error_codes(is_critical);

-- إدراج رموز الأخطاء الشائعة من الدليل التقني
INSERT INTO chiron_error_codes (error_code, error_category, error_description_nl, error_description_ar, solution_steps, prevention_tips, is_critical) VALUES
('CH1205', 'data_format', 'De afstand/kostprijs mag niet meer dan X decimalen bevatten', 'المسافة/التكلفة يجب ألا تحتوي على أكثر من X خانات عشرية', '1. تقريب المسافة إلى 3 خانات عشرية\n2. تقريب التكلفة إلى خانتين عشريتين\n3. استخدام ROUND() في SQL أو toFixed() في JavaScript', 'استخدم دائماً دوال التقريب قبل إرسال البيانات إلى Chiron', true),
('CH1208', 'data_format', 'De breedtegraad/lengtegraad moet minimaal X decimalen bevatten', 'خط العرض/الطول يجب أن يحتوي على X خانات عشرية على الأقل', '1. تأكد من أن الإحداثيات تحتوي على 3 خانات عشرية على الأقل\n2. إذا كانت أقل، أضف أصفار في النهاية\n3. تحقق من دقة GPS', 'احفظ الإحداثيات بدقة 8 خانات عشرية في قاعدة البيانات، وأرسل 3-6 خانات إلى Chiron', true),
('CH1210', 'business_logic', 'Er is al een AANKOMST bericht verstuurd voor dit ritnummer', 'تم إرسال رسالة AANKOMST مسبقاً لهذا الرقم', '1. تحقق من حالة الرحلة في قاعدة البيانات\n2. لا ترسل AANKOMST مرتين لنفس الرحلة\n3. استخدم جدول trip_state_transitions للتتبع', 'استخدم حقل chiron_sync_state في جدول trips لتتبع حالة الرحلة ومنع الإرسال المكرر', true),
('CH1201', 'validation', 'Ritnummer is verplicht', 'رقم الرحلة مطلوب', '1. تأكد من وجود ritnummer قبل الإرسال\n2. استخدم تنسيق فريد (مثل: COMPANY_ID-TIMESTAMP-RANDOM)', 'أنشئ ritnummer تلقائياً عند إنشاء الرحلة', true),
('CH1202', 'validation', 'KBO nummer is ongeldig', 'رقم KBO غير صحيح', '1. تحقق من صحة رقم KBO في جدول companies\n2. تأكد من أن الرقم يتبع التنسيق البلجيكي الصحيح', 'احفظ رقم KBO الصحيح في جدول companies عند التسجيل', true),
('CH1203', 'validation', 'Nummerplaat is verplicht', 'رقم لوحة المركبة مطلوب', '1. تأكد من وجود plate_number في جدول vehicles\n2. تحقق من أن المركبة مسجلة في Chiron', 'تحقق من تسجيل المركبة في Chiron قبل استخدامها في الرحلات', true),
('CH1204', 'validation', 'Capaciteitsbewijs is verplicht', 'رقم شهادة القدرة للسائق مطلوب', '1. تأكد من وجود capacity_certificate_number في جدول drivers\n2. تحقق من صلاحية الشهادة', 'احفظ رقم شهادة القدرة عند تسجيل السائق', true),
('CH1401', 'authentication', 'Access token is verlopen', 'انتهت صلاحية Access Token', '1. احصل على token جديد من OAuth endpoint\n2. حدّث chiron_tokens table\n3. أعد إرسال الطلب', 'تحقق من صلاحية Token قبل كل طلب، وجدده تلقائياً إذا كان قريباً من الانتهاء', true),
('CH1402', 'authentication', 'Client credentials zijn ongeldig', 'بيانات اعتماد العميل غير صحيحة', '1. تحقق من client_id و client_secret في جدول companies\n2. تأكد من استخدام البيانات الصحيحة للبيئة (test/production)', 'احفظ بيانات الاعتماد بشكل آمن ولا تشاركها', true);

-- جدول لتتبع محاولات التحقق من الصحة
CREATE TABLE chiron_validation_log (
    id BIGSERIAL PRIMARY KEY,
    trip_id BIGINT,
    test_trip_id BIGINT,
    validation_type VARCHAR(50) NOT NULL,
    field_name VARCHAR(100) NOT NULL,
    field_value TEXT,
    is_valid BOOLEAN NOT NULL,
    validation_error TEXT,
    error_code VARCHAR(20),
    corrected_value TEXT,
    validated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chiron_validation_log_validation_type_check 
        CHECK (validation_type IN ('pre_send', 'post_error', 'manual_check'))
);

COMMENT ON TABLE chiron_validation_log IS 'سجل جميع عمليات التحقق من صحة البيانات قبل إرسالها إلى Chiron';
COMMENT ON COLUMN chiron_validation_log.trip_id IS 'معرف الرحلة الحقيقية (NULL للرحلات الاختبارية)';
COMMENT ON COLUMN chiron_validation_log.test_trip_id IS 'معرف الرحلة الاختبارية (NULL للرحلات الحقيقية)';
COMMENT ON COLUMN chiron_validation_log.validation_type IS 'نوع التحقق: pre_send (قبل الإرسال)، post_error (بعد الخطأ)، manual_check (فحص يدوي)';
COMMENT ON COLUMN chiron_validation_log.field_name IS 'اسم الحقل الذي تم التحقق منه';
COMMENT ON COLUMN chiron_validation_log.field_value IS 'القيمة الأصلية للحقل';
COMMENT ON COLUMN chiron_validation_log.is_valid IS 'هل القيمة صحيحة';
COMMENT ON COLUMN chiron_validation_log.validation_error IS 'رسالة الخطأ إذا كانت القيمة غير صحيحة';
COMMENT ON COLUMN chiron_validation_log.error_code IS 'رمز الخطأ المتوقع من Chiron';
COMMENT ON COLUMN chiron_validation_log.corrected_value IS 'القيمة المصححة (بعد التقريب أو التعديل)';

CREATE INDEX idx_chiron_validation_log_trip_id ON chiron_validation_log(trip_id);
CREATE INDEX idx_chiron_validation_log_test_trip_id ON chiron_validation_log(test_trip_id);
CREATE INDEX idx_chiron_validation_log_is_valid ON chiron_validation_log(is_valid);
CREATE INDEX idx_chiron_validation_log_error_code ON chiron_validation_log(error_code);
CREATE INDEX idx_chiron_validation_log_validated_at ON chiron_validation_log(validated_at);

-- دالة للتحقق من صحة الأرقام العشرية وتقريبها
CREATE OR REPLACE FUNCTION validate_and_round_decimal(
    p_value NUMERIC,
    p_field_name VARCHAR,
    p_max_decimals INTEGER
) RETURNS NUMERIC AS $$
DECLARE
    v_rounded_value NUMERIC;
BEGIN
    -- تقريب القيمة إلى العدد المطلوب من الخانات العشرية
    v_rounded_value := ROUND(p_value, p_max_decimals);
    
    RETURN v_rounded_value;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION validate_and_round_decimal IS 'دالة للتحقق من صحة الأرقام العشرية وتقريبها حسب متطلبات Chiron API';

-- دالة للتحقق من صحة الإحداثيات
CREATE OR REPLACE FUNCTION validate_coordinate(
    p_value NUMERIC,
    p_field_name VARCHAR,
    p_min_decimals INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_decimal_places INTEGER;
    v_value_text TEXT;
BEGIN
    -- تحويل القيمة إلى نص للتحقق من عدد الخانات العشرية
    v_value_text := p_value::TEXT;
    
    -- حساب عدد الخانات العشرية
    IF POSITION('.' IN v_value_text) > 0 THEN
        v_decimal_places := LENGTH(v_value_text) - POSITION('.' IN v_value_text);
    ELSE
        v_decimal_places := 0;
    END IF;
    
    -- التحقق من أن عدد الخانات العشرية يساوي أو أكبر من الحد الأدنى
    RETURN v_decimal_places >= p_min_decimals;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION validate_coordinate IS 'دالة للتحقق من أن الإحداثيات تحتوي على العدد المطلوب من الخانات العشرية';

-- تحديث جدول trips لإضافة حقول التحقق من الصحة
ALTER TABLE trips ADD COLUMN IF NOT EXISTS validation_status VARCHAR(20) DEFAULT 'pending';
ALTER TABLE trips ADD COLUMN IF NOT EXISTS validation_errors JSONB DEFAULT '[]'::jsonb;
ALTER TABLE trips ADD COLUMN IF NOT EXISTS last_validation_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN trips.validation_status IS 'حالة التحقق من صحة البيانات: pending (قيد الانتظار)، valid (صحيح)، invalid (غير صحيح)، corrected (تم التصحيح)';
COMMENT ON COLUMN trips.validation_errors IS 'قائمة أخطاء التحقق من الصحة (JSON)';
COMMENT ON COLUMN trips.last_validation_at IS 'تاريخ آخر عملية تحقق من الصحة';

CREATE INDEX idx_trips_validation_status ON trips(validation_status);

-- تحديث جدول test_trips لإضافة حقول التحقق من الصحة
ALTER TABLE test_trips ADD COLUMN IF NOT EXISTS validation_status VARCHAR(20) DEFAULT 'pending';
ALTER TABLE test_trips ADD COLUMN IF NOT EXISTS validation_errors JSONB DEFAULT '[]'::jsonb;
ALTER TABLE test_trips ADD COLUMN IF NOT EXISTS last_validation_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN test_trips.validation_status IS 'حالة التحقق من صحة البيانات: pending (قيد الانتظار)، valid (صحيح)، invalid (غير صحيح)، corrected (تم التصحيح)';
COMMENT ON COLUMN test_trips.validation_errors IS 'قائمة أخطاء التحقق من الصحة (JSON)';
COMMENT ON COLUMN test_trips.last_validation_at IS 'تاريخ آخر عملية تحقق من الصحة';

CREATE INDEX idx_test_trips_validation_status ON test_trips(validation_status);

-- جدول لتخزين إعدادات Chiron API لكل بيئة
CREATE TABLE chiron_api_config (
    id BIGSERIAL PRIMARY KEY,
    environment VARCHAR(20) NOT NULL,
    config_key VARCHAR(100) NOT NULL,
    config_value TEXT NOT NULL,
    config_type VARCHAR(50) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chiron_api_config_environment_check 
        CHECK (environment IN ('test', 'production')),
    CONSTRAINT chiron_api_config_config_type_check 
        CHECK (config_type IN ('url', 'timeout', 'retry', 'validation', 'format')),
    UNIQUE(environment, config_key)
);

COMMENT ON TABLE chiron_api_config IS 'إعدادات Chiron API لكل بيئة (test/production) - يمكن تعديلها دون تغيير الكود';
COMMENT ON COLUMN chiron_api_config.environment IS 'البيئة: test (اختبار) أو production (إنتاج)';
COMMENT ON COLUMN chiron_api_config.config_key IS 'مفتاح الإعداد (مثل: max_retry_attempts، request_timeout)';
COMMENT ON COLUMN chiron_api_config.config_value IS 'قيمة الإعداد';
COMMENT ON COLUMN chiron_api_config.config_type IS 'نوع الإعداد: url، timeout، retry، validation، format';
COMMENT ON COLUMN chiron_api_config.description IS 'وصف الإعداد';

CREATE INDEX idx_chiron_api_config_environment ON chiron_api_config(environment);
CREATE INDEX idx_chiron_api_config_config_key ON chiron_api_config(config_key);
CREATE INDEX idx_chiron_api_config_is_active ON chiron_api_config(is_active);

-- إدراج الإعدادات الافتراضية
INSERT INTO chiron_api_config (environment, config_key, config_value, config_type, description) VALUES
('test', 'max_retry_attempts', '3', 'retry', 'الحد الأقصى لمحاولات إعادة الإرسال في بيئة الاختبار'),
('test', 'request_timeout_seconds', '30', 'timeout', 'مهلة الطلب بالثواني في بيئة الاختبار'),
('test', 'retry_delay_seconds', '5', 'retry', 'التأخير بين محاولات إعادة الإرسال بالثواني'),
('test', 'distance_decimal_places', '3', 'validation', 'عدد الخانات العشرية للمسافة'),
('test', 'price_decimal_places', '2', 'validation', 'عدد الخانات العشرية للسعر'),
('test', 'coordinate_min_decimal_places', '3', 'validation', 'الحد الأدنى لعدد الخانات العشرية للإحداثيات'),
('production', 'max_retry_attempts', '5', 'retry', 'الحد الأقصى لمحاولات إعادة الإرسال في بيئة الإنتاج'),
('production', 'request_timeout_seconds', '45', 'timeout', 'مهلة الطلب بالثواني في بيئة الإنتاج'),
('production', 'retry_delay_seconds', '10', 'retry', 'التأخير بين محاولات إعادة الإرسال بالثواني'),
('production', 'distance_decimal_places', '3', 'validation', 'عدد الخانات العشرية للمسافة'),
('production', 'price_decimal_places', '2', 'validation', 'عدد الخانات العشرية للسعر'),
('production', 'coordinate_min_decimal_places', '3', 'validation', 'الحد الأدنى لعدد الخانات العشرية للإحداثيات');

-- إضافة حقول التحقق من الصحة إلى جدول trips
ALTER TABLE trips 
ADD COLUMN IF NOT EXISTS validation_status VARCHAR(20) DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS validation_errors JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS last_validation_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN trips.validation_status IS 'حالة التحقق من صحة البيانات: pending (قيد الانتظار)، valid (صحيح)، invalid (غير صحيح)، corrected (تم التصحيح)';
COMMENT ON COLUMN trips.validation_errors IS 'قائمة أخطاء التحقق من الصحة (JSON)';
COMMENT ON COLUMN trips.last_validation_at IS 'تاريخ آخر عملية تحقق من الصحة';

CREATE INDEX IF NOT EXISTS idx_trips_validation_status ON trips(validation_status);

-- إضافة حقول التحقق من الصحة إلى جدول test_trips
ALTER TABLE test_trips 
ADD COLUMN IF NOT EXISTS validation_status VARCHAR(20) DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS validation_errors JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS last_validation_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN test_trips.validation_status IS 'حالة التحقق من صحة البيانات: pending (قيد الانتظار)، valid (صحيح)، invalid (غير صحيح)، corrected (تم التصحيح)';
COMMENT ON COLUMN test_trips.validation_errors IS 'قائمة أخطاء التحقق من الصحة (JSON)';
COMMENT ON COLUMN test_trips.last_validation_at IS 'تاريخ آخر عملية تحقق من الصحة';

CREATE INDEX IF NOT EXISTS idx_test_trips_validation_status ON test_trips(validation_status);

-- جدول قواعد التحقق من صحة البيانات
CREATE TABLE IF NOT EXISTS chiron_validation_rules (
    id BIGSERIAL PRIMARY KEY,
    field_name VARCHAR(100) NOT NULL UNIQUE,
    field_type VARCHAR(50) NOT NULL CHECK (field_type IN ('decimal', 'integer', 'string', 'coordinate', 'datetime')),
    min_decimal_places INTEGER,
    max_decimal_places INTEGER,
    min_value NUMERIC(20,10),
    max_value NUMERIC(20,10),
    regex_pattern TEXT,
    is_required BOOLEAN DEFAULT true,
    error_code VARCHAR(20),
    validation_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE chiron_validation_rules IS 'قواعد التحقق من صحة البيانات المرسلة إلى Chiron API - تضمن التنسيق الصحيح لجميع الحقول';
COMMENT ON COLUMN chiron_validation_rules.field_name IS 'اسم الحقل في Chiron API (مثل: afstand، kostprijs، breedtegraad)';
COMMENT ON COLUMN chiron_validation_rules.field_type IS 'نوع البيانات: decimal (عشري)، integer (صحيح)، string (نص)، coordinate (إحداثيات)، datetime (تاريخ ووقت)';
COMMENT ON COLUMN chiron_validation_rules.min_decimal_places IS 'الحد الأدنى لعدد الخانات العشرية المطلوبة';
COMMENT ON COLUMN chiron_validation_rules.max_decimal_places IS 'الحد الأقصى لعدد الخانات العشرية المسموح بها';
COMMENT ON COLUMN chiron_validation_rules.min_value IS 'القيمة الدنيا المسموح بها';
COMMENT ON COLUMN chiron_validation_rules.max_value IS 'القيمة القصوى المسموح بها';
COMMENT ON COLUMN chiron_validation_rules.regex_pattern IS 'نمط التحقق من صحة النص (Regular Expression)';
COMMENT ON COLUMN chiron_validation_rules.error_code IS 'رمز الخطأ من Chiron (مثل: CH1205، CH1208)';
COMMENT ON COLUMN chiron_validation_rules.validation_message IS 'رسالة التحقق من الصحة بالعربية';

CREATE INDEX IF NOT EXISTS idx_chiron_validation_rules_field_name ON chiron_validation_rules(field_name);
CREATE INDEX IF NOT EXISTS idx_chiron_validation_rules_error_code ON chiron_validation_rules(error_code);

-- إدراج قواعد التحقق الأساسية بناءً على أخطاء CH1205 و CH1208
INSERT INTO chiron_validation_rules (field_name, field_type, min_decimal_places, max_decimal_places, error_code, validation_message) VALUES
('breedtegraad_vertrek', 'coordinate', 3, 8, 'CH1205', 'خط العرض لنقطة الانطلاق يجب أن يحتوي على 3 خانات عشرية على الأقل'),
('lengtegraad_vertrek', 'coordinate', 3, 8, 'CH1205', 'خط الطول لنقطة الانطلاق يجب أن يحتوي على 3 خانات عشرية على الأقل'),
('breedtegraad_aankomst', 'coordinate', 3, 8, 'CH1208', 'خط العرض لنقطة الوصول يجب أن يحتوي على 3 خانات عشرية على الأقل'),
('lengtegraad_aankomst', 'coordinate', 3, 8, 'CH1208', 'خط الطول لنقطة الوصول يجب أن يحتوي على 3 خانات عشرية على الأقل'),
('kostprijs', 'decimal', 0, 2, 'CH1XXX', 'التكلفة يجب ألا تحتوي على أكثر من خانتين عشريتين'),
('afstand', 'decimal', 0, 2, 'CH1XXX', 'المسافة يجب ألا تحتوي على أكثر من خانتين عشريتين')
ON CONFLICT (field_name) DO NOTHING;

-- جدول قاعدة بيانات أخطاء Chiron
CREATE TABLE IF NOT EXISTS chiron_error_codes (
    id BIGSERIAL PRIMARY KEY,
    error_code VARCHAR(20) NOT NULL UNIQUE,
    error_category VARCHAR(50) NOT NULL CHECK (error_category IN ('validation', 'authentication', 'business_logic', 'technical', 'data_format')),
    error_description_nl TEXT NOT NULL,
    error_description_ar TEXT NOT NULL,
    solution_steps TEXT NOT NULL,
    prevention_tips TEXT,
    is_critical BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE chiron_error_codes IS 'قاعدة بيانات شاملة لجميع رموز أخطاء Chiron API مع الحلول والوقاية';
COMMENT ON COLUMN chiron_error_codes.error_code IS 'رمز الخطأ من Chiron (مثل: CH1205، CH1208، CH1210)';
COMMENT ON COLUMN chiron_error_codes.error_category IS 'تصنيف الخطأ: validation (تحقق من الصحة)، authentication (مصادقة)، business_logic (منطق الأعمال)، technical (تقني)، data_format (تنسيق البيانات)';
COMMENT ON COLUMN chiron_error_codes.error_description_nl IS 'وصف الخطأ بالهولندية (من الدليل التقني)';
COMMENT ON COLUMN chiron_error_codes.error_description_ar IS 'وصف الخطأ بالعربية';
COMMENT ON COLUMN chiron_error_codes.solution_steps IS 'خطوات الحل التفصيلية';
COMMENT ON COLUMN chiron_error_codes.prevention_tips IS 'نصائح لتجنب الخطأ في المستقبل';
COMMENT ON COLUMN chiron_error_codes.is_critical IS 'هل الخطأ حرج ويمنع إكمال العملية';

CREATE INDEX IF NOT EXISTS idx_chiron_error_codes_error_code ON chiron_error_codes(error_code);
CREATE INDEX IF NOT EXISTS idx_chiron_error_codes_category ON chiron_error_codes(error_category);
CREATE INDEX IF NOT EXISTS idx_chiron_error_codes_is_critical ON chiron_error_codes(is_critical);

-- إدراج أخطاء CH1205 و CH1208
INSERT INTO chiron_error_codes (error_code, error_category, error_description_nl, error_description_ar, solution_steps, prevention_tips, is_critical) VALUES
('CH1205', 'data_format', 'De breedtegraad voor het vertrekpunt moet minimaal 3 decimalen bevatten.', 'خط العرض لنقطة الانطلاق يجب أن يحتوي على 3 خانات عشرية على الأقل', '1. تحقق من قيمة breedtegraad_vertrek\n2. تأكد من وجود 3 خانات عشرية على الأقل\n3. استخدم ROUND(latitude, 3) للتقريب\n4. مثال صحيح: 50.850 بدلاً من 50.85', 'استخدم دائماً 3-8 خانات عشرية للإحداثيات الجغرافية', true),
('CH1208', 'data_format', 'De breedtegraad voor het aankomstpunt moet minimaal 3 decimalen bevatten.', 'خط العرض لنقطة الوصول يجب أن يحتوي على 3 خانات عشرية على الأقل', '1. تحقق من قيمة breedtegraad_aankomst\n2. تأكد من وجود 3 خانات عشرية على الأقل\n3. استخدم ROUND(latitude, 3) للتقريب\n4. مثال صحيح: 50.850 بدلاً من 50.85', 'استخدم دائماً 3-8 خانات عشرية للإحداثيات الجغرافية', true),
('CH1210', 'business_logic', 'Er is al een aankomstbericht verstuurd voor dit ritnummer.', 'تم إرسال رسالة وصول مسبقاً لهذا الرقم', '1. تحقق من حالة الرحلة في قاعدة البيانات\n2. لا ترسل AANKOMST إلا بعد نجاح VERTREK\n3. استخدم trip_state_transitions للتحقق من الحالة', 'تتبع حالة كل رحلة بدقة ولا ترسل رسائل مكررة', true)
ON CONFLICT (error_code) DO NOTHING;

-- جدول سجل التحقق من الصحة
CREATE TABLE IF NOT EXISTS chiron_validation_log (
    id BIGSERIAL PRIMARY KEY,
    trip_id BIGINT,
    test_trip_id BIGINT,
    validation_type VARCHAR(50) NOT NULL CHECK (validation_type IN ('pre_send', 'post_error', 'manual_check')),
    field_name VARCHAR(100) NOT NULL,
    field_value TEXT,
    is_valid BOOLEAN NOT NULL,
    validation_error TEXT,
    error_code VARCHAR(20),
    corrected_value TEXT,
    validated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE chiron_validation_log IS 'سجل جميع عمليات التحقق من صحة البيانات قبل إرسالها إلى Chiron';
COMMENT ON COLUMN chiron_validation_log.trip_id IS 'معرف الرحلة الحقيقية (NULL للرحلات الاختبارية)';
COMMENT ON COLUMN chiron_validation_log.test_trip_id IS 'معرف الرحلة الاختبارية (NULL للرحلات الحقيقية)';
COMMENT ON COLUMN chiron_validation_log.validation_type IS 'نوع التحقق: pre_send (قبل الإرسال)، post_error (بعد الخطأ)، manual_check (فحص يدوي)';
COMMENT ON COLUMN chiron_validation_log.field_name IS 'اسم الحقل الذي تم التحقق منه';
COMMENT ON COLUMN chiron_validation_log.field_value IS 'القيمة الأصلية للحقل';
COMMENT ON COLUMN chiron_validation_log.is_valid IS 'هل القيمة صحيحة';
COMMENT ON COLUMN chiron_validation_log.validation_error IS 'رسالة الخطأ إذا كانت القيمة غير صحيحة';
COMMENT ON COLUMN chiron_validation_log.error_code IS 'رمز الخطأ المتوقع من Chiron';
COMMENT ON COLUMN chiron_validation_log.corrected_value IS 'القيمة المصححة (بعد التقريب أو التعديل)';

CREATE INDEX IF NOT EXISTS idx_chiron_validation_log_trip_id ON chiron_validation_log(trip_id);
CREATE INDEX IF NOT EXISTS idx_chiron_validation_log_test_trip_id ON chiron_validation_log(test_trip_id);
CREATE INDEX IF NOT EXISTS idx_chiron_validation_log_is_valid ON chiron_validation_log(is_valid);
CREATE INDEX IF NOT EXISTS idx_chiron_validation_log_error_code ON chiron_validation_log(error_code);
CREATE INDEX IF NOT EXISTS idx_chiron_validation_log_validated_at ON chiron_validation_log(validated_at);

-- جدول إعدادات Chiron API
CREATE TABLE IF NOT EXISTS chiron_api_config (
    id BIGSERIAL PRIMARY KEY,
    environment VARCHAR(20) NOT NULL CHECK (environment IN ('test', 'production')),
    config_key VARCHAR(100) NOT NULL,
    config_value TEXT NOT NULL,
    config_type VARCHAR(50) NOT NULL CHECK (config_type IN ('url', 'timeout', 'retry', 'validation', 'format')),
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(environment, config_key)
);

COMMENT ON TABLE chiron_api_config IS 'إعدادات Chiron API لكل بيئة (test/production) - يمكن تعديلها دون تغيير الكود';
COMMENT ON COLUMN chiron_api_config.environment IS 'البيئة: test (اختبار) أو production (إنتاج)';
COMMENT ON COLUMN chiron_api_config.config_key IS 'مفتاح الإعداد (مثل: max_retry_attempts، request_timeout)';
COMMENT ON COLUMN chiron_api_config.config_value IS 'قيمة الإعداد';
COMMENT ON COLUMN chiron_api_config.config_type IS 'نوع الإعداد: url، timeout، retry، validation، format';
COMMENT ON COLUMN chiron_api_config.description IS 'وصف الإعداد';

CREATE INDEX IF NOT EXISTS idx_chiron_api_config_environment ON chiron_api_config(environment);
CREATE INDEX IF NOT EXISTS idx_chiron_api_config_config_key ON chiron_api_config(config_key);
CREATE INDEX IF NOT EXISTS idx_chiron_api_config_is_active ON chiron_api_config(is_active);

-- إدراج إعدادات افتراضية
INSERT INTO chiron_api_config (environment, config_key, config_value, config_type, description) VALUES
('test', 'max_retry_attempts', '3', 'retry', 'الحد الأقصى لمحاولات إعادة الإرسال'),
('test', 'request_timeout_seconds', '30', 'timeout', 'مهلة الطلب بالثواني'),
('test', 'coordinate_decimal_places', '3', 'validation', 'الحد الأدنى للخانات العشرية للإحداثيات'),
('test', 'price_decimal_places', '2', 'validation', 'الحد الأقصى للخانات العشرية للسعر'),
('production', 'max_retry_attempts', '3', 'retry', 'الحد الأقصى لمحاولات إعادة الإرسال'),
('production', 'request_timeout_seconds', '30', 'timeout', 'مهلة الطلب بالثواني'),
('production', 'coordinate_decimal_places', '3', 'validation', 'الحد الأدنى للخانات العشرية للإحداثيات'),
('production', 'price_decimal_places', '2', 'validation', 'الحد الأقصى للخانات العشرية للسعر')
ON CONFLICT (environment, config_key) DO NOTHING;

-- جدول قواعد التحقق من صحة البيانات لـ Chiron API
CREATE TABLE chiron_validation_rules (
    id BIGSERIAL PRIMARY KEY,
    field_name VARCHAR(100) NOT NULL UNIQUE,
    field_type VARCHAR(50) NOT NULL CHECK (field_type IN ('decimal', 'integer', 'string', 'coordinate', 'datetime')),
    min_decimal_places INTEGER,
    max_decimal_places INTEGER,
    min_value NUMERIC(20,10),
    max_value NUMERIC(20,10),
    regex_pattern TEXT,
    is_required BOOLEAN DEFAULT true,
    error_code VARCHAR(20),
    validation_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chiron_validation_rules_field_name ON chiron_validation_rules(field_name);
CREATE INDEX idx_chiron_validation_rules_error_code ON chiron_validation_rules(error_code);

COMMENT ON TABLE chiron_validation_rules IS 'قواعد التحقق من صحة البيانات المرسلة إلى Chiron API - تضمن التنسيق الصحيح لجميع الحقول';
COMMENT ON COLUMN chiron_validation_rules.field_name IS 'اسم الحقل في Chiron API (مثل: afstand، kostprijs، breedtegraad)';
COMMENT ON COLUMN chiron_validation_rules.field_type IS 'نوع البيانات: decimal (عشري)، integer (صحيح)، string (نص)، coordinate (إحداثيات)، datetime (تاريخ ووقت)';
COMMENT ON COLUMN chiron_validation_rules.min_decimal_places IS 'الحد الأدنى لعدد الخانات العشرية المطلوبة';
COMMENT ON COLUMN chiron_validation_rules.max_decimal_places IS 'الحد الأقصى لعدد الخانات العشرية المسموح بها';
COMMENT ON COLUMN chiron_validation_rules.min_value IS 'القيمة الدنيا المسموح بها';
COMMENT ON COLUMN chiron_validation_rules.max_value IS 'القيمة القصوى المسموح بها';
COMMENT ON COLUMN chiron_validation_rules.regex_pattern IS 'نمط التحقق من صحة النص (Regular Expression)';
COMMENT ON COLUMN chiron_validation_rules.error_code IS 'رمز الخطأ من Chiron (مثل: CH1205، CH1208)';
COMMENT ON COLUMN chiron_validation_rules.validation_message IS 'رسالة التحقق من الصحة بالعربية';

-- إدراج قواعد التحقق الأساسية بناءً على أخطاء CH1205 و CH1208
INSERT INTO chiron_validation_rules (field_name, field_type, min_decimal_places, max_decimal_places, error_code, validation_message) VALUES
('vertrek_breedtegraad', 'coordinate', 3, 8, 'CH1205', 'خط العرض لنقطة الانطلاق يجب أن يحتوي على 3 خانات عشرية على الأقل'),
('vertrek_lengtegraad', 'coordinate', 3, 8, 'CH1205', 'خط الطول لنقطة الانطلاق يجب أن يحتوي على 3 خانات عشرية على الأقل'),
('aankomst_breedtegraad', 'coordinate', 3, 8, 'CH1208', 'خط العرض لنقطة الوصول يجب أن يحتوي على 3 خانات عشرية على الأقل'),
('aankomst_lengtegraad', 'coordinate', 3, 8, 'CH1208', 'خط الطول لنقطة الوصول يجب أن يحتوي على 3 خانات عشرية على الأقل'),
('afstand', 'decimal', 3, 3, 'CH1206', 'المسافة يجب أن تحتوي على 3 خانات عشرية بالضبط'),
('kostprijs', 'decimal', 2, 2, 'CH1207', 'السعر يجب أن يحتوي على خانتين عشريتين بالضبط');

-- جدول سجل التحقق من صحة البيانات
CREATE TABLE chiron_validation_log (
    id BIGSERIAL PRIMARY KEY,
    trip_id BIGINT,
    test_trip_id BIGINT,
    validation_type VARCHAR(50) NOT NULL CHECK (validation_type IN ('pre_send', 'post_error', 'manual_check')),
    field_name VARCHAR(100) NOT NULL,
    field_value TEXT,
    is_valid BOOLEAN NOT NULL,
    validation_error TEXT,
    error_code VARCHAR(20),
    corrected_value TEXT,
    validated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chiron_validation_log_trip_id ON chiron_validation_log(trip_id);
CREATE INDEX idx_chiron_validation_log_test_trip_id ON chiron_validation_log(test_trip_id);
CREATE INDEX idx_chiron_validation_log_is_valid ON chiron_validation_log(is_valid);
CREATE INDEX idx_chiron_validation_log_error_code ON chiron_validation_log(error_code);
CREATE INDEX idx_chiron_validation_log_validated_at ON chiron_validation_log(validated_at);

COMMENT ON TABLE chiron_validation_log IS 'سجل جميع عمليات التحقق من صحة البيانات قبل إرسالها إلى Chiron';
COMMENT ON COLUMN chiron_validation_log.trip_id IS 'معرف الرحلة الحقيقية (NULL للرحلات الاختبارية)';
COMMENT ON COLUMN chiron_validation_log.test_trip_id IS 'معرف الرحلة الاختبارية (NULL للرحلات الحقيقية)';
COMMENT ON COLUMN chiron_validation_log.validation_type IS 'نوع التحقق: pre_send (قبل الإرسال)، post_error (بعد الخطأ)، manual_check (فحص يدوي)';
COMMENT ON COLUMN chiron_validation_log.field_name IS 'اسم الحقل الذي تم التحقق منه';
COMMENT ON COLUMN chiron_validation_log.field_value IS 'القيمة الأصلية للحقل';
COMMENT ON COLUMN chiron_validation_log.is_valid IS 'هل القيمة صحيحة';
COMMENT ON COLUMN chiron_validation_log.validation_error IS 'رسالة الخطأ إذا كانت القيمة غير صحيحة';
COMMENT ON COLUMN chiron_validation_log.error_code IS 'رمز الخطأ المتوقع من Chiron';
COMMENT ON COLUMN chiron_validation_log.corrected_value IS 'القيمة المصححة (بعد التقريب أو التعديل)';

-- جدول قاعدة بيانات أخطاء Chiron
CREATE TABLE chiron_error_codes (
    id BIGSERIAL PRIMARY KEY,
    error_code VARCHAR(20) NOT NULL UNIQUE,
    error_category VARCHAR(50) NOT NULL CHECK (error_category IN ('validation', 'authentication', 'business_logic', 'technical', 'data_format')),
    error_description_nl TEXT NOT NULL,
    error_description_ar TEXT NOT NULL,
    solution_steps TEXT NOT NULL,
    prevention_tips TEXT,
    is_critical BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chiron_error_codes_error_code ON chiron_error_codes(error_code);
CREATE INDEX idx_chiron_error_codes_category ON chiron_error_codes(error_category);
CREATE INDEX idx_chiron_error_codes_is_critical ON chiron_error_codes(is_critical);

COMMENT ON TABLE chiron_error_codes IS 'قاعدة بيانات شاملة لجميع رموز أخطاء Chiron API مع الحلول والوقاية';
COMMENT ON COLUMN chiron_error_codes.error_code IS 'رمز الخطأ من Chiron (مثل: CH1205، CH1208، CH1210)';
COMMENT ON COLUMN chiron_error_codes.error_category IS 'تصنيف الخطأ: validation (تحقق من الصحة)، authentication (مصادقة)، business_logic (منطق الأعمال)، technical (تقني)، data_format (تنسيق البيانات)';
COMMENT ON COLUMN chiron_error_codes.error_description_nl IS 'وصف الخطأ بالهولندية (من الدليل التقني)';
COMMENT ON COLUMN chiron_error_codes.error_description_ar IS 'وصف الخطأ بالعربية';
COMMENT ON COLUMN chiron_error_codes.solution_steps IS 'خطوات الحل التفصيلية';
COMMENT ON COLUMN chiron_error_codes.prevention_tips IS 'نصائح لتجنب الخطأ في المستقبل';
COMMENT ON COLUMN chiron_error_codes.is_critical IS 'هل الخطأ حرج ويمنع إكمال العملية';

-- إدراج أخطاء CH1205 و CH1208 مع الحلول
INSERT INTO chiron_error_codes (error_code, error_category, error_description_nl, error_description_ar, solution_steps, prevention_tips, is_critical) VALUES
('CH1205', 'data_format', 'De breedtegraad voor het vertrekpunt moet minimaal 3 decimalen bevatten', 'خط العرض لنقطة الانطلاق يجب أن يحتوي على 3 خانات عشرية على الأقل', '1. تحقق من قيمة خط العرض (breedtegraad) لنقطة الانطلاق\n2. تأكد من وجود 3 خانات عشرية على الأقل (مثال: 50.850 بدلاً من 50.85)\n3. استخدم دالة التقريب لإضافة الأصفار إذا لزم الأمر\n4. أعد إرسال الطلب بالقيمة المصححة', 'دائماً تأكد من تنسيق الإحداثيات قبل الإرسال:\n- استخدم NUMERIC(10,8) في قاعدة البيانات\n- تحقق من عدد الخانات العشرية قبل الإرسال\n- استخدم دالة FORMAT للتأكد من التنسيق الصحيح', true),
('CH1208', 'data_format', 'De breedtegraad voor het aankomstpunt moet minimaal 3 decimalen bevatten', 'خط العرض لنقطة الوصول يجب أن يحتوي على 3 خانات عشرية على الأقل', '1. تحقق من قيمة خط العرض (breedtegraad) لنقطة الوصول\n2. تأكد من وجود 3 خانات عشرية على الأقل (مثال: 50.850 بدلاً من 50.85)\n3. استخدم دالة التقريب لإضافة الأصفار إذا لزم الأمر\n4. أعد إرسال الطلب بالقيمة المصححة', 'دائماً تأكد من تنسيق الإحداثيات قبل الإرسال:\n- استخدم NUMERIC(10,8) في قاعدة البيانات\n- تحقق من عدد الخانات العشرية قبل الإرسال\n- استخدم دالة FORMAT للتأكد من التنسيق الصحيح', true),
('CH1210', 'business_logic', 'Er is al een aankomstbericht verstuurd voor deze rit', 'تم إرسال رسالة وصول مسبقاً لهذه الرحلة', '1. تحقق من حالة الرحلة في قاعدة البيانات\n2. لا ترسل رسالة AANKOMST مرتين لنفس الرحلة\n3. استخدم جدول trip_state_transitions لتتبع حالة الرحلة\n4. تأكد من أن chiron_sync_state = START_ACCEPTED قبل إرسال AANKOMST', 'استخدم نظام تتبع الحالة:\n- سجل كل انتقال حالة في trip_state_transitions\n- تحقق من الحالة الحالية قبل إرسال أي رسالة\n- لا ترسل AANKOMST إلا بعد تأكيد قبول START', true);

-- جدول إعدادات Chiron API
CREATE TABLE chiron_api_config (
    id BIGSERIAL PRIMARY KEY,
    environment VARCHAR(20) NOT NULL CHECK (environment IN ('test', 'production')),
    config_key VARCHAR(100) NOT NULL,
    config_value TEXT NOT NULL,
    config_type VARCHAR(50) NOT NULL CHECK (config_type IN ('url', 'timeout', 'retry', 'validation', 'format')),
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(environment, config_key)
);

CREATE INDEX idx_chiron_api_config_environment ON chiron_api_config(environment);
CREATE INDEX idx_chiron_api_config_config_key ON chiron_api_config(config_key);
CREATE INDEX idx_chiron_api_config_is_active ON chiron_api_config(is_active);

COMMENT ON TABLE chiron_api_config IS 'إعدادات Chiron API لكل بيئة (test/production) - يمكن تعديلها دون تغيير الكود';
COMMENT ON COLUMN chiron_api_config.environment IS 'البيئة: test (اختبار) أو production (إنتاج)';
COMMENT ON COLUMN chiron_api_config.config_key IS 'مفتاح الإعداد (مثل: max_retry_attempts، request_timeout)';
COMMENT ON COLUMN chiron_api_config.config_value IS 'قيمة الإعداد';
COMMENT ON COLUMN chiron_api_config.config_type IS 'نوع الإعداد: url، timeout، retry، validation، format';
COMMENT ON COLUMN chiron_api_config.description IS 'وصف الإعداد';

-- إدراج الإعدادات الافتراضية
INSERT INTO chiron_api_config (environment, config_key, config_value, config_type, description) VALUES
('test', 'max_retry_attempts', '3', 'retry', 'الحد الأقصى لمحاولات إعادة الإرسال في بيئة الاختبار'),
('test', 'request_timeout_seconds', '30', 'timeout', 'مهلة الطلب بالثواني في بيئة الاختبار'),
('test', 'coordinate_decimal_places', '3', 'format', 'الحد الأدنى لعدد الخانات العشرية للإحداثيات'),
('test', 'distance_decimal_places', '3', 'format', 'عدد الخانات العشرية للمسافة'),
('test', 'price_decimal_places', '2', 'format', 'عدد الخانات العشرية للسعر'),
('production', 'max_retry_attempts', '5', 'retry', 'الحد الأقصى لمحاولات إعادة الإرسال في بيئة الإنتاج'),
('production', 'request_timeout_seconds', '45', 'timeout', 'مهلة الطلب بالثواني في بيئة الإنتاج'),
('production', 'coordinate_decimal_places', '3', 'format', 'الحد الأدنى لعدد الخانات العشرية للإحداثيات'),
('production', 'distance_decimal_places', '3', 'format', 'عدد الخانات العشرية للمسافة'),
('production', 'price_decimal_places', '2', 'format', 'عدد الخانات العشرية للسعر');

-- إضافة أعمدة التحقق من الصحة لجدول trips
ALTER TABLE trips ADD COLUMN IF NOT EXISTS validation_status VARCHAR(20) DEFAULT 'pending' CHECK (validation_status IN ('pending', 'valid', 'invalid', 'corrected'));
ALTER TABLE trips ADD COLUMN IF NOT EXISTS validation_errors JSONB DEFAULT '[]';
ALTER TABLE trips ADD COLUMN IF NOT EXISTS last_validation_at TIMESTAMP WITH TIME ZONE;

CREATE INDEX idx_trips_validation_status ON trips(validation_status);

COMMENT ON COLUMN trips.validation_status IS 'حالة التحقق من صحة البيانات: pending (قيد الانتظار)، valid (صحيح)، invalid (غير صحيح)، corrected (تم التصحيح)';
COMMENT ON COLUMN trips.validation_errors IS 'قائمة أخطاء التحقق من الصحة (JSON)';
COMMENT ON COLUMN trips.last_validation_at IS 'تاريخ آخر عملية تحقق من الصحة';

-- إضافة أعمدة التحقق من الصحة لجدول test_trips
ALTER TABLE test_trips ADD COLUMN IF NOT EXISTS validation_status VARCHAR(20) DEFAULT 'pending' CHECK (validation_status IN ('pending', 'valid', 'invalid', 'corrected'));
ALTER TABLE test_trips ADD COLUMN IF NOT EXISTS validation_errors JSONB DEFAULT '[]';
ALTER TABLE test_trips ADD COLUMN IF NOT EXISTS last_validation_at TIMESTAMP WITH TIME ZONE;

CREATE INDEX idx_test_trips_validation_status ON test_trips(validation_status);

COMMENT ON COLUMN test_trips.validation_status IS 'حالة التحقق من صحة البيانات: pending (قيد الانتظار)، valid (صحيح)، invalid (غير صحيح)، corrected (تم التصحيح)';
COMMENT ON COLUMN test_trips.validation_errors IS 'قائمة أخطاء التحقق من الصحة (JSON)';
COMMENT ON COLUMN test_trips.last_validation_at IS 'تاريخ آخر عملية تحقق من الصحة';

-- جدول قواعد التحقق من صحة البيانات لـ Chiron API
CREATE TABLE chiron_validation_rules (
    id BIGSERIAL PRIMARY KEY,
    field_name VARCHAR(100) NOT NULL UNIQUE,
    field_type VARCHAR(50) NOT NULL CHECK (field_type IN ('decimal', 'integer', 'string', 'coordinate', 'datetime')),
    min_decimal_places INTEGER,
    max_decimal_places INTEGER,
    min_value NUMERIC(20,10),
    max_value NUMERIC(20,10),
    regex_pattern TEXT,
    is_required BOOLEAN DEFAULT true,
    error_code VARCHAR(20),
    validation_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE chiron_validation_rules IS 'قواعد التحقق من صحة البيانات المرسلة إلى Chiron API - تضمن التنسيق الصحيح لجميع الحقول';
COMMENT ON COLUMN chiron_validation_rules.field_name IS 'اسم الحقل في Chiron API (مثل: afstand، kostprijs، breedtegraad)';
COMMENT ON COLUMN chiron_validation_rules.field_type IS 'نوع البيانات: decimal (عشري)، integer (صحيح)، string (نص)، coordinate (إحداثيات)، datetime (تاريخ ووقت)';
COMMENT ON COLUMN chiron_validation_rules.min_decimal_places IS 'الحد الأدنى لعدد الخانات العشرية المطلوبة';
COMMENT ON COLUMN chiron_validation_rules.max_decimal_places IS 'الحد الأقصى لعدد الخانات العشرية المسموح بها';
COMMENT ON COLUMN chiron_validation_rules.min_value IS 'القيمة الدنيا المسموح بها';
COMMENT ON COLUMN chiron_validation_rules.max_value IS 'القيمة القصوى المسموح بها';
COMMENT ON COLUMN chiron_validation_rules.regex_pattern IS 'نمط التحقق من صحة النص (Regular Expression)';
COMMENT ON COLUMN chiron_validation_rules.error_code IS 'رمز الخطأ من Chiron (مثل: CH1205، CH1208)';
COMMENT ON COLUMN chiron_validation_rules.validation_message IS 'رسالة التحقق من الصحة بالعربية';

CREATE INDEX idx_chiron_validation_rules_field_name ON chiron_validation_rules(field_name);
CREATE INDEX idx_chiron_validation_rules_error_code ON chiron_validation_rules(error_code);

-- إدراج قواعد التحقق الأساسية بناءً على أخطاء CH1205 و CH1208
INSERT INTO chiron_validation_rules (field_name, field_type, min_decimal_places, max_decimal_places, error_code, validation_message) VALUES
('vertrek_breedtegraad', 'coordinate', 3, 8, 'CH1205', 'خط العرض لنقطة الانطلاق يجب أن يحتوي على 3 خانات عشرية على الأقل'),
('vertrek_lengtegraad', 'coordinate', 3, 8, 'CH1205', 'خط الطول لنقطة الانطلاق يجب أن يحتوي على 3 خانات عشرية على الأقل'),
('aankomst_breedtegraad', 'coordinate', 3, 8, 'CH1208', 'خط العرض لنقطة الوصول يجب أن يحتوي على 3 خانات عشرية على الأقل'),
('aankomst_lengtegraad', 'coordinate', 3, 8, 'CH1208', 'خط الطول لنقطة الوصول يجب أن يحتوي على 3 خانات عشرية على الأقل'),
('afstand', 'decimal', 3, 3, 'CH1206', 'المسافة يجب أن تحتوي على 3 خانات عشرية بالضبط'),
('kostprijs', 'decimal', 2, 2, 'CH1207', 'السعر يجب أن يحتوي على خانتين عشريتين بالضبط');

-- جدول سجل التحقق من صحة البيانات
CREATE TABLE chiron_validation_log (
    id BIGSERIAL PRIMARY KEY,
    trip_id BIGINT,
    test_trip_id BIGINT,
    validation_type VARCHAR(50) NOT NULL CHECK (validation_type IN ('pre_send', 'post_error', 'manual_check')),
    field_name VARCHAR(100) NOT NULL,
    field_value TEXT,
    is_valid BOOLEAN NOT NULL,
    validation_error TEXT,
    error_code VARCHAR(20),
    corrected_value TEXT,
    validated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE chiron_validation_log IS 'سجل جميع عمليات التحقق من صحة البيانات قبل إرسالها إلى Chiron';
COMMENT ON COLUMN chiron_validation_log.trip_id IS 'معرف الرحلة الحقيقية (NULL للرحلات الاختبارية)';
COMMENT ON COLUMN chiron_validation_log.test_trip_id IS 'معرف الرحلة الاختبارية (NULL للرحلات الحقيقية)';
COMMENT ON COLUMN chiron_validation_log.validation_type IS 'نوع التحقق: pre_send (قبل الإرسال)، post_error (بعد الخطأ)، manual_check (فحص يدوي)';
COMMENT ON COLUMN chiron_validation_log.field_name IS 'اسم الحقل الذي تم التحقق منه';
COMMENT ON COLUMN chiron_validation_log.field_value IS 'القيمة الأصلية للحقل';
COMMENT ON COLUMN chiron_validation_log.is_valid IS 'هل القيمة صحيحة';
COMMENT ON COLUMN chiron_validation_log.validation_error IS 'رسالة الخطأ إذا كانت القيمة غير صحيحة';
COMMENT ON COLUMN chiron_validation_log.error_code IS 'رمز الخطأ المتوقع من Chiron';
COMMENT ON COLUMN chiron_validation_log.corrected_value IS 'القيمة المصححة (بعد التقريب أو التعديل)';

CREATE INDEX idx_chiron_validation_log_trip_id ON chiron_validation_log(trip_id);
CREATE INDEX idx_chiron_validation_log_test_trip_id ON chiron_validation_log(test_trip_id);
CREATE INDEX idx_chiron_validation_log_is_valid ON chiron_validation_log(is_valid);
CREATE INDEX idx_chiron_validation_log_error_code ON chiron_validation_log(error_code);
CREATE INDEX idx_chiron_validation_log_validated_at ON chiron_validation_log(validated_at);

-- جدول قاعدة بيانات أخطاء Chiron
CREATE TABLE chiron_error_codes (
    id BIGSERIAL PRIMARY KEY,
    error_code VARCHAR(20) NOT NULL UNIQUE,
    error_category VARCHAR(50) NOT NULL CHECK (error_category IN ('validation', 'authentication', 'business_logic', 'technical', 'data_format')),
    error_description_nl TEXT NOT NULL,
    error_description_ar TEXT NOT NULL,
    solution_steps TEXT NOT NULL,
    prevention_tips TEXT,
    is_critical BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE chiron_error_codes IS 'قاعدة بيانات شاملة لجميع رموز أخطاء Chiron API مع الحلول والوقاية';
COMMENT ON COLUMN chiron_error_codes.error_code IS 'رمز الخطأ من Chiron (مثل: CH1205، CH1208، CH1210)';
COMMENT ON COLUMN chiron_error_codes.error_category IS 'تصنيف الخطأ: validation (تحقق من الصحة)، authentication (مصادقة)، business_logic (منطق الأعمال)، technical (تقني)، data_format (تنسيق البيانات)';
COMMENT ON COLUMN chiron_error_codes.error_description_nl IS 'وصف الخطأ بالهولندية (من الدليل التقني)';
COMMENT ON COLUMN chiron_error_codes.error_description_ar IS 'وصف الخطأ بالعربية';
COMMENT ON COLUMN chiron_error_codes.solution_steps IS 'خطوات الحل التفصيلية';
COMMENT ON COLUMN chiron_error_codes.prevention_tips IS 'نصائح لتجنب الخطأ في المستقبل';
COMMENT ON COLUMN chiron_error_codes.is_critical IS 'هل الخطأ حرج ويمنع إكمال العملية';

CREATE INDEX idx_chiron_error_codes_error_code ON chiron_error_codes(error_code);
CREATE INDEX idx_chiron_error_codes_category ON chiron_error_codes(error_category);
CREATE INDEX idx_chiron_error_codes_is_critical ON chiron_error_codes(is_critical);

-- إدراج أخطاء CH1205 و CH1208 في قاعدة البيانات
INSERT INTO chiron_error_codes (error_code, error_category, error_description_nl, error_description_ar, solution_steps, prevention_tips, is_critical) VALUES
('CH1205', 'data_format', 'De breedtegraad voor het vertrekpunt moet minimaal 3 decimalen bevatten.', 'خط العرض لنقطة الانطلاق يجب أن يحتوي على 3 خانات عشرية كحد أدنى', '1. تحقق من قيمة خط العرض\n2. تأكد من وجود 3 خانات عشرية على الأقل\n3. أضف أصفاراً إذا لزم الأمر (مثال: 50.85 → 50.850)\n4. أعد إرسال الطلب', 'تأكد دائماً من تنسيق الإحداثيات بـ 3 خانات عشرية على الأقل قبل الإرسال', true),
('CH1208', 'data_format', 'De breedtegraad voor het aankomstpunt moet minimaal 3 decimalen bevatten.', 'خط العرض لنقطة الوصول يجب أن يحتوي على 3 خانات عشرية كحد أدنى', '1. تحقق من قيمة خط العرض\n2. تأكد من وجود 3 خانات عشرية على الأقل\n3. أضف أصفاراً إذا لزم الأمر (مثال: 50.85 → 50.850)\n4. أعد إرسال الطلب', 'تأكد دائماً من تنسيق الإحداثيات بـ 3 خانات عشرية على الأقل قبل الإرسال', true),
('CH1210', 'business_logic', 'Er is al een aankomstbericht verstuurd voor deze rit.', 'تم إرسال رسالة وصول مسبقاً لهذه الرحلة', '1. تحقق من حالة الرحلة في قاعدة البيانات\n2. لا ترسل رسالة AANKOMST مرتين لنفس الرحلة\n3. استخدم جدول trip_state_transitions للتحقق من الحالة', 'تتبع حالة كل رحلة بدقة ولا ترسل رسالة AANKOMST إلا مرة واحدة فقط', true);

-- إضافة حقول التحقق من الصحة في جدول test_trips
ALTER TABLE test_trips ADD COLUMN IF NOT EXISTS validation_status VARCHAR(20) DEFAULT 'pending' CHECK (validation_status IN ('pending', 'valid', 'invalid', 'corrected'));
ALTER TABLE test_trips ADD COLUMN IF NOT EXISTS validation_errors JSONB DEFAULT '[]';
ALTER TABLE test_trips ADD COLUMN IF NOT EXISTS last_validation_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN test_trips.validation_status IS 'حالة التحقق من صحة البيانات: pending (قيد الانتظار)، valid (صحيح)، invalid (غير صحيح)، corrected (تم التصحيح)';
COMMENT ON COLUMN test_trips.validation_errors IS 'قائمة أخطاء التحقق من الصحة (JSON)';
COMMENT ON COLUMN test_trips.last_validation_at IS 'تاريخ آخر عملية تحقق من الصحة';

CREATE INDEX idx_test_trips_validation_status ON test_trips(validation_status);

-- إضافة حقول التحقق من الصحة في جدول trips
ALTER TABLE trips ADD COLUMN IF NOT EXISTS validation_status VARCHAR(20) DEFAULT 'pending' CHECK (validation_status IN ('pending', 'valid', 'invalid', 'corrected'));
ALTER TABLE trips ADD COLUMN IF NOT EXISTS validation_errors JSONB DEFAULT '[]';
ALTER TABLE trips ADD COLUMN IF NOT EXISTS last_validation_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN trips.validation_status IS 'حالة التحقق من صحة البيانات: pending (قيد الانتظار)، valid (صحيح)، invalid (غير صحيح)، corrected (تم التصحيح)';
COMMENT ON COLUMN trips.validation_errors IS 'قائمة أخطاء التحقق من الصحة (JSON)';
COMMENT ON COLUMN trips.last_validation_at IS 'تاريخ آخر عملية تحقق من الصحة';

CREATE INDEX idx_trips_validation_status ON trips(validation_status);

-- تحديث قواعد التحقق من صحة الإحداثيات الجغرافية
-- حذف القواعد القديمة إن وجدت
DELETE FROM chiron_validation_rules WHERE field_name IN ('vertrek_breedtegraad', 'vertrek_lengtegraad', 'aankomst_breedtegraad', 'aankomst_lengtegraad');

-- إضافة قواعد جديدة محدثة للإحداثيات
INSERT INTO chiron_validation_rules (field_name, field_type, min_decimal_places, max_decimal_places, min_value, max_value, is_required, error_code, validation_message) VALUES
('vertrek_breedtegraad', 'coordinate', 3, 6, 49.0, 52.0, true, 'CH1205', 'خط العرض لنقطة الانطلاق يجب أن يحتوي على 3 خانات عشرية على الأقل (مثال: 50.856)'),
('vertrek_lengtegraad', 'coordinate', 3, 6, 2.0, 7.0, true, 'CH1205', 'خط الطول لنقطة الانطلاق يجب أن يحتوي على 3 خانات عشرية على الأقل (مثال: 4.332)'),
('aankomst_breedtegraad', 'coordinate', 3, 6, 49.0, 52.0, true, 'CH1208', 'خط العرض لنقطة الوصول يجب أن يحتوي على 3 خانات عشرية على الأقل (مثال: 50.856)'),
('aankomst_lengtegraad', 'coordinate', 3, 6, 2.0, 7.0, true, 'CH1208', 'خط الطول لنقطة الوصول يجب أن يحتوي على 3 خانات عشرية على الأقل (مثال: 4.332)'),
('afstand', 'decimal', 3, 3, 0.0, 9999.99, true, 'CH1206', 'المسافة يجب أن تحتوي على 3 خانات عشرية بالضبط (مثال: 12.544)'),
('kostprijs', 'decimal', 2, 2, 0.0, 99999.99, true, 'CH1207', 'السعر يجب أن يحتوي على خانتين عشريتين بالضبط (مثال: 42.62)');

-- إضافة أكواد الأخطاء الشائعة من Chiron
DELETE FROM chiron_error_codes WHERE error_code IN ('CH1205', 'CH1208', 'CH1206', 'CH1207', 'CH1210', 'CH1211');

INSERT INTO chiron_error_codes (error_code, error_category, error_description_nl, error_description_ar, solution_steps, prevention_tips, is_critical) VALUES
('CH1205', 'data_format', 'De breedtegraad voor het vertrekpunt moet minimaal 3 decimalen bevatten.', 'خط العرض لنقطة الانطلاق يجب أن يحتوي على 3 خانات عشرية على الأقل', 'تأكد من تنسيق الإحداثيات بـ 3 خانات عشرية على الأقل. مثال: 50.856 بدلاً من 50.85', 'استخدم دالة toFixed(3) في JavaScript أو ROUND(value, 3) في SQL لضمان 3 خانات عشرية', true),
('CH1208', 'data_format', 'De breedtegraad voor het aankomstpunt moet minimaal 3 decimalen bevatten.', 'خط العرض لنقطة الوصول يجب أن يحتوي على 3 خانات عشرية على الأقل', 'تأكد من تنسيق الإحداثيات بـ 3 خانات عشرية على الأقل. مثال: 50.856 بدلاً من 50.85', 'استخدم دالة toFixed(3) في JavaScript أو ROUND(value, 3) في SQL لضمان 3 خانات عشرية', true),
('CH1206', 'data_format', 'De afstand moet exact 3 decimalen bevatten.', 'المسافة يجب أن تحتوي على 3 خانات عشرية بالضبط', 'تأكد من تنسيق المسافة بـ 3 خانات عشرية. مثال: 12.544 بدلاً من 12.54', 'استخدم toFixed(3) لتنسيق المسافة قبل الإرسال', true),
('CH1207', 'data_format', 'De kostprijs moet exact 2 decimalen bevatten.', 'السعر يجب أن يحتوي على خانتين عشريتين بالضبط', 'تأكد من تنسيق السعر بخانتين عشريتين. مثال: 42.62 بدلاً من 42.6', 'استخدم toFixed(2) لتنسيق السعر قبل الإرسال', true),
('CH1210', 'business_logic', 'Er is al een aankomstbericht verzonden voor deze rit.', 'تم إرسال رسالة وصول مسبقاً لهذه الرحلة', 'تحقق من حالة الرحلة في جدول trips قبل إرسال رسالة ARRIVAL. لا ترسل ARRIVAL إلا إذا كانت chiron_sync_state = START_ACCEPTED', 'استخدم جدول trip_state_transitions لتتبع حالة الرحلة ومنع إرسال رسائل مكررة', true),
('CH1211', 'business_logic', 'Er moet eerst een vertrekbericht verzonden worden.', 'يجب إرسال رسالة انطلاق أولاً', 'تأكد من إرسال رسالة START وقبولها من Chiron قبل إرسال ARRIVAL. تحقق من start_accepted_at في جدول trips', 'لا ترسل ARRIVAL إلا بعد التأكد من نجاح START والحصول على HTTP 2xx', true);

-- تحديث إعدادات Chiron API
DELETE FROM chiron_api_config WHERE config_key IN ('coordinate_decimal_places', 'distance_decimal_places', 'price_decimal_places', 'auto_format_coordinates', 'validate_before_send');

INSERT INTO chiron_api_config (environment, config_key, config_value, config_type, description, is_active) VALUES
('test', 'coordinate_decimal_places', '3', 'format', 'عدد الخانات العشرية للإحداثيات الجغرافية (الحد الأدنى 3)', true),
('test', 'distance_decimal_places', '3', 'format', 'عدد الخانات العشرية للمسافة (بالضبط 3)', true),
('test', 'price_decimal_places', '2', 'format', 'عدد الخانات العشرية للسعر (بالضبط 2)', true),
('test', 'auto_format_coordinates', 'true', 'validation', 'تنسيق تلقائي للإحداثيات قبل الإرسال', true),
('test', 'validate_before_send', 'true', 'validation', 'التحقق من صحة البيانات قبل الإرسال إلى Chiron', true),
('test', 'max_retry_attempts', '3', 'retry', 'الحد الأقصى لمحاولات إعادة الإرسال', true),
('test', 'retry_delay_seconds', '5', 'retry', 'التأخير بين محاولات إعادة الإرسال (بالثواني)', true),
('production', 'coordinate_decimal_places', '3', 'format', 'عدد الخانات العشرية للإحداثيات الجغرافية (الحد الأدنى 3)', true),
('production', 'distance_decimal_places', '3', 'format', 'عدد الخانات العشرية للمسافة (بالضبط 3)', true),
('production', 'price_decimal_places', '2', 'format', 'عدد الخانات العشرية للسعر (بالضبط 2)', true),
('production', 'auto_format_coordinates', 'true', 'validation', 'تنسيق تلقائي للإحداثيات قبل الإرسال', true),
('production', 'validate_before_send', 'true', 'validation', 'التحقق من صحة البيانات قبل الإرسال إلى Chiron', true),
('production', 'max_retry_attempts', '3', 'retry', 'الحد الأقصى لمحاولات إعادة الإرسال', true),
('production', 'retry_delay_seconds', '5', 'retry', 'التأخير بين محاولات إعادة الإرسال (بالثواني)', true);

-- إضافة دالة مساعدة لتنسيق الإحداثيات تلقائياً
CREATE OR REPLACE FUNCTION format_coordinate(coord NUMERIC, decimal_places INTEGER DEFAULT 3)
RETURNS NUMERIC AS $$
BEGIN
    -- تنسيق الإحداثية بعدد الخانات العشرية المطلوب
    -- إذا كانت الإحداثية تحتوي على خانات أقل، يتم إضافة أصفار
    RETURN ROUND(coord::NUMERIC, decimal_places);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION format_coordinate IS 'تنسيق الإحداثيات الجغرافية بعدد الخانات العشرية المطلوب (افتراضي 3)';

-- إضافة دالة للتحقق من صحة الإحداثيات
CREATE OR REPLACE FUNCTION validate_coordinate_format(coord NUMERIC, min_decimals INTEGER DEFAULT 3)
RETURNS BOOLEAN AS $$
DECLARE
    coord_text TEXT;
    decimal_part TEXT;
    decimal_count INTEGER;
BEGIN
    -- تحويل الإحداثية إلى نص
    coord_text := coord::TEXT;
    
    -- التحقق من وجود نقطة عشرية
    IF coord_text NOT LIKE '%.%' THEN
        RETURN FALSE;
    END IF;
    
    -- استخراج الجزء العشري
    decimal_part := SPLIT_PART(coord_text, '.', 2);
    decimal_count := LENGTH(decimal_part);
    
    -- التحقق من عدد الخانات العشرية
    RETURN decimal_count >= min_decimals;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION validate_coordinate_format IS 'التحقق من أن الإحداثية تحتوي على العدد المطلوب من الخانات العشرية';

-- إضافة trigger لتنسيق الإحداثيات تلقائياً في جدول trips
CREATE OR REPLACE FUNCTION auto_format_trip_coordinates()
RETURNS TRIGGER AS $$
BEGIN
    -- تنسيق إحداثيات البداية
    IF NEW.start_lat IS NOT NULL THEN
        NEW.start_lat := format_coordinate(NEW.start_lat, 3);
    END IF;
    
    IF NEW.start_lon IS NOT NULL THEN
        NEW.start_lon := format_coordinate(NEW.start_lon, 3);
    END IF;
    
    -- تنسيق إحداثيات النهاية
    IF NEW.end_lat IS NOT NULL THEN
        NEW.end_lat := format_coordinate(NEW.end_lat, 3);
    END IF;
    
    IF NEW.end_lon IS NOT NULL THEN
        NEW.end_lon := format_coordinate(NEW.end_lon, 3);
    END IF;
    
    -- تنسيق المسافة
    IF NEW.distance_km IS NOT NULL THEN
        NEW.distance_km := ROUND(NEW.distance_km::NUMERIC, 3);
    END IF;
    
    -- تنسيق السعر
    IF NEW.price IS NOT NULL THEN
        NEW.price := ROUND(NEW.price::NUMERIC, 2);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_auto_format_trip_coordinates ON trips;
CREATE TRIGGER trigger_auto_format_trip_coordinates
    BEFORE INSERT OR UPDATE ON trips
    FOR EACH ROW
    EXECUTE FUNCTION auto_format_trip_coordinates();

COMMENT ON FUNCTION auto_format_trip_coordinates IS 'تنسيق تلقائي للإحداثيات والمسافة والسعر في جدول trips';

-- إضافة trigger مماثل لجدول test_trips
CREATE OR REPLACE FUNCTION auto_format_test_trip_coordinates()
RETURNS TRIGGER AS $$
BEGIN
    -- تنسيق إحداثيات البداية
    IF NEW.start_lat IS NOT NULL THEN
        NEW.start_lat := format_coordinate(NEW.start_lat, 3);
    END IF;
    
    IF NEW.start_lon IS NOT NULL THEN
        NEW.start_lon := format_coordinate(NEW.start_lon, 3);
    END IF;
    
    -- تنسيق إحداثيات النهاية
    IF NEW.end_lat IS NOT NULL THEN
        NEW.end_lat := format_coordinate(NEW.end_lat, 3);
    END IF;
    
    IF NEW.end_lon IS NOT NULL THEN
        NEW.end_lon := format_coordinate(NEW.end_lon, 3);
    END IF;
    
    -- تنسيق المسافة
    IF NEW.distance_km IS NOT NULL THEN
        NEW.distance_km := ROUND(NEW.distance_km::NUMERIC, 3);
    END IF;
    
    -- تنسيق السعر
    IF NEW.price IS NOT NULL THEN
        NEW.price := ROUND(NEW.price::NUMERIC, 2);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_auto_format_test_trip_coordinates ON test_trips;
CREATE TRIGGER trigger_auto_format_test_trip_coordinates
    BEFORE INSERT OR UPDATE ON test_trips
    FOR EACH ROW
    EXECUTE FUNCTION auto_format_test_trip_coordinates();

COMMENT ON FUNCTION auto_format_test_trip_coordinates IS 'تنسيق تلقائي للإحداثيات والمسافة والسعر في جدول test_trips';

-- إزالة القيد القديم
ALTER TABLE platform_contracts DROP CONSTRAINT IF EXISTS platform_contracts_platform_name_check;

-- إضافة قيد جديد يقبل الأحرف الكبيرة والصغيرة
ALTER TABLE platform_contracts 
ADD CONSTRAINT platform_contracts_platform_name_check 
CHECK (LOWER(platform_name) IN ('uber', 'bolt', 'heetch'));

-- إضافة دالة trigger لتحويل platform_name إلى أحرف صغيرة تلقائياً
CREATE OR REPLACE FUNCTION normalize_platform_name()
RETURNS TRIGGER AS $$
BEGIN
    -- تحويل platform_name إلى أحرف صغيرة وإزالة المسافات
    NEW.platform_name := LOWER(TRIM(NEW.platform_name));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إنشاء trigger لتطبيق التحويل التلقائي
DROP TRIGGER IF EXISTS normalize_platform_name_trigger ON platform_contracts;
CREATE TRIGGER normalize_platform_name_trigger
    BEFORE INSERT OR UPDATE ON platform_contracts
    FOR EACH ROW
    EXECUTE FUNCTION normalize_platform_name();

-- تحديث البيانات الموجودة لتطابق التنسيق الجديد
UPDATE platform_contracts 
SET platform_name = LOWER(TRIM(platform_name))
WHERE platform_name IS NOT NULL;

COMMENT ON CONSTRAINT platform_contracts_platform_name_check ON platform_contracts IS 
'يسمح بأسماء المنصات: uber, bolt, heetch (غير حساس لحالة الأحرف - يتم التحويل تلقائياً إلى أحرف صغيرة)';

COMMENT ON FUNCTION normalize_platform_name() IS 
'دالة تلقائية لتحويل platform_name إلى أحرف صغيرة وإزالة المسافات قبل الحفظ';

-- جدول ملخصات الرحلات مع المعلومات الضريبية
CREATE TABLE trip_summaries (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    driver_id BIGINT NOT NULL,
    company_id BIGINT NOT NULL,
    summary_period VARCHAR(20) NOT NULL CHECK (summary_period IN ('daily', 'weekly', 'monthly', 'custom')),
    period_start_date DATE NOT NULL,
    period_end_date DATE NOT NULL,
    
    -- إحصائيات الرحلات
    total_trips INTEGER DEFAULT 0,
    completed_trips INTEGER DEFAULT 0,
    cancelled_trips INTEGER DEFAULT 0,
    
    -- المبالغ الإجمالية
    total_revenue NUMERIC(10,2) DEFAULT 0.00,
    total_distance_km NUMERIC(10,2) DEFAULT 0.00,
    total_duration_minutes INTEGER DEFAULT 0,
    
    -- تفاصيل طرق الدفع
    cash_amount NUMERIC(10,2) DEFAULT 0.00,
    card_amount NUMERIC(10,2) DEFAULT 0.00,
    bank_transfer_amount NUMERIC(10,2) DEFAULT 0.00,
    bancontact_amount NUMERIC(10,2) DEFAULT 0.00,
    
    -- تفاصيل الضرائب
    total_tax_amount NUMERIC(10,2) DEFAULT 0.00,
    tax_rate_6_amount NUMERIC(10,2) DEFAULT 0.00,
    tax_rate_21_amount NUMERIC(10,2) DEFAULT 0.00,
    
    -- مبالغ قبل وبعد الضريبة
    total_before_tax NUMERIC(10,2) DEFAULT 0.00,
    total_after_tax NUMERIC(10,2) DEFAULT 0.00,
    
    -- رحلات خاصة
    airport_trips_count INTEGER DEFAULT 0,
    airport_trips_amount NUMERIC(10,2) DEFAULT 0.00,
    night_trips_count INTEGER DEFAULT 0,
    night_trips_amount NUMERIC(10,2) DEFAULT 0.00,
    peak_hour_trips_count INTEGER DEFAULT 0,
    peak_hour_trips_amount NUMERIC(10,2) DEFAULT 0.00,
    
    -- رحلات المنصات الخارجية
    external_trips_count INTEGER DEFAULT 0,
    external_trips_amount NUMERIC(10,2) DEFAULT 0.00,
    bolt_trips_count INTEGER DEFAULT 0,
    bolt_trips_amount NUMERIC(10,2) DEFAULT 0.00,
    uber_trips_count INTEGER DEFAULT 0,
    uber_trips_amount NUMERIC(10,2) DEFAULT 0.00,
    heetch_trips_count INTEGER DEFAULT 0,
    heetch_trips_amount NUMERIC(10,2) DEFAULT 0.00,
    
    -- معلومات إضافية
    summary_notes TEXT,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- الفهارس لتحسين الأداء
CREATE INDEX idx_trip_summaries_user_id ON trip_summaries(user_id);
CREATE INDEX idx_trip_summaries_driver_id ON trip_summaries(driver_id);
CREATE INDEX idx_trip_summaries_company_id ON trip_summaries(company_id);
CREATE INDEX idx_trip_summaries_period ON trip_summaries(summary_period);
CREATE INDEX idx_trip_summaries_period_dates ON trip_summaries(period_start_date, period_end_date);
CREATE INDEX idx_trip_summaries_generated_at ON trip_summaries(generated_at);

-- التعليقات التوضيحية
COMMENT ON TABLE trip_summaries IS 'ملخصات الرحلات مع المعلومات الضريبية التفصيلية - يسهل عمل المحاسب ويوفر تقارير دقيقة';
COMMENT ON COLUMN trip_summaries.user_id IS 'معرف المستخدم';
COMMENT ON COLUMN trip_summaries.driver_id IS 'معرف السائق';
COMMENT ON COLUMN trip_summaries.company_id IS 'معرف الشركة';
COMMENT ON COLUMN trip_summaries.summary_period IS 'فترة الملخص: daily (يومي), weekly (أسبوعي), monthly (شهري), custom (مخصص)';
COMMENT ON COLUMN trip_summaries.period_start_date IS 'تاريخ بداية الفترة';
COMMENT ON COLUMN trip_summaries.period_end_date IS 'تاريخ نهاية الفترة';
COMMENT ON COLUMN trip_summaries.total_trips IS 'إجمالي عدد الرحلات';
COMMENT ON COLUMN trip_summaries.completed_trips IS 'عدد الرحلات المكتملة';
COMMENT ON COLUMN trip_summaries.cancelled_trips IS 'عدد الرحلات الملغاة';
COMMENT ON COLUMN trip_summaries.total_revenue IS 'إجمالي الإيرادات';
COMMENT ON COLUMN trip_summaries.total_distance_km IS 'إجمالي المسافة المقطوعة بالكيلومتر';
COMMENT ON COLUMN trip_summaries.total_duration_minutes IS 'إجمالي مدة الرحلات بالدقائق';
COMMENT ON COLUMN trip_summaries.cash_amount IS 'إجمالي المبلغ النقدي (Cash) - مهم للمحاسب';
COMMENT ON COLUMN trip_summaries.card_amount IS 'إجمالي المبلغ المدفوع بالبطاقة';
COMMENT ON COLUMN trip_summaries.bank_transfer_amount IS 'إجمالي المبلغ المدفوع بالتحويل البنكي';
COMMENT ON COLUMN trip_summaries.bancontact_amount IS 'إجمالي المبلغ المدفوع عبر Bancontact';
COMMENT ON COLUMN trip_summaries.total_tax_amount IS 'إجمالي الضريبة - مهم للمحاسب';
COMMENT ON COLUMN trip_summaries.tax_rate_6_amount IS 'إجمالي الضريبة بنسبة 6% (رحلات التاكسي)';
COMMENT ON COLUMN trip_summaries.tax_rate_21_amount IS 'إجمالي الضريبة بنسبة 21% (خدمات الشركات)';
COMMENT ON COLUMN trip_summaries.total_before_tax IS 'إجمالي المبلغ قبل الضريبة';
COMMENT ON COLUMN trip_summaries.total_after_tax IS 'إجمالي المبلغ بعد الضريبة';
COMMENT ON COLUMN trip_summaries.airport_trips_count IS 'عدد رحلات المطار';
COMMENT ON COLUMN trip_summaries.airport_trips_amount IS 'إجمالي مبلغ رحلات المطار';
COMMENT ON COLUMN trip_summaries.night_trips_count IS 'عدد الرحلات الليلية';
COMMENT ON COLUMN trip_summaries.night_trips_amount IS 'إجمالي مبلغ الرحلات الليلية';
COMMENT ON COLUMN trip_summaries.peak_hour_trips_count IS 'عدد رحلات ساعات الذروة';
COMMENT ON COLUMN trip_summaries.peak_hour_trips_amount IS 'إجمالي مبلغ رحلات ساعات الذروة';
COMMENT ON COLUMN trip_summaries.external_trips_count IS 'عدد الرحلات من المنصات الخارجية';
COMMENT ON COLUMN trip_summaries.external_trips_amount IS 'إجمالي مبلغ الرحلات من المنصات الخارجية';
COMMENT ON COLUMN trip_summaries.bolt_trips_count IS 'عدد رحلات Bolt';
COMMENT ON COLUMN trip_summaries.bolt_trips_amount IS 'إجمالي مبلغ رحلات Bolt';
COMMENT ON COLUMN trip_summaries.uber_trips_count IS 'عدد رحلات Uber';
COMMENT ON COLUMN trip_summaries.uber_trips_amount IS 'إجمالي مبلغ رحلات Uber';
COMMENT ON COLUMN trip_summaries.heetch_trips_count IS 'عدد رحلات Heetch';
COMMENT ON COLUMN trip_summaries.heetch_trips_amount IS 'إجمالي مبلغ رحلات Heetch';
COMMENT ON COLUMN trip_summaries.summary_notes IS 'ملاحظات إضافية عن الملخص';
COMMENT ON COLUMN trip_summaries.generated_at IS 'تاريخ ووقت إنشاء الملخص';

-- تفعيل RLS
ALTER TABLE trip_summaries ENABLE ROW LEVEL SECURITY;

-- سياسات RLS
CREATE POLICY trip_summaries_select_policy ON trip_summaries
    FOR SELECT USING (user_id = uid());

CREATE POLICY trip_summaries_insert_policy ON trip_summaries
    FOR INSERT WITH CHECK (user_id = uid());

CREATE POLICY trip_summaries_update_policy ON trip_summaries
    FOR UPDATE USING (user_id = uid()) WITH CHECK (user_id = uid());

CREATE POLICY trip_summaries_delete_policy ON trip_summaries
    FOR DELETE USING (user_id = uid());

-- إضافة حقول جديدة لتتبع حالة قبول START ومنع أخطاء CH1205 و CH1208

-- 1. إضافة حقل start_accepted لتخزين حالة قبول START من Chiron
ALTER TABLE test_trips 
ADD COLUMN start_accepted BOOLEAN DEFAULT false NOT NULL;

-- 2. إضافة حقل start_accepted_at لتخزين تاريخ ووقت قبول START
ALTER TABLE test_trips 
ADD COLUMN start_accepted_at TIMESTAMP WITH TIME ZONE;

-- 3. إضافة حقل start_message_id لتخزين معرف رسالة START المقبولة
ALTER TABLE test_trips 
ADD COLUMN start_message_id VARCHAR(100);

-- 4. إضافة حقل arrival_allowed لتحديد إذا كان مسموح بإرسال ARRIVAL
ALTER TABLE test_trips 
ADD COLUMN arrival_allowed BOOLEAN DEFAULT false NOT NULL;

-- 5. إضافة حقل last_chiron_status لتخزين آخر حالة من Chiron
ALTER TABLE test_trips 
ADD COLUMN last_chiron_status VARCHAR(50);

-- 6. إضافة حقل start_http_status لتخزين HTTP Status Code لرسالة START
ALTER TABLE test_trips 
ADD COLUMN start_http_status INTEGER;

-- 7. إضافة حقل arrival_http_status لتخزين HTTP Status Code لرسالة ARRIVAL
ALTER TABLE test_trips 
ADD COLUMN arrival_http_status INTEGER;

-- إضافة تعليقات توضيحية للحقول الجديدة
COMMENT ON COLUMN test_trips.start_accepted IS 'هل تم قبول رسالة START من Chiron (HTTP 2xx) - يجب أن يكون true قبل إرسال ARRIVAL لتجنب CH1205';
COMMENT ON COLUMN test_trips.start_accepted_at IS 'تاريخ ووقت قبول START من Chiron - يستخدم للتحقق من التسلسل الصحيح';
COMMENT ON COLUMN test_trips.start_message_id IS 'معرف رسالة START المقبولة من Chiron - للربط مع ARRIVAL';
COMMENT ON COLUMN test_trips.arrival_allowed IS 'هل يُسمح بإرسال ARRIVAL (يصبح true فقط بعد start_accepted = true) - يمنع CH1205';
COMMENT ON COLUMN test_trips.last_chiron_status IS 'آخر حالة تم استلامها من Chiron (مثل: GESTART) - للتحقق من التسلسل الصحيح ومنع CH1208';
COMMENT ON COLUMN test_trips.start_http_status IS 'HTTP Status Code لرسالة START - يجب أن يكون 2xx للقبول';
COMMENT ON COLUMN test_trips.arrival_http_status IS 'HTTP Status Code لرسالة ARRIVAL - يجب أن يكون 2xx للنجاح';

-- إنشاء فهارس للحقول الجديدة لتحسين الأداء
CREATE INDEX idx_test_trips_start_accepted ON test_trips(start_accepted);
CREATE INDEX idx_test_trips_arrival_allowed ON test_trips(arrival_allowed);
CREATE INDEX idx_test_trips_start_accepted_at ON test_trips(start_accepted_at);

-- إضافة نفس الحقول لجدول trips (الرحلات الحقيقية)
ALTER TABLE trips 
ADD COLUMN start_accepted BOOLEAN DEFAULT false NOT NULL,
ADD COLUMN start_message_id VARCHAR(100),
ADD COLUMN arrival_allowed BOOLEAN DEFAULT false NOT NULL,
ADD COLUMN last_chiron_status VARCHAR(50),
ADD COLUMN start_http_status INTEGER,
ADD COLUMN arrival_http_status INTEGER;

-- إضافة تعليقات توضيحية للحقول الجديدة في جدول trips
COMMENT ON COLUMN trips.start_accepted IS 'هل تم قبول رسالة START من Chiron (HTTP 2xx) - يجب أن يكون true قبل إرسال ARRIVAL لتجنب CH1205';
COMMENT ON COLUMN trips.start_message_id IS 'معرف رسالة START المقبولة من Chiron - للربط مع ARRIVAL';
COMMENT ON COLUMN trips.arrival_allowed IS 'هل يُسمح بإرسال ARRIVAL (يصبح true فقط بعد start_accepted = true) - يمنع CH1205';
COMMENT ON COLUMN trips.last_chiron_status IS 'آخر حالة تم استلامها من Chiron (مثل: GESTART) - للتحقق من التسلسل الصحيح ومنع CH1208';
COMMENT ON COLUMN trips.start_http_status IS 'HTTP Status Code لرسالة START - يجب أن يكون 2xx للقبول';
COMMENT ON COLUMN trips.arrival_http_status IS 'HTTP Status Code لرسالة ARRIVAL - يجب أن يكون 2xx للنجاح';

-- إنشاء فهارس للحقول الجديدة في جدول trips
CREATE INDEX idx_trips_start_accepted ON trips(start_accepted);
CREATE INDEX idx_trips_arrival_allowed ON trips(arrival_allowed);

-- إنشاء جدول جديد لتتبع محاولات إرسال الرسائل بشكل تفصيلي
CREATE TABLE chiron_message_log (
    id BIGSERIAL PRIMARY KEY,
    trip_id BIGINT,
    test_trip_id BIGINT,
    ritnummer VARCHAR(100) NOT NULL,
    message_type VARCHAR(20) NOT NULL CHECK (message_type IN ('VERTREK', 'AANKOMST')),
    message_status VARCHAR(50) NOT NULL,
    http_status_code INTEGER,
    request_payload JSONB,
    response_payload JSONB,
    error_code VARCHAR(20),
    error_message TEXT,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- إضافة تعليقات توضيحية لجدول chiron_message_log
COMMENT ON TABLE chiron_message_log IS 'سجل تفصيلي لجميع الرسائل المرسلة إلى Chiron - يساعد في تشخيص أخطاء CH1205 و CH1208';
COMMENT ON COLUMN chiron_message_log.trip_id IS 'معرف الرحلة الحقيقية (NULL للرحلات الاختبارية)';
COMMENT ON COLUMN chiron_message_log.test_trip_id IS 'معرف الرحلة الاختبارية (NULL للرحلات الحقيقية)';
COMMENT ON COLUMN chiron_message_log.ritnummer IS 'رقم الرحلة في Chiron - يجب أن يكون متطابقاً تماماً بين START و ARRIVAL';
COMMENT ON COLUMN chiron_message_log.message_type IS 'نوع الرسالة: VERTREK (بداية) أو AANKOMST (وصول)';
COMMENT ON COLUMN chiron_message_log.message_status IS 'حالة الرسالة من Chiron (مثل: GESTART، ACCEPTED، REJECTED)';
COMMENT ON COLUMN chiron_message_log.http_status_code IS 'HTTP Status Code من Chiron';
COMMENT ON COLUMN chiron_message_log.request_payload IS 'محتوى الطلب المرسل إلى Chiron (JSON)';
COMMENT ON COLUMN chiron_message_log.response_payload IS 'محتوى الاستجابة من Chiron (JSON)';
COMMENT ON COLUMN chiron_message_log.error_code IS 'رمز الخطأ من Chiron (مثل: CH1205، CH1208)';
COMMENT ON COLUMN chiron_message_log.error_message IS 'رسالة الخطأ التفصيلية';

-- إنشاء فهارس لجدول chiron_message_log
CREATE INDEX idx_chiron_message_log_trip_id ON chiron_message_log(trip_id);
CREATE INDEX idx_chiron_message_log_test_trip_id ON chiron_message_log(test_trip_id);
CREATE INDEX idx_chiron_message_log_ritnummer ON chiron_message_log(ritnummer);
CREATE INDEX idx_chiron_message_log_message_type ON chiron_message_log(message_type);
CREATE INDEX idx_chiron_message_log_error_code ON chiron_message_log(error_code);
CREATE INDEX idx_chiron_message_log_sent_at ON chiron_message_log(sent_at);

-- إنشاء جدول لتخزين قواعد التحقق من التسلسل الصحيح
CREATE TABLE chiron_sequence_rules (
    id BIGSERIAL PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL UNIQUE,
    from_state VARCHAR(50),
    to_state VARCHAR(50) NOT NULL,
    required_status VARCHAR(50),
    is_allowed BOOLEAN DEFAULT true,
    error_code VARCHAR(20),
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- إضافة تعليقات توضيحية لجدول chiron_sequence_rules
COMMENT ON TABLE chiron_sequence_rules IS 'قواعد التسلسل الصحيح للرسائل في Chiron - يمنع أخطاء CH1208';
COMMENT ON COLUMN chiron_sequence_rules.rule_name IS 'اسم القاعدة (مثل: START_TO_ARRIVAL)';
COMMENT ON COLUMN chiron_sequence_rules.from_state IS 'الحالة السابقة (NULL للحالة الأولى)';
COMMENT ON COLUMN chiron_sequence_rules.to_state IS 'الحالة الجديدة';
COMMENT ON COLUMN chiron_sequence_rules.required_status IS 'الحالة المطلوبة (مثل: GESTART)';
COMMENT ON COLUMN chiron_sequence_rules.is_allowed IS 'هل الانتقال مسموح';
COMMENT ON COLUMN chiron_sequence_rules.error_code IS 'رمز الخطأ المتوقع إذا تم انتهاك القاعدة';
COMMENT ON COLUMN chiron_sequence_rules.error_message IS 'رسالة الخطأ التوضيحية';

-- إدراج قواعد التسلسل الأساسية
INSERT INTO chiron_sequence_rules (rule_name, from_state, to_state, required_status, is_allowed, error_code, error_message) VALUES
('INITIAL_START', NULL, 'VERTREK', 'GESTART', true, NULL, 'يمكن إرسال START كأول رسالة'),
('START_TO_ARRIVAL', 'VERTREK', 'AANKOMST', NULL, true, NULL, 'يمكن إرسال ARRIVAL بعد قبول START'),
('NO_ARRIVAL_WITHOUT_START', NULL, 'AANKOMST', NULL, false, 'CH1205', 'لا يمكن إرسال ARRIVAL بدون START مقبول'),
('NO_DUPLICATE_START', 'VERTREK', 'VERTREK', NULL, false, 'CH1209', 'لا يمكن إرسال START مرتين'),
('NO_STATUS_IN_ARRIVAL', 'VERTREK', 'AANKOMST', 'GESTART', false, 'CH1208', 'لا يجب إرسال status في رسالة ARRIVAL'),
('ONLY_GESTART_STATUS', NULL, 'VERTREK', 'GESTART', true, 'CH1208', 'يجب استخدام status = GESTART فقط في START');

-- إنشاء فهرس لجدول chiron_sequence_rules
CREATE INDEX idx_chiron_sequence_rules_from_to ON chiron_sequence_rules(from_state, to_state);

-- تحديث قواعد التحقق من صحة الإحداثيات الجغرافية لضمان 5 أرقام عشرية على الأقل

-- حذف القواعد القديمة إذا كانت موجودة
DELETE FROM chiron_validation_rules 
WHERE field_name IN ('vertrek.locatie.lat', 'vertrek.locatie.lon', 'aankomst.locatie.lat', 'aankomst.locatie.lon');

-- إضافة قواعد التحقق الجديدة للإحداثيات
INSERT INTO chiron_validation_rules (
    field_name,
    field_type,
    min_decimal_places,
    max_decimal_places,
    min_value,
    max_value,
    is_required,
    error_code,
    validation_message
) VALUES
-- قواعد نقطة البداية (VERTREK)
(
    'vertrek.locatie.lat',
    'coordinate',
    5,
    8,
    49.0,
    52.0,
    true,
    'CH1405',
    'خط العرض لنقطة الانطلاق يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.88012)'
),
(
    'vertrek.locatie.lon',
    'coordinate',
    5,
    8,
    2.0,
    7.0,
    true,
    'CH1405',
    'خط الطول لنقطة الانطلاق يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35178)'
),
-- قواعد نقطة الوصول (AANKOMST)
(
    'aankomst.locatie.lat',
    'coordinate',
    5,
    8,
    49.0,
    52.0,
    true,
    'CH1405',
    'خط العرض لنقطة الوصول يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.88012)'
),
(
    'aankomst.locatie.lon',
    'coordinate',
    5,
    8,
    2.0,
    7.0,
    true,
    'CH1405',
    'خط الطول لنقطة الوصول يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35178)'
);

-- تحديث رمز الخطأ في جدول chiron_error_codes إذا لم يكن موجوداً
INSERT INTO chiron_error_codes (
    error_code,
    error_category,
    error_description_nl,
    error_description_ar,
    solution_steps,
    prevention_tips,
    is_critical
) VALUES (
    'CH1405',
    'data_format',
    'De breedtegraad/lengtegraad moet minimaal 3 decimalen bevatten',
    'خط العرض/الطول يجب أن يحتوي على 3 أرقام عشرية على الأقل',
    '1. تأكد من أن جميع الإحداثيات تحتوي على 5 أرقام عشرية على الأقل
2. استخدم دالة toFixed(5) لتنسيق الإحداثيات قبل الإرسال
3. تحقق من دقة GPS في التطبيق
4. لا ترسل إحداثيات مقربة أو مبسطة',
    'استخدم دائماً 5-6 أرقام عشرية للإحداثيات الجغرافية لضمان الدقة المطلوبة من Chiron',
    true
) ON CONFLICT (error_code) DO UPDATE SET
    error_description_nl = EXCLUDED.error_description_nl,
    error_description_ar = EXCLUDED.error_description_ar,
    solution_steps = EXCLUDED.solution_steps,
    prevention_tips = EXCLUDED.prevention_tips,
    updated_at = CURRENT_TIMESTAMP;

-- إضافة تعليق توضيحي على الأعمدة المتأثرة
COMMENT ON COLUMN trips.start_lat IS 'خط العرض لنقطة البداية - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.88012) لتجنب خطأ CH1405';
COMMENT ON COLUMN trips.start_lon IS 'خط الطول لنقطة البداية - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35178) لتجنب خطأ CH1405';
COMMENT ON COLUMN trips.end_lat IS 'خط العرض لنقطة الوصول - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.88012) لتجنب خطأ CH1405';
COMMENT ON COLUMN trips.end_lon IS 'خط الطول لنقطة الوصول - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35178) لتجنب خطأ CH1405';

COMMENT ON COLUMN test_trips.start_lat IS 'خط العرض لنقطة البداية - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.88012) لتجنب خطأ CH1405';
COMMENT ON COLUMN test_trips.start_lon IS 'خط الطول لنقطة البداية - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35178) لتجنب خطأ CH1405';
COMMENT ON COLUMN test_trips.end_lat IS 'خط العرض لنقطة الوصول - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.88012) لتجنب خطأ CH1405';
COMMENT ON COLUMN test_trips.end_lon IS 'خط الطول لنقطة الوصول - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35178) لتجنب خطأ CH1405';

-- تحديث قواعد التحقق من صحة الإحداثيات الجغرافية لتطلب 5 أرقام عشرية على الأقل

-- حذف القواعد القديمة إذا كانت موجودة
DELETE FROM chiron_validation_rules WHERE field_name IN ('breedtegraad', 'lengtegraad', 'vertrek_lat', 'vertrek_lon', 'aankomst_lat', 'aankomst_lon');

-- إضافة قواعد التحقق الصحيحة للإحداثيات
INSERT INTO chiron_validation_rules (
    field_name,
    field_type,
    min_decimal_places,
    max_decimal_places,
    min_value,
    max_value,
    is_required,
    error_code,
    validation_message
) VALUES
-- قواعد لإحداثيات نقطة الانطلاق (Vertrek)
(
    'vertrek_breedtegraad',
    'coordinate',
    5,  -- الحد الأدنى 5 أرقام عشرية (وليس 3)
    8,  -- الحد الأقصى 8 أرقام عشرية
    49.0,  -- الحد الأدنى لخط العرض في بلجيكا
    52.0,  -- الحد الأقصى لخط العرض في بلجيكا
    true,
    'CH1405',
    'خط العرض لنقطة الانطلاق يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.88000 وليس 50.88)'
),
(
    'vertrek_lengtegraad',
    'coordinate',
    5,  -- الحد الأدنى 5 أرقام عشرية (وليس 3)
    8,  -- الحد الأقصى 8 أرقام عشرية
    2.0,  -- الحد الأدنى لخط الطول في بلجيكا
    7.0,  -- الحد الأقصى لخط الطول في بلجيكا
    true,
    'CH1405',
    'خط الطول لنقطة الانطلاق يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.70100 وليس 4.701)'
),
-- قواعد لإحداثيات نقطة الوصول (Aankomst)
(
    'aankomst_breedtegraad',
    'coordinate',
    5,  -- الحد الأدنى 5 أرقام عشرية (وليس 3)
    8,  -- الحد الأقصى 8 أرقام عشرية
    49.0,  -- الحد الأدنى لخط العرض في بلجيكا
    52.0,  -- الحد الأقصى لخط العرض في بلجيكا
    true,
    'CH1405',
    'خط العرض لنقطة الوصول يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.84800 وليس 50.848)'
),
(
    'aankomst_lengtegraad',
    'coordinate',
    5,  -- الحد الأدنى 5 أرقام عشرية (وليس 3)
    8,  -- الحد الأقصى 8 أرقام عشرية
    2.0,  -- الحد الأدنى لخط الطول في بلجيكا
    7.0,  -- الحد الأقصى لخط الطول في بلجيكا
    true,
    'CH1405',
    'خط الطول لنقطة الوصول يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35700 وليس 4.357)'
);

-- تحديث رمز الخطأ CH1405 في جدول chiron_error_codes
DELETE FROM chiron_error_codes WHERE error_code = 'CH1405';

INSERT INTO chiron_error_codes (
    error_code,
    error_category,
    error_description_nl,
    error_description_ar,
    solution_steps,
    prevention_tips,
    is_critical
) VALUES (
    'CH1405',
    'data_format',
    'De breedtegraad of lengtegraad moet minimaal 5 decimalen bevatten',
    'خط العرض أو خط الطول يجب أن يحتوي على 5 أرقام عشرية على الأقل',
    '1. تحقق من أن جميع الإحداثيات تحتوي على 5 أرقام عشرية على الأقل
2. استخدم دالة normalizeCoord لتنسيق الإحداثيات تلقائياً:
   function normalizeCoord(value: number): number {
     return Number(value.toFixed(5));
   }
3. مثال صحيح:
   - ✅ 50.88000 (5 أرقام عشرية)
   - ✅ 50.88012 (5 أرقام عشرية)
   - ❌ 50.88 (رقمين عشريين فقط)
4. تطبيق على جميع الإحداثيات:
   - vertrek.locatie.lat
   - vertrek.locatie.lon
   - aankomst.locatie.lat
   - aankomst.locatie.lon',
    'نصائح للوقاية:
1. دائماً استخدم 5-6 أرقام عشرية للإحداثيات
2. استخدم دالة normalizeCoord قبل إرسال أي بيانات إلى Chiron
3. تحقق من التنسيق قبل الإرسال باستخدام جدول chiron_validation_rules
4. استخدم النقطة (.) كفاصلة عشرية وليس الفاصلة (,)
5. تأكد من أن القيم من نوع Number وليس String',
    true
);

-- إضافة أمثلة للتحقق من الصحة في جدول chiron_validation_log
COMMENT ON TABLE chiron_validation_log IS 'سجل جميع عمليات التحقق من صحة البيانات قبل إرسالها إلى Chiron

أمثلة على التحقق من الإحداثيات:
- ❌ خطأ: 50.88 (رقمين عشريين فقط)
- ✅ صحيح: 50.88000 (5 أرقام عشرية)
- ✅ صحيح: 50.88012 (5 أرقام عشرية)

استخدم دالة normalizeCoord لتنسيق الإحداثيات:
function normalizeCoord(value: number): number {
  return Number(value.toFixed(5));
}';

-- دالة لتنسيق الإحداثيات تلقائياً إلى 5 أرقام عشرية
CREATE OR REPLACE FUNCTION normalize_coordinate(coord NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND(coord::NUMERIC, 5);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION normalize_coordinate IS 'تنسيق الإحداثيات الجغرافية إلى 5 أرقام عشرية لتجنب خطأ CH1405 من Chiron';

-- إضافة قيود CHECK للتحقق من عدد الأرقام العشرية في جدول trips
ALTER TABLE trips DROP CONSTRAINT IF EXISTS trips_start_lat_decimals_check;
ALTER TABLE trips ADD CONSTRAINT trips_start_lat_decimals_check 
    CHECK (start_lat IS NULL OR (start_lat::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$'));

ALTER TABLE trips DROP CONSTRAINT IF EXISTS trips_start_lon_decimals_check;
ALTER TABLE trips ADD CONSTRAINT trips_start_lon_decimals_check 
    CHECK (start_lon IS NULL OR (start_lon::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$'));

ALTER TABLE trips DROP CONSTRAINT IF EXISTS trips_end_lat_decimals_check;
ALTER TABLE trips ADD CONSTRAINT trips_end_lat_decimals_check 
    CHECK (end_lat IS NULL OR (end_lat::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$'));

ALTER TABLE trips DROP CONSTRAINT IF EXISTS trips_end_lon_decimals_check;
ALTER TABLE trips ADD CONSTRAINT trips_end_lon_decimals_check 
    CHECK (end_lon IS NULL OR (end_lon::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$'));

-- إضافة قيود CHECK للتحقق من عدد الأرقام العشرية في جدول test_trips
ALTER TABLE test_trips DROP CONSTRAINT IF EXISTS test_trips_start_lat_decimals_check;
ALTER TABLE test_trips ADD CONSTRAINT test_trips_start_lat_decimals_check 
    CHECK (start_lat IS NULL OR (start_lat::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$'));

ALTER TABLE test_trips DROP CONSTRAINT IF EXISTS test_trips_start_lon_decimals_check;
ALTER TABLE test_trips ADD CONSTRAINT test_trips_start_lon_decimals_check 
    CHECK (start_lon IS NULL OR (start_lon::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$'));

ALTER TABLE test_trips DROP CONSTRAINT IF EXISTS test_trips_end_lat_decimals_check;
ALTER TABLE test_trips ADD CONSTRAINT test_trips_end_lat_decimals_check 
    CHECK (end_lat IS NULL OR (end_lat::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$'));

ALTER TABLE test_trips DROP CONSTRAINT IF EXISTS test_trips_end_lon_decimals_check;
ALTER TABLE test_trips ADD CONSTRAINT test_trips_end_lon_decimals_check 
    CHECK (end_lon IS NULL OR (end_lon::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$'));

-- إضافة قيود CHECK للتحقق من عدد الأرقام العشرية في جدول trip_locations
ALTER TABLE trip_locations DROP CONSTRAINT IF EXISTS trip_locations_latitude_decimals_check;
ALTER TABLE trip_locations ADD CONSTRAINT trip_locations_latitude_decimals_check 
    CHECK (latitude::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$');

ALTER TABLE trip_locations DROP CONSTRAINT IF EXISTS trip_locations_longitude_decimals_check;
ALTER TABLE trip_locations ADD CONSTRAINT trip_locations_longitude_decimals_check 
    CHECK (longitude::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$');

-- تحديث قواعد التحقق في جدول chiron_validation_rules
INSERT INTO chiron_validation_rules (
    field_name,
    field_type,
    min_decimal_places,
    max_decimal_places,
    min_value,
    max_value,
    is_required,
    error_code,
    validation_message
) VALUES
    -- قواعد التحقق من خط العرض (Latitude)
    ('vertrek.locatie.lat', 'coordinate', 5, 8, 49.0, 52.0, true, 'CH1405', 
     'خط العرض لنقطة الانطلاق يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.88012)'),
    
    ('aankomst.locatie.lat', 'coordinate', 5, 8, 49.0, 52.0, true, 'CH1405', 
     'خط العرض لنقطة الوصول يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.84873)'),
    
    -- قواعد التحقق من خط الطول (Longitude)
    ('vertrek.locatie.lon', 'coordinate', 5, 8, 2.0, 7.0, true, 'CH1405', 
     'خط الطول لنقطة الانطلاق يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.70134)'),
    
    ('aankomst.locatie.lon', 'coordinate', 5, 8, 2.0, 7.0, true, 'CH1405', 
     'خط الطول لنقطة الوصول يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35791)'),
    
    -- قواعد التحقق من وقت الانطلاق (Vertrektijd)
    ('vertrektijd', 'datetime', NULL, NULL, NULL, NULL, true, 'CH1405', 
     'وقت الانطلاق يجب أن يكون بتنسيق ISO 8601 الصحيح: YYYY-MM-DDTHH:MM:SS+00:00 (مثال: 2025-01-15T14:30:00+01:00)')
ON CONFLICT (field_name) DO UPDATE SET
    min_decimal_places = EXCLUDED.min_decimal_places,
    max_decimal_places = EXCLUDED.max_decimal_places,
    min_value = EXCLUDED.min_value,
    max_value = EXCLUDED.max_value,
    validation_message = EXCLUDED.validation_message,
    updated_at = CURRENT_TIMESTAMP;

-- إضافة تعليقات توضيحية للجداول
COMMENT ON CONSTRAINT trips_start_lat_decimals_check ON trips IS 
'يضمن أن خط العرض لنقطة البداية يحتوي على 5 أرقام عشرية على الأقل لتجنب خطأ CH1405';

COMMENT ON CONSTRAINT trips_start_lon_decimals_check ON trips IS 
'يضمن أن خط الطول لنقطة البداية يحتوي على 5 أرقام عشرية على الأقل لتجنب خطأ CH1405';

COMMENT ON CONSTRAINT trips_end_lat_decimals_check ON trips IS 
'يضمن أن خط العرض لنقطة الوصول يحتوي على 5 أرقام عشرية على الأقل لتجنب خطأ CH1405';

COMMENT ON CONSTRAINT trips_end_lon_decimals_check ON trips IS 
'يضمن أن خط الطول لنقطة الوصول يحتوي على 5 أرقام عشرية على الأقل لتجنب خطأ CH1405';

-- إنشاء دالة للتحقق من تنسيق الوقت
CREATE OR REPLACE FUNCTION validate_chiron_timestamp(ts TIMESTAMP WITH TIME ZONE)
RETURNS BOOLEAN AS $$
BEGIN
    -- التحقق من أن الوقت ليس في المستقبل البعيد أو الماضي البعيد
    IF ts < (CURRENT_TIMESTAMP - INTERVAL '1 year') OR 
       ts > (CURRENT_TIMESTAMP + INTERVAL '1 day') THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION validate_chiron_timestamp IS 'التحقق من صحة تنسيق الوقت المرسل إلى Chiron - يجب أن يكون ضمن نطاق معقول';

-- إضافة قيود للتحقق من صحة الأوقات في جدول trips
ALTER TABLE trips DROP CONSTRAINT IF EXISTS trips_start_time_valid_check;
ALTER TABLE trips ADD CONSTRAINT trips_start_time_valid_check 
    CHECK (validate_chiron_timestamp(start_time));

ALTER TABLE trips DROP CONSTRAINT IF EXISTS trips_end_time_valid_check;
ALTER TABLE trips ADD CONSTRAINT trips_end_time_valid_check 
    CHECK (end_time IS NULL OR validate_chiron_timestamp(end_time));

-- إضافة قيود للتحقق من صحة الأوقات في جدول test_trips
ALTER TABLE test_trips DROP CONSTRAINT IF EXISTS test_trips_start_time_valid_check;
ALTER TABLE test_trips ADD CONSTRAINT test_trips_start_time_valid_check 
    CHECK (start_time IS NULL OR validate_chiron_timestamp(start_time));

ALTER TABLE test_trips DROP CONSTRAINT IF EXISTS test_trips_end_time_valid_check;
ALTER TABLE test_trips ADD CONSTRAINT test_trips_end_time_valid_check 
    CHECK (end_time IS NULL OR validate_chiron_timestamp(end_time));

-- إنشاء view لعرض الرحلات مع الإحداثيات المنسقة
CREATE OR REPLACE VIEW trips_with_normalized_coords AS
SELECT 
    id,
    ritnummer,
    normalize_coordinate(start_lat) as start_lat_normalized,
    normalize_coordinate(start_lon) as start_lon_normalized,
    normalize_coordinate(end_lat) as end_lat_normalized,
    normalize_coordinate(end_lon) as end_lon_normalized,
    start_time,
    end_time,
    status,
    chiron_sync_state,
    validation_status
FROM trips;

COMMENT ON VIEW trips_with_normalized_coords IS 
'عرض الرحلات مع الإحداثيات المنسقة تلقائياً إلى 5 أرقام عشرية - يستخدم للتحقق قبل الإرسال إلى Chiron';

-- إنشاء view لعرض الرحلات الاختبارية مع الإحداثيات المنسقة
CREATE OR REPLACE VIEW test_trips_with_normalized_coords AS
SELECT 
    id,
    ritnummer,
    normalize_coordinate(start_lat) as start_lat_normalized,
    normalize_coordinate(start_lon) as start_lon_normalized,
    normalize_coordinate(end_lat) as end_lat_normalized,
    normalize_coordinate(end_lon) as end_lon_normalized,
    start_time,
    end_time,
    sync_status,
    validation_status
FROM test_trips;

COMMENT ON VIEW test_trips_with_normalized_coords IS 
'عرض الرحلات الاختبارية مع الإحداثيات المنسقة تلقائياً إلى 5 أرقام عشرية - يستخدم للتحقق قبل الإرسال إلى Chiron';

-- تحديث قواعد التحقق من صحة الإحداثيات في chiron_validation_rules
-- إضافة قواعد للتحقق من أن الإحداثيات تحتوي على 5 أرقام عشرية على الأقل

-- حذف القواعد القديمة إذا كانت موجودة
DELETE FROM chiron_validation_rules WHERE field_name IN ('vertrek_breedtegraad', 'vertrek_lengtegraad', 'aankomst_breedtegraad', 'aankomst_lengtegraad');

-- إضافة قواعد جديدة للإحداثيات
INSERT INTO chiron_validation_rules (field_name, field_type, min_decimal_places, max_decimal_places, min_value, max_value, is_required, error_code, validation_message) VALUES
('vertrek_breedtegraad', 'coordinate', 5, 8, 49.0, 52.0, true, 'CH1405', 'خط العرض لنقطة الانطلاق يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.88012)'),
('vertrek_lengtegraad', 'coordinate', 5, 8, 2.0, 7.0, true, 'CH1405', 'خط الطول لنقطة الانطلاق يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35178)'),
('aankomst_breedtegraad', 'coordinate', 5, 8, 49.0, 52.0, true, 'CH1405', 'خط العرض لنقطة الوصول يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.84873)'),
('aankomst_lengtegraad', 'coordinate', 5, 8, 2.0, 7.0, true, 'CH1405', 'خط الطول لنقطة الوصول يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35791)');

-- إضافة قيود CHECK على جدول trips للتحقق من تنسيق الإحداثيات
-- التحقق من أن الإحداثيات تحتوي على 5 أرقام عشرية على الأقل باستخدام Regular Expression

-- حذف القيود القديمة إذا كانت موجودة
ALTER TABLE trips DROP CONSTRAINT IF EXISTS trips_start_lat_decimals_check;
ALTER TABLE trips DROP CONSTRAINT IF EXISTS trips_start_lon_decimals_check;
ALTER TABLE trips DROP CONSTRAINT IF EXISTS trips_end_lat_decimals_check;
ALTER TABLE trips DROP CONSTRAINT IF EXISTS trips_end_lon_decimals_check;

-- إضافة قيود جديدة
ALTER TABLE trips ADD CONSTRAINT trips_start_lat_decimals_check 
    CHECK (start_lat IS NULL OR start_lat::text ~ '^\-?[0-9]+\.[0-9]{5,}$');

ALTER TABLE trips ADD CONSTRAINT trips_start_lon_decimals_check 
    CHECK (start_lon IS NULL OR start_lon::text ~ '^\-?[0-9]+\.[0-9]{5,}$');

ALTER TABLE trips ADD CONSTRAINT trips_end_lat_decimals_check 
    CHECK (end_lat IS NULL OR end_lat::text ~ '^\-?[0-9]+\.[0-9]{5,}$');

ALTER TABLE trips ADD CONSTRAINT trips_end_lon_decimals_check 
    CHECK (end_lon IS NULL OR end_lon::text ~ '^\-?[0-9]+\.[0-9]{5,}$');

-- إضافة نفس القيود على جدول test_trips
ALTER TABLE test_trips DROP CONSTRAINT IF EXISTS test_trips_start_lat_decimals_check;
ALTER TABLE test_trips DROP CONSTRAINT IF EXISTS test_trips_start_lon_decimals_check;
ALTER TABLE test_trips DROP CONSTRAINT IF EXISTS test_trips_end_lat_decimals_check;
ALTER TABLE test_trips DROP CONSTRAINT IF EXISTS test_trips_end_lon_decimals_check;

ALTER TABLE test_trips ADD CONSTRAINT test_trips_start_lat_decimals_check 
    CHECK (start_lat IS NULL OR start_lat::text ~ '^\-?[0-9]+\.[0-9]{5,}$');

ALTER TABLE test_trips ADD CONSTRAINT test_trips_start_lon_decimals_check 
    CHECK (start_lon IS NULL OR start_lon::text ~ '^\-?[0-9]+\.[0-9]{5,}$');

ALTER TABLE test_trips ADD CONSTRAINT test_trips_end_lat_decimals_check 
    CHECK (end_lat IS NULL OR end_lat::text ~ '^\-?[0-9]+\.[0-9]{5,}$');

ALTER TABLE test_trips ADD CONSTRAINT test_trips_end_lon_decimals_check 
    CHECK (end_lon IS NULL OR end_lon::text ~ '^\-?[0-9]+\.[0-9]{5,}$');

-- إضافة قيود CHECK على جدول trip_locations
ALTER TABLE trip_locations DROP CONSTRAINT IF EXISTS trip_locations_latitude_decimals_check;
ALTER TABLE trip_locations DROP CONSTRAINT IF EXISTS trip_locations_longitude_decimals_check;

ALTER TABLE trip_locations ADD CONSTRAINT trip_locations_latitude_decimals_check 
    CHECK (latitude::text ~ '^\-?[0-9]+\.[0-9]{5,}$');

ALTER TABLE trip_locations ADD CONSTRAINT trip_locations_longitude_decimals_check 
    CHECK (longitude::text ~ '^\-?[0-9]+\.[0-9]{5,}$');

-- تحديث تعليق جدول chiron_validation_log لتوضيح أمثلة الإحداثيات الصحيحة
COMMENT ON TABLE chiron_validation_log IS 'سجل جميع عمليات التحقق من صحة البيانات قبل إرسالها إلى Chiron

أمثلة على التحقق من الإحداثيات:
- ❌ خطأ: 50.88 (رقمين عشريين فقط)
- ✅ صحيح: 50.88000 (5 أرقام عشرية)
- ✅ صحيح: 50.88012 (5 أرقام عشرية)

استخدم دالة normalizeCoord لتنسيق الإحداثيات:
function normalizeCoord(value: number): number {
  return Number(value.toFixed(5));
}';

-- تحديث تعليقات أعمدة الإحداثيات في جدول trips
COMMENT ON COLUMN trips.start_lat IS 'خط العرض لنقطة البداية - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.88012) لتجنب خطأ CH1405';
COMMENT ON COLUMN trips.start_lon IS 'خط الطول لنقطة البداية - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35178) لتجنب خطأ CH1405';
COMMENT ON COLUMN trips.end_lat IS 'خط العرض لنقطة الوصول - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.88012) لتجنب خطأ CH1405';
COMMENT ON COLUMN trips.end_lon IS 'خط الطول لنقطة الوصول - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35178) لتجنب خطأ CH1405';

-- تحديث تعليقات أعمدة الإحداثيات في جدول test_trips
COMMENT ON COLUMN test_trips.start_lat IS 'خط العرض لنقطة البداية - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.88012) لتجنب خطأ CH1405';
COMMENT ON COLUMN test_trips.start_lon IS 'خط الطول لنقطة البداية - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35178) لتجنب خطأ CH1405';
COMMENT ON COLUMN test_trips.end_lat IS 'خط العرض لنقطة الوصول - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.88012) لتجنب خطأ CH1405';
COMMENT ON COLUMN test_trips.end_lon IS 'خط الطول لنقطة الوصول - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35178) لتجنب خطأ CH1405';

-- دالة للتحقق من صحة الإحداثيات (يجب أن تحتوي على 5 أرقام عشرية على الأقل)
CREATE OR REPLACE FUNCTION validate_coordinate_decimals(coord NUMERIC)
RETURNS BOOLEAN AS $$
BEGIN
    -- التحقق من أن الإحداثية تحتوي على 5 أرقام عشرية على الأقل
    -- مثال: 50.85030 ✅ صحيح
    -- مثال: 50.85 ❌ خطأ
    RETURN coord::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION validate_coordinate_decimals IS 'التحقق من أن الإحداثية تحتوي على 5 أرقام عشرية على الأقل لتجنب خطأ CH1405 من Chiron';

-- إضافة قيود CHECK على جدول trips للتأكد من صحة الإحداثيات
ALTER TABLE trips DROP CONSTRAINT IF EXISTS trips_start_lat_decimals_check;
ALTER TABLE trips DROP CONSTRAINT IF EXISTS trips_start_lon_decimals_check;
ALTER TABLE trips DROP CONSTRAINT IF EXISTS trips_end_lat_decimals_check;
ALTER TABLE trips DROP CONSTRAINT IF EXISTS trips_end_lon_decimals_check;

ALTER TABLE trips ADD CONSTRAINT trips_start_lat_decimals_check 
    CHECK (start_lat IS NULL OR start_lat::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$');

ALTER TABLE trips ADD CONSTRAINT trips_start_lon_decimals_check 
    CHECK (start_lon IS NULL OR start_lon::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$');

ALTER TABLE trips ADD CONSTRAINT trips_end_lat_decimals_check 
    CHECK (end_lat IS NULL OR end_lat::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$');

ALTER TABLE trips ADD CONSTRAINT trips_end_lon_decimals_check 
    CHECK (end_lon IS NULL OR end_lon::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$');

COMMENT ON CONSTRAINT trips_start_lat_decimals_check ON trips IS 'يضمن أن start_lat يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.85030) لتجنب خطأ CH1405';
COMMENT ON CONSTRAINT trips_start_lon_decimals_check ON trips IS 'يضمن أن start_lon يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35170) لتجنب خطأ CH1405';
COMMENT ON CONSTRAINT trips_end_lat_decimals_check ON trips IS 'يضمن أن end_lat يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.85030) لتجنب خطأ CH1405';
COMMENT ON CONSTRAINT trips_end_lon_decimals_check ON trips IS 'يضمن أن end_lon يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35170) لتجنب خطأ CH1405';

-- إضافة قيود CHECK على جدول test_trips
ALTER TABLE test_trips DROP CONSTRAINT IF EXISTS test_trips_start_lat_decimals_check;
ALTER TABLE test_trips DROP CONSTRAINT IF EXISTS test_trips_start_lon_decimals_check;
ALTER TABLE test_trips DROP CONSTRAINT IF EXISTS test_trips_end_lat_decimals_check;
ALTER TABLE test_trips DROP CONSTRAINT IF EXISTS test_trips_end_lon_decimals_check;

ALTER TABLE test_trips ADD CONSTRAINT test_trips_start_lat_decimals_check 
    CHECK (start_lat IS NULL OR start_lat::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$');

ALTER TABLE test_trips ADD CONSTRAINT test_trips_start_lon_decimals_check 
    CHECK (start_lon IS NULL OR start_lon::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$');

ALTER TABLE test_trips ADD CONSTRAINT test_trips_end_lat_decimals_check 
    CHECK (end_lat IS NULL OR end_lat::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$');

ALTER TABLE test_trips ADD CONSTRAINT test_trips_end_lon_decimals_check 
    CHECK (end_lon IS NULL OR end_lon::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$');

-- إضافة قيود CHECK على جدول trip_locations
ALTER TABLE trip_locations DROP CONSTRAINT IF EXISTS trip_locations_latitude_decimals_check;
ALTER TABLE trip_locations DROP CONSTRAINT IF EXISTS trip_locations_longitude_decimals_check;

ALTER TABLE trip_locations ADD CONSTRAINT trip_locations_latitude_decimals_check 
    CHECK (latitude::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$');

ALTER TABLE trip_locations ADD CONSTRAINT trip_locations_longitude_decimals_check 
    CHECK (longitude::TEXT ~ '^\-?[0-9]+\.[0-9]{5,}$');

-- تحديث التعليقات على الأعمدة لتوضيح المتطلبات
COMMENT ON COLUMN trips.start_lat IS 'خط العرض لنقطة البداية - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.88012) لتجنب خطأ CH1405';
COMMENT ON COLUMN trips.start_lon IS 'خط الطول لنقطة البداية - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35178) لتجنب خطأ CH1405';
COMMENT ON COLUMN trips.end_lat IS 'خط العرض لنقطة الوصول - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.88012) لتجنب خطأ CH1405';
COMMENT ON COLUMN trips.end_lon IS 'خط الطول لنقطة الوصول - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35178) لتجنب خطأ CH1405';

COMMENT ON COLUMN test_trips.start_lat IS 'خط العرض لنقطة البداية - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.88012) لتجنب خطأ CH1405';
COMMENT ON COLUMN test_trips.start_lon IS 'خط الطول لنقطة البداية - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35178) لتجنب خطأ CH1405';
COMMENT ON COLUMN test_trips.end_lat IS 'خط العرض لنقطة الوصول - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 50.88012) لتجنب خطأ CH1405';
COMMENT ON COLUMN test_trips.end_lon IS 'خط الطول لنقطة الوصول - يجب أن يحتوي على 5 أرقام عشرية على الأقل (مثال: 4.35178) لتجنب خطأ CH1405';

-- تحديث جدول chiron_validation_log لتوضيح أمثلة الإحداثيات
COMMENT ON TABLE chiron_validation_log IS 'سجل جميع عمليات التحقق من صحة البيانات قبل إرسالها إلى Chiron

أمثلة على التحقق من الإحداثيات:
- ❌ خطأ: 50.88 (رقمين عشريين فقط)
- ✅ صحيح: 50.88000 (5 أرقام عشرية)
- ✅ صحيح: 50.88012 (5 أرقام عشرية)

استخدم دالة normalizeCoord لتنسيق الإحداثيات:
function normalizeCoord(value: number): number {
  return Number(value.toFixed(5));
}';

-- إنشاء فهرس لتسريع البحث عن الإحداثيات غير الصحيحة
CREATE INDEX IF NOT EXISTS idx_chiron_validation_log_invalid_coords 
ON chiron_validation_log(field_name, is_valid) 
WHERE field_name IN ('start_lat', 'start_lon', 'end_lat', 'end_lon') AND is_valid = false;

-- إضافة حقول جديدة لتخزين الإحداثيات المُنسقة بشكل صحيح (5-6 أرقام عشرية)
-- في جدول trips
ALTER TABLE trips 
ADD COLUMN IF NOT EXISTS vertrek_lat DECIMAL(10,6),
ADD COLUMN IF NOT EXISTS vertrek_lon DECIMAL(11,6),
ADD COLUMN IF NOT EXISTS aankomst_lat DECIMAL(10,6),
ADD COLUMN IF NOT EXISTS aankomst_lon DECIMAL(11,6);

-- إضافة تعليقات توضيحية
COMMENT ON COLUMN trips.vertrek_lat IS 'خط العرض لنقطة البداية (Vertrek) - مُنسق بـ 6 أرقام عشرية للإرسال إلى Chiron';
COMMENT ON COLUMN trips.vertrek_lon IS 'خط الطول لنقطة البداية (Vertrek) - مُنسق بـ 6 أرقام عشرية للإرسال إلى Chiron';
COMMENT ON COLUMN trips.aankomst_lat IS 'خط العرض لنقطة الوصول (Aankomst) - مُنسق بـ 6 أرقام عشرية للإرسال إلى Chiron';
COMMENT ON COLUMN trips.aankomst_lon IS 'خط الطول لنقطة الوصول (Aankomst) - مُنسق بـ 6 أرقام عشرية للإرسال إلى Chiron';

-- إضافة نفس الحقول في جدول test_trips
ALTER TABLE test_trips 
ADD COLUMN IF NOT EXISTS vertrek_lat DECIMAL(10,6),
ADD COLUMN IF NOT EXISTS vertrek_lon DECIMAL(11,6),
ADD COLUMN IF NOT EXISTS aankomst_lat DECIMAL(10,6),
ADD COLUMN IF NOT EXISTS aankomst_lon DECIMAL(11,6);

-- إضافة تعليقات توضيحية
COMMENT ON COLUMN test_trips.vertrek_lat IS 'خط العرض لنقطة البداية (Vertrek) - مُنسق بـ 6 أرقام عشرية للإرسال إلى Chiron';
COMMENT ON COLUMN test_trips.vertrek_lon IS 'خط الطول لنقطة البداية (Vertrek) - مُنسق بـ 6 أرقام عشرية للإرسال إلى Chiron';
COMMENT ON COLUMN test_trips.aankomst_lat IS 'خط العرض لنقطة الوصول (Aankomst) - مُنسق بـ 6 أرقام عشرية للإرسال إلى Chiron';
COMMENT ON COLUMN test_trips.aankomst_lon IS 'خط الطول لنقطة الوصول (Aankomst) - مُنسق بـ 6 أرقام عشرية للإرسال إلى Chiron';

-- إنشاء دالة لتنسيق الإحداثيات تلقائياً
CREATE OR REPLACE FUNCTION format_coordinates_for_chiron()
RETURNS TRIGGER AS $$
BEGIN
    -- تنسيق إحداثيات البداية (Vertrek)
    IF NEW.start_lat IS NOT NULL THEN
        NEW.vertrek_lat := ROUND(NEW.start_lat::numeric, 6);
    END IF;
    
    IF NEW.start_lon IS NOT NULL THEN
        NEW.vertrek_lon := ROUND(NEW.start_lon::numeric, 6);
    END IF;
    
    -- تنسيق إحداثيات الوصول (Aankomst)
    IF NEW.end_lat IS NOT NULL THEN
        NEW.aankomst_lat := ROUND(NEW.end_lat::numeric, 6);
    END IF;
    
    IF NEW.end_lon IS NOT NULL THEN
        NEW.aankomst_lon := ROUND(NEW.end_lon::numeric, 6);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إضافة Trigger لجدول trips
DROP TRIGGER IF EXISTS format_trips_coordinates ON trips;
CREATE TRIGGER format_trips_coordinates
    BEFORE INSERT OR UPDATE ON trips
    FOR EACH ROW
    EXECUTE FUNCTION format_coordinates_for_chiron();

-- إضافة Trigger لجدول test_trips
DROP TRIGGER IF EXISTS format_test_trips_coordinates ON test_trips;
CREATE TRIGGER format_test_trips_coordinates
    BEFORE INSERT OR UPDATE ON test_trips
    FOR EACH ROW
    EXECUTE FUNCTION format_coordinates_for_chiron();

-- إنشاء جدول لتتبع تنسيق الإحداثيات
CREATE TABLE IF NOT EXISTS chiron_coordinate_formatting_log (
    id BIGSERIAL PRIMARY KEY,
    trip_id BIGINT,
    test_trip_id BIGINT,
    message_type VARCHAR(20) NOT NULL CHECK (message_type IN ('vertrek', 'aankomst')),
    original_lat DECIMAL(10,8),
    original_lon DECIMAL(11,8),
    formatted_lat DECIMAL(10,6),
    formatted_lon DECIMAL(11,6),
    formatting_method VARCHAR(50) DEFAULT 'auto_trigger',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_coord_formatting_trip_id ON chiron_coordinate_formatting_log(trip_id);
CREATE INDEX idx_coord_formatting_test_trip_id ON chiron_coordinate_formatting_log(test_trip_id);
CREATE INDEX idx_coord_formatting_message_type ON chiron_coordinate_formatting_log(message_type);

COMMENT ON TABLE chiron_coordinate_formatting_log IS 'سجل تنسيق الإحداثيات - يتتبع كيفية تحويل الإحداثيات من الشكل الأصلي إلى الشكل المُنسق للإرسال إلى Chiron';
COMMENT ON COLUMN chiron_coordinate_formatting_log.message_type IS 'نوع الرسالة: vertrek (بداية) أو aankomst (وصول)';
COMMENT ON COLUMN chiron_coordinate_formatting_log.original_lat IS 'خط العرض الأصلي قبل التنسيق';
COMMENT ON COLUMN chiron_coordinate_formatting_log.original_lon IS 'خط الطول الأصلي قبل التنسيق';
COMMENT ON COLUMN chiron_coordinate_formatting_log.formatted_lat IS 'خط العرض بعد التنسيق (6 أرقام عشرية)';
COMMENT ON COLUMN chiron_coordinate_formatting_log.formatted_lon IS 'خط الطول بعد التنسيق (6 أرقام عشرية)';
COMMENT ON COLUMN chiron_coordinate_formatting_log.formatting_method IS 'طريقة التنسيق: auto_trigger (تلقائي)، manual (يدوي)، api_correction (تصحيح من API)';

-- ===================================================================
-- إصلاح شامل لدقة الإحداثيات الجغرافية في قاعدة البيانات
-- ===================================================================

-- 1. إنشاء دالة لتنسيق الإحداثيات تلقائياً (5-6 أرقام عشرية)
CREATE OR REPLACE FUNCTION format_coordinate(coord NUMERIC) 
RETURNS NUMERIC AS $$
BEGIN
    -- إذا كانت القيمة NULL، نرجع NULL
    IF coord IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- تنسيق الإحداثية إلى 6 أرقام عشرية
    RETURN ROUND(coord::NUMERIC, 6);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION format_coordinate IS 'تنسيق الإحداثيات الجغرافية إلى 6 أرقام عشرية - يضمن التوافق مع Chiron API';

-- 2. إنشاء trigger function لتنسيق إحداثيات trips تلقائياً
CREATE OR REPLACE FUNCTION auto_format_trip_coordinates()
RETURNS TRIGGER AS $$
BEGIN
    -- تنسيق إحداثيات البداية والنهاية
    NEW.start_lat := format_coordinate(NEW.start_lat);
    NEW.start_lon := format_coordinate(NEW.start_lon);
    NEW.end_lat := format_coordinate(NEW.end_lat);
    NEW.end_lon := format_coordinate(NEW.end_lon);
    
    -- تنسيق إحداثيات Vertrek و Aankomst
    NEW.vertrek_lat := format_coordinate(NEW.vertrek_lat);
    NEW.vertrek_lon := format_coordinate(NEW.vertrek_lon);
    NEW.aankomst_lat := format_coordinate(NEW.aankomst_lat);
    NEW.aankomst_lon := format_coordinate(NEW.aankomst_lon);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION auto_format_trip_coordinates IS 'Trigger function لتنسيق إحداثيات الرحلات تلقائياً قبل الإدراج أو التحديث';

-- 3. إنشاء trigger function لتنسيق إحداثيات test_trips تلقائياً
CREATE OR REPLACE FUNCTION auto_format_test_trip_coordinates()
RETURNS TRIGGER AS $$
BEGIN
    -- تنسيق إحداثيات البداية والنهاية
    NEW.start_lat := format_coordinate(NEW.start_lat);
    NEW.start_lon := format_coordinate(NEW.start_lon);
    NEW.end_lat := format_coordinate(NEW.end_lat);
    NEW.end_lon := format_coordinate(NEW.end_lon);
    
    -- تنسيق إحداثيات Vertrek و Aankomst
    NEW.vertrek_lat := format_coordinate(NEW.vertrek_lat);
    NEW.vertrek_lon := format_coordinate(NEW.vertrek_lon);
    NEW.aankomst_lat := format_coordinate(NEW.aankomst_lat);
    NEW.aankomst_lon := format_coordinate(NEW.aankomst_lon);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION auto_format_test_trip_coordinates IS 'Trigger function لتنسيق إحداثيات الرحلات الاختبارية تلقائياً قبل الإدراج أو التحديث';

-- 4. إنشاء trigger function لتنسيق إحداثيات trip_locations تلقائياً
CREATE OR REPLACE FUNCTION auto_format_trip_location_coordinates()
RETURNS TRIGGER AS $$
BEGIN
    -- تنسيق إحداثيات الموقع
    NEW.latitude := format_coordinate(NEW.latitude);
    NEW.longitude := format_coordinate(NEW.longitude);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION auto_format_trip_location_coordinates IS 'Trigger function لتنسيق إحداثيات مواقع الرحلات تلقائياً قبل الإدراج أو التحديث';

-- 5. إضافة triggers على جدول trips
DROP TRIGGER IF EXISTS trigger_format_trip_coordinates ON trips;
CREATE TRIGGER trigger_format_trip_coordinates
    BEFORE INSERT OR UPDATE ON trips
    FOR EACH ROW
    EXECUTE FUNCTION auto_format_trip_coordinates();

COMMENT ON TRIGGER trigger_format_trip_coordinates ON trips IS 'ينسق الإحداثيات تلقائياً إلى 6 أرقام عشرية قبل الإدراج أو التحديث';

-- 6. إضافة triggers على جدول test_trips
DROP TRIGGER IF EXISTS trigger_format_test_trip_coordinates ON test_trips;
CREATE TRIGGER trigger_format_test_trip_coordinates
    BEFORE INSERT OR UPDATE ON test_trips
    FOR EACH ROW
    EXECUTE FUNCTION auto_format_test_trip_coordinates();

COMMENT ON TRIGGER trigger_format_test_trip_coordinates ON test_trips IS 'ينسق الإحداثيات تلقائياً إلى 6 أرقام عشرية قبل الإدراج أو التحديث';

-- 7. إضافة triggers على جدول trip_locations
DROP TRIGGER IF EXISTS trigger_format_trip_location_coordinates ON trip_locations;
CREATE TRIGGER trigger_format_trip_location_coordinates
    BEFORE INSERT OR UPDATE ON trip_locations
    FOR EACH ROW
    EXECUTE FUNCTION auto_format_trip_location_coordinates();

COMMENT ON TRIGGER trigger_format_trip_location_coordinates ON trip_locations IS 'ينسق الإحداثيات تلقائياً إلى 6 أرقام عشرية قبل الإدراج أو التحديث';

-- 8. تحديث جميع الإحداثيات الموجودة في trips
UPDATE trips SET
    start_lat = format_coordinate(start_lat),
    start_lon = format_coordinate(start_lon),
    end_lat = format_coordinate(end_lat),
    end_lon = format_coordinate(end_lon),
    vertrek_lat = format_coordinate(vertrek_lat),
    vertrek_lon = format_coordinate(vertrek_lon),
    aankomst_lat = format_coordinate(aankomst_lat),
    aankomst_lon = format_coordinate(aankomst_lon)
WHERE 
    start_lat IS NOT NULL OR 
    start_lon IS NOT NULL OR 
    end_lat IS NOT NULL OR 
    end_lon IS NOT NULL OR
    vertrek_lat IS NOT NULL OR
    vertrek_lon IS NOT NULL OR
    aankomst_lat IS NOT NULL OR
    aankomst_lon IS NOT NULL;

-- 9. تحديث جميع الإحداثيات الموجودة في test_trips
UPDATE test_trips SET
    start_lat = format_coordinate(start_lat),
    start_lon = format_coordinate(start_lon),
    end_lat = format_coordinate(end_lat),
    end_lon = format_coordinate(end_lon),
    vertrek_lat = format_coordinate(vertrek_lat),
    vertrek_lon = format_coordinate(vertrek_lon),
    aankomst_lat = format_coordinate(aankomst_lat),
    aankomst_lon = format_coordinate(aankomst_lon)
WHERE 
    start_lat IS NOT NULL OR 
    start_lon IS NOT NULL OR 
    end_lat IS NOT NULL OR 
    end_lon IS NOT NULL OR
    vertrek_lat IS NOT NULL OR
    vertrek_lon IS NOT NULL OR
    aankomst_lat IS NOT NULL OR
    aankomst_lon IS NOT NULL;

-- 10. تحديث جميع الإحداثيات الموجودة في trip_locations
UPDATE trip_locations SET
    latitude = format_coordinate(latitude),
    longitude = format_coordinate(longitude)
WHERE 
    latitude IS NOT NULL OR 
    longitude IS NOT NULL;

-- 11. إنشاء view لعرض الإحداثيات المنسقة بشكل صحيح
CREATE OR REPLACE VIEW v_trips_with_formatted_coordinates AS
SELECT 
    id,
    ritnummer,
    -- إحداثيات البداية (منسقة)
    ROUND(start_lat::NUMERIC, 6) as start_lat_formatted,
    ROUND(start_lon::NUMERIC, 6) as start_lon_formatted,
    -- إحداثيات النهاية (منسقة)
    ROUND(end_lat::NUMERIC, 6) as end_lat_formatted,
    ROUND(end_lon::NUMERIC, 6) as end_lon_formatted,
    -- إحداثيات Vertrek (منسقة)
    ROUND(vertrek_lat::NUMERIC, 6) as vertrek_lat_formatted,
    ROUND(vertrek_lon::NUMERIC, 6) as vertrek_lon_formatted,
    -- إحداثيات Aankomst (منسقة)
    ROUND(aankomst_lat::NUMERIC, 6) as aankomst_lat_formatted,
    ROUND(aankomst_lon::NUMERIC, 6) as aankomst_lon_formatted,
    -- باقي الأعمدة
    company_id,
    driver_id,
    vehicle_id,
    start_time,
    end_time,
    status,
    chiron_sync_state
FROM trips;

COMMENT ON VIEW v_trips_with_formatted_coordinates IS 'عرض الرحلات مع الإحداثيات المنسقة بشكل صحيح (6 أرقام عشرية) - استخدم هذا View عند الإرسال إلى Chiron';

-- 12. إنشاء view لعرض إحداثيات test_trips المنسقة
CREATE OR REPLACE VIEW v_test_trips_with_formatted_coordinates AS
SELECT 
    id,
    ritnummer,
    message_type,
    -- إحداثيات البداية (منسقة)
    ROUND(start_lat::NUMERIC, 6) as start_lat_formatted,
    ROUND(start_lon::NUMERIC, 6) as start_lon_formatted,
    -- إحداثيات النهاية (منسقة)
    ROUND(end_lat::NUMERIC, 6) as end_lat_formatted,
    ROUND(end_lon::NUMERIC, 6) as end_lon_formatted,
    -- إحداثيات Vertrek (منسقة)
    ROUND(vertrek_lat::NUMERIC, 6) as vertrek_lat_formatted,
    ROUND(vertrek_lon::NUMERIC, 6) as vertrek_lon_formatted,
    -- إحداثيات Aankomst (منسقة)
    ROUND(aankomst_lat::NUMERIC, 6) as aankomst_lat_formatted,
    ROUND(aankomst_lon::NUMERIC, 6) as aankomst_lon_formatted,
    -- باقي الأعمدة
    company_id,
    driver_id,
    vehicle_id,
    test_sequence_number,
    sync_status,
    validation_status
FROM test_trips;

COMMENT ON VIEW v_test_trips_with_formatted_coordinates IS 'عرض الرحلات الاختبارية مع الإحداثيات المنسقة بشكل صحيح (6 أرقام عشرية) - استخدم هذا View عند الإرسال إلى Chiron';

-- 13. إنشاء دالة للتحقق من صحة الإحداثيات قبل الإرسال إلى Chiron
CREATE OR REPLACE FUNCTION validate_chiron_coordinates(
    p_lat NUMERIC,
    p_lon NUMERIC
) RETURNS BOOLEAN AS $$
DECLARE
    v_lat_text TEXT;
    v_lon_text TEXT;
    v_lat_decimals INTEGER;
    v_lon_decimals INTEGER;
BEGIN
    -- التحقق من أن القيم ليست NULL
    IF p_lat IS NULL OR p_lon IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- تحويل القيم إلى نص للتحقق من عدد الأرقام العشرية
    v_lat_text := p_lat::TEXT;
    v_lon_text := p_lon::TEXT;
    
    -- حساب عدد الأرقام العشرية
    v_lat_decimals := LENGTH(SPLIT_PART(v_lat_text, '.', 2));
    v_lon_decimals := LENGTH(SPLIT_PART(v_lon_text, '.', 2));
    
    -- التحقق من أن عدد الأرقام العشرية >= 5
    IF v_lat_decimals < 5 OR v_lon_decimals < 5 THEN
        RETURN FALSE;
    END IF;
    
    -- التحقق من النطاق الصحيح للإحداثيات
    -- Latitude: -90 to 90
    -- Longitude: -180 to 180
    IF p_lat < -90 OR p_lat > 90 OR p_lon < -180 OR p_lon > 180 THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION validate_chiron_coordinates IS 'التحقق من صحة الإحداثيات قبل الإرسال إلى Chiron - يجب أن تحتوي على 5 أرقام عشرية على الأقل';

-- 14. إضافة check constraints للتحقق من صحة الإحداثيات
-- (ملاحظة: هذه الـ constraints موجودة بالفعل، لكن سنتأكد من تطبيقها)

-- 15. إنشاء جدول لتسجيل أخطاء التنسيق
CREATE TABLE IF NOT EXISTS coordinate_formatting_errors (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id BIGINT NOT NULL,
    field_name VARCHAR(50) NOT NULL,
    original_value NUMERIC,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_coord_errors_table_record ON coordinate_formatting_errors(table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_coord_errors_created_at ON coordinate_formatting_errors(created_at);

COMMENT ON TABLE coordinate_formatting_errors IS 'سجل أخطاء تنسيق الإحداثيات - يساعد في تشخيص المشاكل';

-- 16. منح الصلاحيات للـ views والدوال الجديدة
GRANT SELECT ON v_trips_with_formatted_coordinates TO app20251225073911jaqqaxdfir_v1_user;
GRANT SELECT ON v_trips_with_formatted_coordinates TO app20251225073911jaqqaxdfir_v1_admin_user;

GRANT SELECT ON v_test_trips_with_formatted_coordinates TO app20251225073911jaqqaxdfir_v1_user;
GRANT SELECT ON v_test_trips_with_formatted_coordinates TO app20251225073911jaqqaxdfir_v1_admin_user;

GRANT ALL ON coordinate_formatting_errors TO app20251225073911jaqqaxdfir_v1_user;
GRANT ALL ON coordinate_formatting_errors TO app20251225073911jaqqaxdfir_v1_admin_user;

-- ===================================================================
-- ملاحظات مهمة للمطورين:
-- ===================================================================
-- 1. جميع الإحداثيات الآن يتم تنسيقها تلقائياً إلى 6 أرقام عشرية
-- 2. استخدم الـ views (v_trips_with_formatted_coordinates) عند الإرسال إلى Chiron
-- 3. الـ triggers تعمل تلقائياً عند INSERT أو UPDATE
-- 4. استخدم دالة validate_chiron_coordinates() للتحقق قبل الإرسال
-- 5. لا تستخدم toFixed() أو Math.round() في الكود - الـ database يتولى التنسيق
-- ===================================================================

-- حذف جميع التعريفات المكررة لدالة format_coordinate
DROP FUNCTION IF EXISTS format_coordinate(numeric) CASCADE;

-- إنشاء الدالة بشكل صحيح مرة واحدة فقط
CREATE OR REPLACE FUNCTION format_coordinate(coord numeric)
RETURNS numeric
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    -- تنسيق الإحداثيات إلى 6 أرقام عشرية
    -- هذا يضمن التوافق مع متطلبات Chiron API
    RETURN ROUND(coord::numeric, 6);
END;
$$;

COMMENT ON FUNCTION format_coordinate(numeric) IS 'تنسيق الإحداثيات الجغرافية إلى 6 أرقام عشرية للتوافق مع Chiron API - يمنع أخطاء CH1405';

-- حذف جميع التعريفات المكررة لدالة format_coordinate
DROP FUNCTION IF EXISTS format_coordinate(numeric) CASCADE;
DROP FUNCTION IF EXISTS format_coordinate(numeric, integer) CASCADE;

-- إعادة إنشاء الدالة بشكل صحيح
CREATE OR REPLACE FUNCTION format_coordinate(coord numeric, decimal_places integer DEFAULT 6)
RETURNS numeric
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    -- تنسيق الإحداثية بعدد محدد من الأرقام العشرية (افتراضي 6)
    RETURN ROUND(coord::numeric, decimal_places);
END;
$$;

COMMENT ON FUNCTION format_coordinate(numeric, integer) IS 'تنسيق الإحداثيات الجغرافية بعدد محدد من الأرقام العشرية (افتراضي 6) للإرسال إلى Chiron API';

-- جدول روابط الفواتير القابلة للمشاركة
CREATE TABLE invoice_share_links (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL,
    share_token VARCHAR(100) NOT NULL UNIQUE,
    qr_code_url TEXT,
    view_count INTEGER DEFAULT 0,
    last_viewed_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- فهارس لتحسين الأداء
CREATE INDEX idx_invoice_share_links_invoice_id ON invoice_share_links(invoice_id);
CREATE INDEX idx_invoice_share_links_share_token ON invoice_share_links(share_token);
CREATE INDEX idx_invoice_share_links_is_active ON invoice_share_links(is_active);
CREATE INDEX idx_invoice_share_links_expires_at ON invoice_share_links(expires_at);

-- تعليقات توضيحية
COMMENT ON TABLE invoice_share_links IS 'روابط مشاركة الفواتير مع العملاء - تحتوي على رابط دائم وQR Code';
COMMENT ON COLUMN invoice_share_links.invoice_id IS 'معرف الفاتورة المرتبطة';
COMMENT ON COLUMN invoice_share_links.share_token IS 'رمز فريد للرابط (مثل: INV-2025-ABC123) - يستخدم في URL';
COMMENT ON COLUMN invoice_share_links.qr_code_url IS 'رابط صورة QR Code - يتم إنشاؤه تلقائياً ويحتوي على رابط الفاتورة';
COMMENT ON COLUMN invoice_share_links.view_count IS 'عدد مرات عرض الفاتورة من قبل العملاء';
COMMENT ON COLUMN invoice_share_links.last_viewed_at IS 'تاريخ آخر مشاهدة للفاتورة';
COMMENT ON COLUMN invoice_share_links.expires_at IS 'تاريخ انتهاء صلاحية الرابط (اختياري - NULL للروابط الدائمة)';
COMMENT ON COLUMN invoice_share_links.is_active IS 'هل الرابط نشط ويمكن استخدامه';

-- جدول سجل مشاهدات الفواتير
CREATE TABLE invoice_view_log (
    id BIGSERIAL PRIMARY KEY,
    share_link_id BIGINT NOT NULL,
    invoice_id BIGINT NOT NULL,
    viewer_ip VARCHAR(50),
    viewer_user_agent TEXT,
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- فهارس
CREATE INDEX idx_invoice_view_log_share_link_id ON invoice_view_log(share_link_id);
CREATE INDEX idx_invoice_view_log_invoice_id ON invoice_view_log(invoice_id);
CREATE INDEX idx_invoice_view_log_viewed_at ON invoice_view_log(viewed_at);

-- تعليقات
COMMENT ON TABLE invoice_view_log IS 'سجل مشاهدات الفواتير من قبل العملاء - لتتبع من شاف الفاتورة ومتى';
COMMENT ON COLUMN invoice_view_log.share_link_id IS 'معرف رابط المشاركة';
COMMENT ON COLUMN invoice_view_log.invoice_id IS 'معرف الفاتورة';
COMMENT ON COLUMN invoice_view_log.viewer_ip IS 'عنوان IP للمشاهد';
COMMENT ON COLUMN invoice_view_log.viewer_user_agent IS 'معلومات المتصفح للمشاهد';
COMMENT ON COLUMN invoice_view_log.viewed_at IS 'تاريخ ووقت المشاهدة';

-- إضافة حقل trip_id لربط الفاتورة بالرحلة
ALTER TABLE invoices 
ADD COLUMN trip_id BIGINT;

-- إضافة تعليق توضيحي
COMMENT ON COLUMN invoices.trip_id IS 'معرف الرحلة المرتبطة بالفاتورة - NULL للفواتير العامة، NOT NULL لفواتير الرحلات';

-- إنشاء فهرس لتحسين الأداء
CREATE INDEX idx_invoices_trip_id ON invoices(trip_id);

-- إنشاء فهرس مركب لتسهيل الاستعلامات
CREATE INDEX idx_invoices_trip_id_status ON invoices(trip_id, status) WHERE trip_id IS NOT NULL;

-- جدول الرسائل الرئيسي
CREATE TABLE internal_messages (
    id BIGSERIAL PRIMARY KEY,
    sender_user_id BIGINT NOT NULL,
    sender_type VARCHAR(20) NOT NULL CHECK (sender_type IN ('admin', 'driver', 'manager', 'distributor')),
    subject VARCHAR(200) NOT NULL,
    message_body TEXT NOT NULL,
    message_priority VARCHAR(20) DEFAULT 'normal' CHECK (message_priority IN ('low', 'normal', 'high', 'urgent')),
    recipient_type VARCHAR(20) NOT NULL CHECK (recipient_type IN ('individual', 'company', 'all_drivers', 'all_active_drivers')),
    target_company_id BIGINT,
    is_broadcast BOOLEAN DEFAULT false,
    parent_message_id BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE internal_messages IS 'الرسائل الداخلية بين الإدارة والسائقين - يدعم الرسائل الفردية والجماعية';
COMMENT ON COLUMN internal_messages.sender_user_id IS 'معرف المرسل';
COMMENT ON COLUMN internal_messages.sender_type IS 'نوع المرسل: admin (إدارة), driver (سائق), manager (مدير), distributor (موزع)';
COMMENT ON COLUMN internal_messages.subject IS 'موضوع الرسالة';
COMMENT ON COLUMN internal_messages.message_body IS 'نص الرسالة الكامل';
COMMENT ON COLUMN internal_messages.message_priority IS 'أولوية الرسالة: low (منخفضة), normal (عادية), high (عالية), urgent (عاجلة)';
COMMENT ON COLUMN internal_messages.recipient_type IS 'نوع المستلم: individual (فردي), company (شركة), all_drivers (جميع السائقين), all_active_drivers (السائقين النشطين فقط)';
COMMENT ON COLUMN internal_messages.target_company_id IS 'معرف الشركة المستهدفة (إذا كان recipient_type = company)';
COMMENT ON COLUMN internal_messages.is_broadcast IS 'هل الرسالة إذاعية لمجموعة كبيرة';
COMMENT ON COLUMN internal_messages.parent_message_id IS 'معرف الرسالة الأصلية (للردود)';

CREATE INDEX idx_internal_messages_sender ON internal_messages(sender_user_id);
CREATE INDEX idx_internal_messages_sender_type ON internal_messages(sender_type);
CREATE INDEX idx_internal_messages_priority ON internal_messages(message_priority);
CREATE INDEX idx_internal_messages_recipient_type ON internal_messages(recipient_type);
CREATE INDEX idx_internal_messages_target_company ON internal_messages(target_company_id);
CREATE INDEX idx_internal_messages_parent ON internal_messages(parent_message_id);
CREATE INDEX idx_internal_messages_created_at ON internal_messages(created_at);

-- جدول المستلمين وحالة القراءة
CREATE TABLE message_recipients (
    id BIGSERIAL PRIMARY KEY,
    message_id BIGINT NOT NULL,
    recipient_user_id BIGINT NOT NULL,
    recipient_driver_id BIGINT,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    is_archived BOOLEAN DEFAULT false,
    archived_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT false,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(message_id, recipient_user_id)
);

COMMENT ON TABLE message_recipients IS 'مستلمو الرسائل وحالة القراءة لكل مستلم';
COMMENT ON COLUMN message_recipients.message_id IS 'معرف الرسالة';
COMMENT ON COLUMN message_recipients.recipient_user_id IS 'معرف المستخدم المستلم';
COMMENT ON COLUMN message_recipients.recipient_driver_id IS 'معرف السائق المستلم (إذا كان المستلم سائق)';
COMMENT ON COLUMN message_recipients.is_read IS 'هل تم قراءة الرسالة';
COMMENT ON COLUMN message_recipients.read_at IS 'تاريخ ووقت القراءة';
COMMENT ON COLUMN message_recipients.is_archived IS 'هل تم أرشفة الرسالة';
COMMENT ON COLUMN message_recipients.archived_at IS 'تاريخ ووقت الأرشفة';
COMMENT ON COLUMN message_recipients.is_deleted IS 'هل تم حذف الرسالة (حذف ناعم)';
COMMENT ON COLUMN message_recipients.deleted_at IS 'تاريخ ووقت الحذف';

CREATE INDEX idx_message_recipients_message_id ON message_recipients(message_id);
CREATE INDEX idx_message_recipients_recipient_user ON message_recipients(recipient_user_id);
CREATE INDEX idx_message_recipients_recipient_driver ON message_recipients(recipient_driver_id);
CREATE INDEX idx_message_recipients_is_read ON message_recipients(is_read);
CREATE INDEX idx_message_recipients_unread ON message_recipients(recipient_user_id, is_read) WHERE is_read = false;

-- جدول مرفقات الرسائل
CREATE TABLE message_attachments (
    id BIGSERIAL PRIMARY KEY,
    message_id BIGINT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_type VARCHAR(100),
    file_size_bytes BIGINT,
    uploaded_by_user_id BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE message_attachments IS 'مرفقات الرسائل - صور، ملفات PDF، مستندات، إلخ';
COMMENT ON COLUMN message_attachments.message_id IS 'معرف الرسالة المرتبطة';
COMMENT ON COLUMN message_attachments.file_name IS 'اسم الملف';
COMMENT ON COLUMN message_attachments.file_url IS 'رابط الملف';
COMMENT ON COLUMN message_attachments.file_type IS 'نوع الملف (MIME type)';
COMMENT ON COLUMN message_attachments.file_size_bytes IS 'حجم الملف بالبايتات';
COMMENT ON COLUMN message_attachments.uploaded_by_user_id IS 'معرف المستخدم الذي رفع الملف';

CREATE INDEX idx_message_attachments_message_id ON message_attachments(message_id);
CREATE INDEX idx_message_attachments_uploaded_by ON message_attachments(uploaded_by_user_id);

-- جدول الردود على الرسائل
CREATE TABLE message_replies (
    id BIGSERIAL PRIMARY KEY,
    parent_message_id BIGINT NOT NULL,
    reply_message_id BIGINT NOT NULL,
    sender_user_id BIGINT NOT NULL,
    reply_body TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(parent_message_id, reply_message_id)
);

COMMENT ON TABLE message_replies IS 'الردود على الرسائل - لدعم المحادثات المترابطة';
COMMENT ON COLUMN message_replies.parent_message_id IS 'معرف الرسالة الأصلية';
COMMENT ON COLUMN message_replies.reply_message_id IS 'معرف رسالة الرد';
COMMENT ON COLUMN message_replies.sender_user_id IS 'معرف المرسل';
COMMENT ON COLUMN message_replies.reply_body IS 'نص الرد';

CREATE INDEX idx_message_replies_parent ON message_replies(parent_message_id);
CREATE INDEX idx_message_replies_reply ON message_replies(reply_message_id);
CREATE INDEX idx_message_replies_sender ON message_replies(sender_user_id);

-- جدول إحصائيات الرسائل
CREATE TABLE message_statistics (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    total_sent BIGINT DEFAULT 0,
    total_received BIGINT DEFAULT 0,
    total_read BIGINT DEFAULT 0,
    total_unread BIGINT DEFAULT 0,
    total_archived BIGINT DEFAULT 0,
    last_message_sent_at TIMESTAMP WITH TIME ZONE,
    last_message_received_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

COMMENT ON TABLE message_statistics IS 'إحصائيات الرسائل لكل مستخدم - لعرض سريع في لوحة التحكم';
COMMENT ON COLUMN message_statistics.user_id IS 'معرف المستخدم';
COMMENT ON COLUMN message_statistics.total_sent IS 'إجمالي الرسائل المرسلة';
COMMENT ON COLUMN message_statistics.total_received IS 'إجمالي الرسائل المستلمة';
COMMENT ON COLUMN message_statistics.total_read IS 'إجمالي الرسائل المقروءة';
COMMENT ON COLUMN message_statistics.total_unread IS 'إجمالي الرسائل غير المقروءة';
COMMENT ON COLUMN message_statistics.total_archived IS 'إجمالي الرسائل المؤرشفة';
COMMENT ON COLUMN message_statistics.last_message_sent_at IS 'تاريخ آخر رسالة مرسلة';
COMMENT ON COLUMN message_statistics.last_message_received_at IS 'تاريخ آخر رسالة مستلمة';

CREATE INDEX idx_message_statistics_user_id ON message_statistics(user_id);

-- تفعيل Row Level Security على جداول الرسائل والإشعارات
ALTER TABLE internal_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_statistics ENABLE ROW LEVEL SECURITY;

-- سياسات RLS لجدول internal_messages
-- المستخدمون يمكنهم رؤية الرسائل التي أرسلوها أو استلموها
CREATE POLICY internal_messages_select_policy ON internal_messages
    FOR SELECT USING (
        sender_user_id = uid() OR 
        EXISTS (
            SELECT 1 FROM message_recipients 
            WHERE message_recipients.message_id = internal_messages.id 
            AND message_recipients.recipient_user_id = uid()
        )
    );

-- المستخدمون يمكنهم إرسال رسائل جديدة
CREATE POLICY internal_messages_insert_policy ON internal_messages
    FOR INSERT WITH CHECK (sender_user_id = uid());

-- المستخدمون يمكنهم تحديث رسائلهم الخاصة فقط
CREATE POLICY internal_messages_update_policy ON internal_messages
    FOR UPDATE USING (sender_user_id = uid()) WITH CHECK (sender_user_id = uid());

-- المستخدمون يمكنهم حذف رسائلهم الخاصة فقط
CREATE POLICY internal_messages_delete_policy ON internal_messages
    FOR DELETE USING (sender_user_id = uid());

-- سياسات RLS لجدول message_recipients
-- المستخدمون يمكنهم رؤية سجلات الاستلام الخاصة بهم فقط
CREATE POLICY message_recipients_select_policy ON message_recipients
    FOR SELECT USING (recipient_user_id = uid());

-- يمكن إنشاء سجلات استلام جديدة
CREATE POLICY message_recipients_insert_policy ON message_recipients
    FOR INSERT WITH CHECK (true);

-- المستخدمون يمكنهم تحديث حالة قراءة رسائلهم فقط
CREATE POLICY message_recipients_update_policy ON message_recipients
    FOR UPDATE USING (recipient_user_id = uid()) WITH CHECK (recipient_user_id = uid());

-- المستخدمون يمكنهم حذف سجلات الاستلام الخاصة بهم
CREATE POLICY message_recipients_delete_policy ON message_recipients
    FOR DELETE USING (recipient_user_id = uid());

-- سياسات RLS لجدول message_replies
-- المستخدمون يمكنهم رؤية الردود على رسائلهم أو الردود التي أرسلوها
CREATE POLICY message_replies_select_policy ON message_replies
    FOR SELECT USING (
        sender_user_id = uid() OR
        EXISTS (
            SELECT 1 FROM internal_messages 
            WHERE internal_messages.id = message_replies.parent_message_id 
            AND internal_messages.sender_user_id = uid()
        )
    );

-- المستخدمون يمكنهم إضافة ردود جديدة
CREATE POLICY message_replies_insert_policy ON message_replies
    FOR INSERT WITH CHECK (sender_user_id = uid());

-- المستخدمون يمكنهم تحديث ردودهم فقط
CREATE POLICY message_replies_update_policy ON message_replies
    FOR UPDATE USING (sender_user_id = uid()) WITH CHECK (sender_user_id = uid());

-- المستخدمون يمكنهم حذف ردودهم فقط
CREATE POLICY message_replies_delete_policy ON message_replies
    FOR DELETE USING (sender_user_id = uid());

-- سياسات RLS لجدول message_attachments
-- المستخدمون يمكنهم رؤية المرفقات للرسائل التي يمكنهم الوصول إليها
CREATE POLICY message_attachments_select_policy ON message_attachments
    FOR SELECT USING (
        uploaded_by_user_id = uid() OR
        EXISTS (
            SELECT 1 FROM internal_messages 
            WHERE internal_messages.id = message_attachments.message_id 
            AND (
                internal_messages.sender_user_id = uid() OR
                EXISTS (
                    SELECT 1 FROM message_recipients 
                    WHERE message_recipients.message_id = internal_messages.id 
                    AND message_recipients.recipient_user_id = uid()
                )
            )
        )
    );

-- المستخدمون يمكنهم رفع مرفقات جديدة
CREATE POLICY message_attachments_insert_policy ON message_attachments
    FOR INSERT WITH CHECK (uploaded_by_user_id = uid());

-- المستخدمون يمكنهم تحديث مرفقاتهم فقط
CREATE POLICY message_attachments_update_policy ON message_attachments
    FOR UPDATE USING (uploaded_by_user_id = uid()) WITH CHECK (uploaded_by_user_id = uid());

-- المستخدمون يمكنهم حذف مرفقاتهم فقط
CREATE POLICY message_attachments_delete_policy ON message_attachments
    FOR DELETE USING (uploaded_by_user_id = uid());

-- سياسات RLS لجدول message_statistics
-- المستخدمون يمكنهم رؤية إحصائياتهم فقط
CREATE POLICY message_statistics_select_policy ON message_statistics
    FOR SELECT USING (user_id = uid());

-- يمكن إنشاء إحصائيات جديدة
CREATE POLICY message_statistics_insert_policy ON message_statistics
    FOR INSERT WITH CHECK (user_id = uid());

-- المستخدمون يمكنهم تحديث إحصائياتهم فقط
CREATE POLICY message_statistics_update_policy ON message_statistics
    FOR UPDATE USING (user_id = uid()) WITH CHECK (user_id = uid());

-- المستخدمون يمكنهم حذف إحصائياتهم
CREATE POLICY message_statistics_delete_policy ON message_statistics
    FOR DELETE USING (user_id = uid());

-- ملاحظة: جداول notifications و user_notifications لديها بالفعل RLS مفعل
-- لذلك لن نحتاج لتعديلها

-- إضافة حقول جديدة لجدول الرسائل الداخلية
ALTER TABLE internal_messages 
ADD COLUMN IF NOT EXISTS sender_name VARCHAR(200),
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'resolved')),
ADD COLUMN IF NOT EXISTS last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS is_locked BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS resolved_by_user_id BIGINT;

-- إضافة تعليقات على الحقول الجديدة
COMMENT ON COLUMN internal_messages.sender_name IS 'اسم المرسل (يتم نسخه من جدول users أو drivers)';
COMMENT ON COLUMN internal_messages.status IS 'حالة الرسالة: open (مفتوحة), resolved (تم الحل)';
COMMENT ON COLUMN internal_messages.last_activity_at IS 'تاريخ آخر نشاط على الرسالة (إرسال أو رد)';
COMMENT ON COLUMN internal_messages.is_locked IS 'هل الرسالة مقفلة (لا يمكن الرد عليها)';
COMMENT ON COLUMN internal_messages.resolved_at IS 'تاريخ ووقت حل الرسالة';
COMMENT ON COLUMN internal_messages.resolved_by_user_id IS 'معرف المستخدم الذي قام بحل الرسالة';

-- إضافة فهارس للحقول الجديدة
CREATE INDEX IF NOT EXISTS idx_internal_messages_status ON internal_messages(status);
CREATE INDEX IF NOT EXISTS idx_internal_messages_last_activity ON internal_messages(last_activity_at);
CREATE INDEX IF NOT EXISTS idx_internal_messages_is_locked ON internal_messages(is_locked);

-- إضافة حقل اللغة المفضلة لجدول السائقين
ALTER TABLE drivers 
ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(10) DEFAULT 'ar' CHECK (preferred_language IN ('ar', 'en'));

COMMENT ON COLUMN drivers.preferred_language IS 'اللغة المفضلة للسائق: ar (عربي), en (إنجليزي)';

CREATE INDEX IF NOT EXISTS idx_drivers_preferred_language ON drivers(preferred_language);

-- دالة لتحديث آخر نشاط على الرسالة
CREATE OR REPLACE FUNCTION update_message_last_activity()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE internal_messages 
    SET last_activity_at = CURRENT_TIMESTAMP
    WHERE id = NEW.parent_message_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- تفعيل الدالة عند إضافة رد جديد
DROP TRIGGER IF EXISTS trigger_update_message_last_activity ON message_replies;
CREATE TRIGGER trigger_update_message_last_activity
    AFTER INSERT ON message_replies
    FOR EACH ROW
    EXECUTE FUNCTION update_message_last_activity();

-- دالة لقفل الرسالة عند تغيير الحالة إلى "تم الحل"
CREATE OR REPLACE FUNCTION lock_resolved_messages()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'resolved' AND OLD.status != 'resolved' THEN
        NEW.is_locked = true;
        NEW.resolved_at = CURRENT_TIMESTAMP;
        IF NEW.resolved_by_user_id IS NULL THEN
            NEW.resolved_by_user_id = uid();
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- تفعيل الدالة عند تحديث حالة الرسالة
DROP TRIGGER IF EXISTS trigger_lock_resolved_messages ON internal_messages;
CREATE TRIGGER trigger_lock_resolved_messages
    BEFORE UPDATE ON internal_messages
    FOR EACH ROW
    EXECUTE FUNCTION lock_resolved_messages();

-- دالة للحذف التلقائي للرسائل القديمة (أكثر من 30 يوم من آخر نشاط)
CREATE OR REPLACE FUNCTION auto_delete_old_messages()
RETURNS void AS $$
BEGIN
    -- حذف المستلمين للرسائل القديمة
    DELETE FROM message_recipients
    WHERE message_id IN (
        SELECT id FROM internal_messages
        WHERE last_activity_at < CURRENT_TIMESTAMP - INTERVAL '30 days'
    );
    
    -- حذف الردود للرسائل القديمة
    DELETE FROM message_replies
    WHERE parent_message_id IN (
        SELECT id FROM internal_messages
        WHERE last_activity_at < CURRENT_TIMESTAMP - INTERVAL '30 days'
    );
    
    -- حذف المرفقات للرسائل القديمة
    DELETE FROM message_attachments
    WHERE message_id IN (
        SELECT id FROM internal_messages
        WHERE last_activity_at < CURRENT_TIMESTAMP - INTERVAL '30 days'
    );
    
    -- حذف الرسائل القديمة
    DELETE FROM internal_messages
    WHERE last_activity_at < CURRENT_TIMESTAMP - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION auto_delete_old_messages() IS 'دالة للحذف التلقائي للرسائل التي مر عليها أكثر من 30 يوم من آخر نشاط';

-- إنشاء مهمة مجدولة للحذف التلقائي (يتم تشغيلها يومياً)
-- ملاحظة: يجب تفعيل pg_cron extension أولاً إذا لم تكن مفعلة
-- يمكن تشغيل هذه الدالة من خلال cron job خارجي أو من خلال scheduled_tasks table

-- ============================================================
-- المتطلب 1: إضافة حقل المركبة الحالية للسائق
-- يُستخدم لتتبع المركبة التي يعمل عليها السائق في كل جلسة
-- ============================================================
ALTER TABLE drivers 
ADD COLUMN IF NOT EXISTS current_vehicle_id BIGINT DEFAULT NULL;

COMMENT ON COLUMN drivers.current_vehicle_id IS 'معرف المركبة التي يعمل عليها السائق حالياً - يتم تحديده عند بدء الجلسة - NULL إذا لم يختر مركبة بعد';

CREATE INDEX IF NOT EXISTS idx_drivers_current_vehicle_id 
ON drivers(current_vehicle_id);


-- ============================================================
-- المتطلب 3: إضافة حقل وقت الرحلة في الفاتورة
-- لحل مشكلة ظهور 00:00 بدلاً من الوقت الفعلي
-- invoice_date هو DATE فقط بدون وقت، لذا نضيف trip_time
-- ============================================================
ALTER TABLE invoices 
ADD COLUMN IF NOT EXISTS trip_time TIME WITH TIME ZONE DEFAULT NULL;

COMMENT ON COLUMN invoices.trip_time IS 'وقت الرحلة الفعلي (ساعة:دقيقة) - يُأخذ من trips.start_time عند إنشاء الفاتورة - يحل مشكلة ظهور 00:00 في الفاتورة';

-- إضافة حقل لحفظ التاريخ والوقت الكاملين معاً كبديل أفضل
ALTER TABLE invoices 
ADD COLUMN IF NOT EXISTS trip_datetime TIMESTAMP WITH TIME ZONE DEFAULT NULL;

COMMENT ON COLUMN invoices.trip_datetime IS 'تاريخ ووقت الرحلة الكاملان (يُأخذ من trips.start_time) - يُستخدم لعرض التاريخ والوقت الصحيحين في الفاتورة بدلاً من invoice_date الذي يحتوي على التاريخ فقط';

CREATE INDEX IF NOT EXISTS idx_invoices_trip_datetime 
ON invoices(trip_datetime) WHERE trip_datetime IS NOT NULL;


-- ============================================================
-- تحديث الفواتير الموجودة المرتبطة برحلات لإصلاح الوقت
-- يأخذ start_time من جدول trips ويحفظه في trip_datetime
-- ============================================================
UPDATE invoices 
SET trip_datetime = trips.start_time
FROM trips
WHERE invoices.trip_id = trips.id 
  AND invoices.trip_id IS NOT NULL
  AND invoices.trip_datetime IS NULL;

-- منح صلاحية مدير كامل للمستخدم 123aliactionx5@gmail.com
UPDATE users
SET 
    role = 'app20251225073911jaqqaxdfir_v1_admin_user',
    user_type = 'admin',
    updated_at = CURRENT_TIMESTAMP
WHERE email = '123aliactionx5@gmail.com';

-- ============================================================
-- 1. تعديل جدول drivers: إضافة registration_status
-- ============================================================
ALTER TABLE drivers
    ADD COLUMN IF NOT EXISTS registration_status VARCHAR(20) DEFAULT 'pending'
        CHECK (registration_status IN ('pending', 'approved', 'rejected', 'under_review')),
    ADD COLUMN IF NOT EXISTS registration_submitted_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS registration_reviewed_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS registration_reviewed_by BIGINT,
    ADD COLUMN IF NOT EXISTS registration_rejection_reason TEXT,
    ADD COLUMN IF NOT EXISTS bestuurderspas_number VARCHAR(100),
    ADD COLUMN IF NOT EXISTS assigned_vehicle_id BIGINT;

COMMENT ON COLUMN drivers.registration_status IS 'حالة طلب تسجيل السائق: pending (قيد الانتظار), approved (موافق عليه), rejected (مرفوض), under_review (قيد المراجعة)';
COMMENT ON COLUMN drivers.registration_submitted_at IS 'تاريخ تقديم طلب التسجيل';
COMMENT ON COLUMN drivers.registration_reviewed_at IS 'تاريخ مراجعة طلب التسجيل';
COMMENT ON COLUMN drivers.registration_reviewed_by IS 'معرف المسؤول الذي راجع الطلب';
COMMENT ON COLUMN drivers.registration_rejection_reason IS 'سبب رفض طلب التسجيل';
COMMENT ON COLUMN drivers.bestuurderspas_number IS 'رقم Bestuurderspas - وثيقة السائق البلجيكية';
COMMENT ON COLUMN drivers.assigned_vehicle_id IS 'معرف المركبة المخصصة للسائق عند التسجيل';

-- تحديث قيد اللغة ليشمل الفرنسية والهولندية
ALTER TABLE drivers DROP CONSTRAINT IF EXISTS drivers_preferred_language_check;
ALTER TABLE drivers
    ADD CONSTRAINT drivers_preferred_language_check
        CHECK (preferred_language IN ('ar', 'en', 'fr', 'nl'));

-- إنشاء indexes للحقول الجديدة
CREATE INDEX IF NOT EXISTS idx_drivers_registration_status ON drivers(registration_status);
CREATE INDEX IF NOT EXISTS idx_drivers_assigned_vehicle_id ON drivers(assigned_vehicle_id);
CREATE INDEX IF NOT EXISTS idx_drivers_registration_submitted_at ON drivers(registration_submitted_at);


-- ============================================================
-- 2. تعديل جدول approval_requests: إضافة نوع register
-- ============================================================
ALTER TABLE approval_requests DROP CONSTRAINT IF EXISTS approval_requests_request_type_check;
ALTER TABLE approval_requests
    ADD CONSTRAINT approval_requests_request_type_check
        CHECK (request_type IN ('register', 'update', 'delete'));

ALTER TABLE approval_requests DROP CONSTRAINT IF EXISTS approval_requests_entity_type_check;
ALTER TABLE approval_requests
    ADD CONSTRAINT approval_requests_entity_type_check
        CHECK (entity_type IN ('company', 'vehicle', 'driver', 'invoice', 'expense', 'driver_registration'));

COMMENT ON COLUMN approval_requests.request_type IS 'نوع الطلب: register (تسجيل جديد), update (تعديل), delete (حذف)';
COMMENT ON COLUMN approval_requests.entity_type IS 'نوع الكيان: company, vehicle, driver, invoice, expense, driver_registration';


-- ============================================================
-- 3. تعديل جدول driver_credentials: إضافة vehicle_id
-- ============================================================
ALTER TABLE driver_credentials
    ADD COLUMN IF NOT EXISTS vehicle_id BIGINT,
    ADD COLUMN IF NOT EXISTS company_id BIGINT,
    ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(10) DEFAULT 'fr'
        CHECK (preferred_language IN ('ar', 'en', 'fr', 'nl'));

COMMENT ON COLUMN driver_credentials.vehicle_id IS 'معرف المركبة المرتبطة بالسائق - يُحدَّث تلقائياً عند الموافقة على التسجيل';
COMMENT ON COLUMN driver_credentials.company_id IS 'معرف الشركة التي ينتمي إليها السائق';
COMMENT ON COLUMN driver_credentials.preferred_language IS 'اللغة المفضلة للسائق في بوابة السائق: ar, en, fr, nl';

CREATE INDEX IF NOT EXISTS idx_driver_credentials_vehicle_id ON driver_credentials(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_driver_credentials_company_id ON driver_credentials(company_id);


-- ============================================================
-- 4. جدول جديد: driver_registration_requests
--    يخزن كامل بيانات نموذج تسجيل السائق الجديد
-- ============================================================
CREATE TABLE IF NOT EXISTS driver_registration_requests (
    id                          BIGSERIAL PRIMARY KEY,

    -- ربط الطلب
    approval_request_id         BIGINT,                          -- ربط بجدول approval_requests
    driver_id                   BIGINT,                          -- يُملأ بعد الموافقة وإنشاء السائق
    company_id                  BIGINT NOT NULL,                 -- الشركة التي ينتمي إليها

    -- القسم 1: البيانات الشخصية
    full_name                   VARCHAR(200) NOT NULL,
    phone                       VARCHAR(50) NOT NULL,
    email                       VARCHAR(255),
    company_address             TEXT,

    -- القسم 2: بيانات المركبة
    vehicle_brand               VARCHAR(100) NOT NULL,
    vehicle_model               VARCHAR(100) NOT NULL,
    vehicle_vin                 VARCHAR(100),
    vehicle_plate_number        VARCHAR(50) NOT NULL,
    vehicle_id                  BIGINT,                          -- يُملأ بعد إنشاء المركبة

    -- القسم 3: الوثائق والتراخيص
    tva_number                  VARCHAR(50),                     -- رقم الضريبة TVA
    driver_license_number       VARCHAR(100) NOT NULL,           -- رقم رخصة القيادة
    bestuurderspas_number       VARCHAR(100),                    -- رقم Bestuurderspas

    -- رفع الوثائق (روابط الملفات)
    driver_license_doc_url      TEXT,                            -- صورة رخصة القيادة
    bestuurderspas_doc_url      TEXT,                            -- صورة Bestuurderspas
    vehicle_registration_doc_url TEXT,                           -- وثيقة تسجيل المركبة
    additional_docs             JSONB DEFAULT '[]'::jsonb,       -- وثائق إضافية

    -- القسم 4: الدفع
    payment_status              VARCHAR(20) DEFAULT 'pending'
        CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
    payment_reference           VARCHAR(200),                    -- مرجع الدفع من SumUp
    payment_amount              NUMERIC(10,2),
    payment_date                TIMESTAMP WITH TIME ZONE,

    -- حالة الطلب
    status                      VARCHAR(20) DEFAULT 'pending'
        CHECK (status IN ('draft', 'pending', 'under_review', 'approved', 'rejected', 'cancelled')),
    rejection_reason            TEXT,
    reviewed_by_user_id         BIGINT,
    reviewed_at                 TIMESTAMP WITH TIME ZONE,
    review_notes                TEXT,

    -- اللغة المفضلة للسائق
    preferred_language          VARCHAR(10) DEFAULT 'fr'
        CHECK (preferred_language IN ('ar', 'en', 'fr', 'nl')),

    -- بيانات المراجعة
    submitted_at                TIMESTAMP WITH TIME ZONE,
    created_at                  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE driver_registration_requests IS 'طلبات تسجيل السائقين الجدد - يحتوي على كامل بيانات نموذج JOUW DRIVER';
COMMENT ON COLUMN driver_registration_requests.approval_request_id IS 'ربط بجدول approval_requests لظهور الطلب في لوحة التحكم';
COMMENT ON COLUMN driver_registration_requests.driver_id IS 'معرف السائق بعد الموافقة وإنشاء الحساب تلقائياً';
COMMENT ON COLUMN driver_registration_requests.company_id IS 'الشركة التي ينتمي إليها السائق - ربط بجدول companies';
COMMENT ON COLUMN driver_registration_requests.vehicle_id IS 'معرف المركبة بعد إنشائها تلقائياً عند الموافقة';
COMMENT ON COLUMN driver_registration_requests.tva_number IS 'رقم الضريبة TVA للسائق';
COMMENT ON COLUMN driver_registration_requests.bestuurderspas_number IS 'رقم Bestuurderspas - وثيقة السائق البلجيكية الرسمية';
COMMENT ON COLUMN driver_registration_requests.payment_status IS 'حالة الدفع: pending (لم يدفع), paid (دفع), failed (فشل الدفع), refunded (مسترد)';
COMMENT ON COLUMN driver_registration_requests.status IS 'حالة الطلب: draft (مسودة), pending (قيد الانتظار), under_review (قيد المراجعة), approved (موافق), rejected (مرفوض), cancelled (ملغي)';
COMMENT ON COLUMN driver_registration_requests.preferred_language IS 'اللغة التي اختارها السائق عند التسجيل - تُطبَّق على بوابة السائق';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_drr_company_id ON driver_registration_requests(company_id);
CREATE INDEX IF NOT EXISTS idx_drr_status ON driver_registration_requests(status);
CREATE INDEX IF NOT EXISTS idx_drr_payment_status ON driver_registration_requests(payment_status);
CREATE INDEX IF NOT EXISTS idx_drr_driver_id ON driver_registration_requests(driver_id);
CREATE INDEX IF NOT EXISTS idx_drr_approval_request_id ON driver_registration_requests(approval_request_id);
CREATE INDEX IF NOT EXISTS idx_drr_submitted_at ON driver_registration_requests(submitted_at);
CREATE INDEX IF NOT EXISTS idx_drr_vehicle_plate ON driver_registration_requests(vehicle_plate_number);
CREATE INDEX IF NOT EXISTS idx_drr_pending ON driver_registration_requests(status, payment_status)
    WHERE status IN ('pending', 'under_review');

-- Permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON driver_registration_requests TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON driver_registration_requests TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE driver_registration_requests_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE driver_registration_requests_id_seq TO app20251225073911jaqqaxdfir_v1_user;


-- ============================================================
-- 5. جدول: driver_registration_steps
--    لتتبع تقدم السائق في خطوات نموذج التسجيل متعدد الخطوات
-- ============================================================
CREATE TABLE IF NOT EXISTS driver_registration_steps (
    id                          BIGSERIAL PRIMARY KEY,
    registration_request_id     BIGINT NOT NULL,                 -- ربط بـ driver_registration_requests
    step_number                 INTEGER NOT NULL,                 -- رقم الخطوة (1-5)
    step_name                   VARCHAR(100) NOT NULL,           -- اسم الخطوة
    step_status                 VARCHAR(20) DEFAULT 'pending'
        CHECK (step_status IN ('pending', 'in_progress', 'completed', 'skipped')),
    step_data                   JSONB DEFAULT '{}'::jsonb,       -- بيانات الخطوة المحفوظة
    completed_at                TIMESTAMP WITH TIME ZONE,
    created_at                  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(registration_request_id, step_number)
);

COMMENT ON TABLE driver_registration_steps IS 'تتبع خطوات نموذج تسجيل السائق متعدد الخطوات - يحفظ تقدم السائق في كل خطوة';
COMMENT ON COLUMN driver_registration_steps.step_number IS '1=البيانات الشخصية, 2=بيانات المركبة, 3=الوثائق, 4=الدفع, 5=المراجعة';
COMMENT ON COLUMN driver_registration_steps.step_data IS 'البيانات المدخلة في هذه الخطوة محفوظة كـ JSON';

CREATE INDEX IF NOT EXISTS idx_drs_registration_request_id ON driver_registration_steps(registration_request_id);
CREATE INDEX IF NOT EXISTS idx_drs_step_status ON driver_registration_steps(step_status);

GRANT SELECT, INSERT, UPDATE, DELETE ON driver_registration_steps TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON driver_registration_steps TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE driver_registration_steps_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE driver_registration_steps_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================
-- الحل الجذري: إصلاح صلاحيات السائق في لوحة التحكم
-- ============================================================

-- 1. إضافة RLS على جدول vehicles
--    السائق يشوف فقط المركبة المرتبطة به عبر drivers.assigned_vehicle_id
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

-- السائق يشوف مركبته المرتبطة به فقط
CREATE POLICY vehicles_select_driver_policy ON vehicles
    FOR SELECT
    USING (
        id IN (
            SELECT assigned_vehicle_id FROM drivers
            WHERE user_id = uid() AND assigned_vehicle_id IS NOT NULL
            UNION
            SELECT current_vehicle_id FROM drivers
            WHERE user_id = uid() AND current_vehicle_id IS NOT NULL
        )
    );

-- المدير فقط يعدل/يضيف/يحذف مركبات (السائق عرض فقط)
CREATE POLICY vehicles_insert_admin_policy ON vehicles
    FOR INSERT WITH CHECK (false);

CREATE POLICY vehicles_update_admin_policy ON vehicles
    FOR UPDATE USING (false);

CREATE POLICY vehicles_delete_admin_policy ON vehicles
    FOR DELETE USING (false);

-- ============================================================
-- 2. إضافة RLS على جدول companies
--    السائق يشوف فقط شركته المرتبطة به عبر drivers.company_id
-- ============================================================
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- السائق يشوف شركته فقط
CREATE POLICY companies_select_driver_policy ON companies
    FOR SELECT
    USING (
        id IN (
            SELECT company_id FROM drivers
            WHERE user_id = uid()
        )
    );

-- المدير فقط يعدل/يضيف/يحذف شركات
CREATE POLICY companies_insert_admin_policy ON companies
    FOR INSERT WITH CHECK (false);

CREATE POLICY companies_update_admin_policy ON companies
    FOR UPDATE USING (false);

CREATE POLICY companies_delete_admin_policy ON companies
    FOR DELETE USING (false);

-- ============================================================
-- 3. إضافة RLS على driver_registration_requests
--    السائق يشوف طلب تسجيله فقط
-- ============================================================
ALTER TABLE driver_registration_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY drr_select_driver_policy ON driver_registration_requests
    FOR SELECT
    USING (
        driver_id IN (
            SELECT id FROM drivers WHERE user_id = uid()
        )
    );

-- السائق لا يعدل طلبات التسجيل بعد الإرسال
CREATE POLICY drr_insert_policy ON driver_registration_requests
    FOR INSERT WITH CHECK (false);

CREATE POLICY drr_update_policy ON driver_registration_requests
    FOR UPDATE USING (false);

CREATE POLICY drr_delete_policy ON driver_registration_requests
    FOR DELETE USING (false);

-- ============================================================
-- 4. إضافة RLS على driver_registration_steps
-- ============================================================
ALTER TABLE driver_registration_steps ENABLE ROW LEVEL SECURITY;

CREATE POLICY drs_select_driver_policy ON driver_registration_steps
    FOR SELECT
    USING (
        registration_request_id IN (
            SELECT drr.id FROM driver_registration_requests drr
            JOIN drivers d ON d.id = drr.driver_id
            WHERE d.user_id = uid()
        )
    );

CREATE POLICY drs_insert_policy ON driver_registration_steps
    FOR INSERT WITH CHECK (false);

CREATE POLICY drs_update_policy ON driver_registration_steps
    FOR UPDATE USING (false);

CREATE POLICY drs_delete_policy ON driver_registration_steps
    FOR DELETE USING (false);

-- ============================================================
-- 5. منح صلاحيات القراءة للـ admin_user على الجداول الجديدة
--    (المدير يتجاوز RLS تلقائياً بصلاحية BYPASSRLS)
-- ============================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON vehicles TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON companies TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON driver_registration_requests TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON driver_registration_steps TO app20251225073911jaqqaxdfir_v1_admin_user;

-- منح صلاحية SELECT فقط للسائق العادي
GRANT SELECT ON vehicles TO app20251225073911jaqqaxdfir_v1_user;
GRANT SELECT ON companies TO app20251225073911jaqqaxdfir_v1_user;
GRANT SELECT ON driver_registration_requests TO app20251225073911jaqqaxdfir_v1_user;
GRANT SELECT ON driver_registration_steps TO app20251225073911jaqqaxdfir_v1_user;

-- =====================================================
-- الحل الجذري: دعم تسجيل الدخول عبر Google للسائقين
-- =====================================================

-- 1. تعديل جدول users: جعل password يقبل NULL لمستخدمي OAuth
ALTER TABLE users ALTER COLUMN password DROP NOT NULL;

-- 2. إضافة حقل auth_provider لمعرفة طريقة التسجيل الأصلية
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(20) DEFAULT 'email' 
    CHECK (auth_provider IN ('email', 'google', 'facebook', 'apple'));

-- 3. إضافة حقل google_id لربط حساب Google مباشرة في جدول users
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id VARCHAR(255) UNIQUE;

-- 4. إضافة حقل avatar_url لصورة الحساب (مفيد لحسابات Google)
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- 5. إضافة حقل display_name للاسم القادم من Google
ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name VARCHAR(255);

-- إضافة index على google_id للبحث السريع
CREATE INDEX IF NOT EXISTS idx_users_google_id ON users(google_id) WHERE google_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_auth_provider ON users(auth_provider);

-- =====================================================
-- جدول user_oauth_providers: تخزين بيانات OAuth الكاملة
-- يدعم ربط أكثر من provider بنفس الحساب مستقبلاً
-- =====================================================
CREATE TABLE IF NOT EXISTS user_oauth_providers (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,                          -- ربط منطقي بـ users.id
    provider VARCHAR(20) NOT NULL                      -- google, facebook, apple
        CHECK (provider IN ('google', 'facebook', 'apple')),
    provider_user_id VARCHAR(255) NOT NULL,            -- الـ ID من Google/Facebook
    provider_email VARCHAR(255),                       -- الإيميل من الـ provider
    provider_name VARCHAR(255),                        -- الاسم من الـ provider
    provider_avatar_url TEXT,                          -- صورة الحساب من الـ provider
    access_token TEXT,                                 -- Access Token من OAuth
    refresh_token TEXT,                                -- Refresh Token من OAuth
    token_expires_at TIMESTAMP WITH TIME ZONE,         -- انتهاء صلاحية الـ token
    raw_profile JSONB,                                 -- البيانات الكاملة من الـ provider
    is_active BOOLEAN DEFAULT TRUE,                    -- هل الربط نشط
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(provider, provider_user_id)                 -- لا يمكن ربط نفس حساب Google بأكثر من مستخدم
);

COMMENT ON TABLE user_oauth_providers IS 'بيانات OAuth لكل مستخدم - يدعم Google وغيره';
COMMENT ON COLUMN user_oauth_providers.user_id IS 'ربط منطقي بـ users.id بدون foreign key';
COMMENT ON COLUMN user_oauth_providers.provider IS 'مزود OAuth: google, facebook, apple';
COMMENT ON COLUMN user_oauth_providers.provider_user_id IS 'الـ ID الفريد من مزود OAuth';
COMMENT ON COLUMN user_oauth_providers.raw_profile IS 'البيانات الكاملة المُرجعة من OAuth provider';

-- Indexes للبحث السريع
CREATE INDEX idx_oauth_providers_user_id ON user_oauth_providers(user_id);
CREATE INDEX idx_oauth_providers_provider ON user_oauth_providers(provider);
CREATE INDEX idx_oauth_providers_provider_user_id ON user_oauth_providers(provider, provider_user_id);
CREATE INDEX idx_oauth_providers_provider_email ON user_oauth_providers(provider_email) WHERE provider_email IS NOT NULL;

-- Grants للـ roles
GRANT SELECT, INSERT, UPDATE, DELETE ON user_oauth_providers TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_oauth_providers TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE user_oauth_providers_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE user_oauth_providers_id_seq TO app20251225073911jaqqaxdfir_v1_user;

CREATE TABLE homepage_ad_slots (
    id BIGSERIAL PRIMARY KEY,
    slot_key VARCHAR(100) NOT NULL,
    title VARCHAR(200) NOT NULL,
    html_content TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    display_order INTEGER NOT NULL DEFAULT 1,
    created_by_user_id BIGINT,
    create_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    modify_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(slot_key, display_order)
);

CREATE INDEX idx_homepage_ad_slots_slot_key ON homepage_ad_slots(slot_key);
CREATE INDEX idx_homepage_ad_slots_is_active ON homepage_ad_slots(is_active);
CREATE INDEX idx_homepage_ad_slots_start_time ON homepage_ad_slots(start_time);
CREATE INDEX idx_homepage_ad_slots_end_time ON homepage_ad_slots(end_time);
CREATE INDEX idx_homepage_ad_slots_display_order ON homepage_ad_slots(display_order);

COMMENT ON TABLE homepage_ad_slots IS 'مساحات إعلانية ديناميكية للصفحة الرئيسية قابلة للإدارة من لوحة التحكم';
COMMENT ON COLUMN homepage_ad_slots.slot_key IS 'مفتاح مكان العرض داخل الصفحة مثل home_mid_banner';
COMMENT ON COLUMN homepage_ad_slots.title IS 'عنوان داخلي للإعلان داخل لوحة التحكم';
COMMENT ON COLUMN homepage_ad_slots.html_content IS 'محتوى HTML الكامل الذي سيتم عرضه في الواجهة';
COMMENT ON COLUMN homepage_ad_slots.is_active IS 'حالة تفعيل الإعلان';
COMMENT ON COLUMN homepage_ad_slots.start_time IS 'بداية فترة العرض (اختياري)';
COMMENT ON COLUMN homepage_ad_slots.end_time IS 'نهاية فترة العرض (اختياري)';
COMMENT ON COLUMN homepage_ad_slots.display_order IS 'ترتيب العرض عند وجود أكثر من إعلان في نفس المكان';
COMMENT ON COLUMN homepage_ad_slots.created_by_user_id IS 'معرف المستخدم الذي أنشأ الإعلان';

INSERT INTO homepage_ad_slots (slot_key, title, html_content, is_active, start_time, end_time, display_order, created_by_user_id) VALUES
('home_mid_banner', 'عرض انطلاقة JouwDriver', '<div style="background:#0b1220;color:#fff;padding:28px;border-radius:16px;border:1px solid #1f2937;text-align:center;"><h2 style="margin:0 0 10px;font-size:30px;color:#facc15;">ابدأ رحلتك مع JouwDriver</h2><p style="margin:0;font-size:16px;line-height:1.7;">نمو أسرع، إدارة أذكى، وسائقون أكثر التزامًا. حوّل عملياتك اليومية إلى نجاح مستمر.</p></div>', true, CURRENT_TIMESTAMP, NULL, 1, 1),
('home_mid_banner', 'اشتراك شهري محفز', '<div style="background:linear-gradient(135deg,#0f172a,#111827);color:#fff;padding:24px;border-radius:16px;border:1px solid #334155;"><h3 style="margin:0 0 12px;color:#fbbf24;">خطة تشغيل واضحة وتكلفة ثابتة</h3><p style="margin:0 0 10px;">ابدأ من 49.99 يورو ووسّع أسطولك بسهولة.</p><a href="https://wa.me/32465555596" style="display:inline-block;margin-top:8px;padding:10px 18px;background:#22c55e;color:#fff;border-radius:10px;text-decoration:none;">تواصل الآن عبر واتساب</a></div>', true, CURRENT_TIMESTAMP, NULL, 2, 1),
('home_mid_banner', 'إعلان لوحة التحكم 1', '<div style="background:#111827;color:#e5e7eb;padding:22px;border-radius:14px;border:1px dashed #4b5563;text-align:center;"><strong style="font-size:22px;color:#fde047;">مساحتك الإعلانية جاهزة</strong><p style="margin-top:10px;">يمكنك نشر أي HTML من لوحة التحكم مباشرة في هذا المكان.</p></div>', true, CURRENT_TIMESTAMP, NULL, 3, 1),
('home_mid_banner', 'ميزة تتبع الرحلات', '<div style="background:#0a0f1f;color:#fff;padding:26px;border-radius:16px;"><h3 style="margin:0 0 8px;color:#60a5fa;">تابع الرحلات لحظة بلحظة</h3><p style="margin:0;">لوحة تحكم مرنة، تقارير دقيقة، وتجربة سائق متكاملة.</p></div>', false, CURRENT_TIMESTAMP, NULL, 4, 1),
('home_footer_banner', 'إعلان تذييل الصفحة', '<div style="background:#1e293b;color:#f8fafc;padding:18px;border-radius:12px;text-align:center;"><p style="margin:0;font-size:15px;">JouwDriver: منصة موثوقة لإدارة السائقين والمركبات باحترافية.</p></div>', true, CURRENT_TIMESTAMP, NULL, 1, 1);

INSERT INTO homepage_ad_slots (
    slot_key,
    title,
    html_content,
    is_active,
    display_order,
    created_by_user_id
) VALUES (
    'home_mid_banner',
    'JOUW DRIVER - Banner Belgique | بلجيكا',
    '<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>JOUW DRIVER Banner</title>
<style>
body{
    margin:0;
    display:flex;
    justify-content:center;
    align-items:center;
    min-height:100%;
    background:url(''https://images.unsplash.com/photo-1513635269975-59663e0ac1ad'') center/cover;
    font-family:Arial,sans-serif;
}
.banner{
    width:90%;
    max-width:1200px;
    padding:40px;
    border-radius:25px;
    background:rgba(255,255,255,0.12);
    backdrop-filter:blur(18px);
    border:1px solid rgba(255,255,255,0.25);
    box-shadow:0 8px 32px rgba(0,0,0,0.35);
    color:white;
    text-align:center;
}
h1{
    font-size:3rem;
    color:#FFD700;
    margin-bottom:20px;
}
.fr{
    font-size:1.5rem;
    margin-bottom:15px;
}
.ar{
    font-size:1.7rem;
    direction:rtl;
    margin-bottom:25px;
}
.highlight{
    color:#00eaff;
    font-weight:bold;
}
.footer{
    font-size:2.2rem;
    font-weight:bold;
    letter-spacing:5px;
    margin-top:20px;
    text-shadow:0 0 15px rgba(255,255,255,0.8);
}
</style>
</head>
<body>
<div class="banner">
    <h1>🇧🇪 Belgique | بلجيكا</h1>
    <div class="fr">
        Votre solution de transport premium en Belgique
        <span class="highlight">Rapide • Sécurisé • Professionnel</span>
    </div>
    <div class="ar">
        الحل الأمثل لخدمات النقل في بلجيكا
        <span class="highlight">سريع • آمن • احترافي</span>
    </div>
    <div class="footer">JOUW DRIVER</div>
</div>
</body>
</html>',
    true,
    1,
    1
);

-- =============================================
-- جدول محادثات المساعد الذكي
-- =============================================
CREATE TABLE ai_assistant_conversations (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    session_token VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'closed', 'resolved')),
    -- بيانات تعريفية جمعها المساعد من المستخدم
    identified_company_id BIGINT,
    identified_driver_id BIGINT,
    identified_vehicle_id BIGINT,
    identified_trip_id BIGINT,
    -- ملخص المشكلة
    problem_summary TEXT,
    resolution_summary TEXT,
    -- عدد الرسائل في المحادثة
    message_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ai_conversations_user_id ON ai_assistant_conversations(user_id);
CREATE INDEX idx_ai_conversations_status ON ai_assistant_conversations(status);
CREATE INDEX idx_ai_conversations_session_token ON ai_assistant_conversations(session_token);
CREATE INDEX idx_ai_conversations_company_id ON ai_assistant_conversations(identified_company_id);
CREATE INDEX idx_ai_conversations_driver_id ON ai_assistant_conversations(identified_driver_id);

COMMENT ON TABLE ai_assistant_conversations IS 'جلسات محادثات المساعد الذكي مع المستخدمين';
COMMENT ON COLUMN ai_assistant_conversations.session_token IS 'رمز فريد لكل جلسة محادثة';
COMMENT ON COLUMN ai_assistant_conversations.identified_company_id IS 'معرف الشركة التي تم التعرف عليها من خلال المحادثة';
COMMENT ON COLUMN ai_assistant_conversations.identified_driver_id IS 'معرف السائق الذي تم التعرف عليه من خلال المحادثة';
COMMENT ON COLUMN ai_assistant_conversations.identified_vehicle_id IS 'معرف المركبة التي تم التعرف عليها من خلال المحادثة';
COMMENT ON COLUMN ai_assistant_conversations.problem_summary IS 'ملخص المشكلة التي أبلغ عنها المستخدم';
COMMENT ON COLUMN ai_assistant_conversations.resolution_summary IS 'ملخص الحل الذي تم تطبيقه';

-- تفعيل RLS
ALTER TABLE ai_assistant_conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY ai_conversations_select_policy ON ai_assistant_conversations
    FOR SELECT USING (user_id = uid());

CREATE POLICY ai_conversations_insert_policy ON ai_assistant_conversations
    FOR INSERT WITH CHECK (user_id = uid());

CREATE POLICY ai_conversations_update_policy ON ai_assistant_conversations
    FOR UPDATE USING (user_id = uid()) WITH CHECK (user_id = uid());

CREATE POLICY ai_conversations_delete_policy ON ai_assistant_conversations
    FOR DELETE USING (user_id = uid());


-- =============================================
-- جدول رسائل المحادثة
-- =============================================
CREATE TABLE ai_assistant_messages (
    id BIGSERIAL PRIMARY KEY,
    conversation_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    -- بيانات إضافية للرسالة (مثل نتائج البحث في قاعدة البيانات)
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ai_messages_conversation_id ON ai_assistant_messages(conversation_id);
CREATE INDEX idx_ai_messages_user_id ON ai_assistant_messages(user_id);
CREATE INDEX idx_ai_messages_role ON ai_assistant_messages(role);
CREATE INDEX idx_ai_messages_created_at ON ai_assistant_messages(created_at);

COMMENT ON TABLE ai_assistant_messages IS 'رسائل المحادثة بين المستخدم والمساعد الذكي';
COMMENT ON COLUMN ai_assistant_messages.role IS 'دور المرسل: user (المستخدم) أو assistant (المساعد الذكي)';
COMMENT ON COLUMN ai_assistant_messages.metadata IS 'بيانات إضافية مثل نتائج البحث في قاعدة البيانات أو الإجراءات المقترحة';

-- تفعيل RLS
ALTER TABLE ai_assistant_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY ai_messages_select_policy ON ai_assistant_messages
    FOR SELECT USING (user_id = uid());

CREATE POLICY ai_messages_insert_policy ON ai_assistant_messages
    FOR INSERT WITH CHECK (user_id = uid());

CREATE POLICY ai_messages_update_policy ON ai_assistant_messages
    FOR UPDATE USING (user_id = uid()) WITH CHECK (user_id = uid());

CREATE POLICY ai_messages_delete_policy ON ai_assistant_messages
    FOR DELETE USING (user_id = uid());


-- =============================================
-- جدول الإجراءات المقترحة (تحتاج تأكيد)
-- =============================================
CREATE TABLE ai_assistant_actions (
    id BIGSERIAL PRIMARY KEY,
    conversation_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    -- نوع الإجراء المقترح
    action_type VARCHAR(50) NOT NULL CHECK (action_type IN (
        'update_trip',
        'update_driver',
        'update_vehicle',
        'update_company',
        'cancel_trip',
        'change_trip_status',
        'update_payment',
        'other'
    )),
    -- وصف الإجراء بلغة بشرية
    action_description TEXT NOT NULL,
    -- الجدول المستهدف والسجل
    target_table VARCHAR(100),
    target_record_id BIGINT,
    -- البيانات قبل وبعد التعديل
    before_data JSONB,
    proposed_changes JSONB NOT NULL,
    -- حالة الإجراء
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'rejected', 'executed', 'failed')),
    -- تفاصيل التنفيذ
    confirmed_at TIMESTAMP WITH TIME ZONE,
    executed_at TIMESTAMP WITH TIME ZONE,
    rejected_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    execution_error TEXT,
    -- إشعار البريد الإلكتروني
    notification_email VARCHAR(255) DEFAULT 'ezetdin@gmail.com',
    email_sent BOOLEAN DEFAULT FALSE,
    email_sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ai_actions_conversation_id ON ai_assistant_actions(conversation_id);
CREATE INDEX idx_ai_actions_user_id ON ai_assistant_actions(user_id);
CREATE INDEX idx_ai_actions_status ON ai_assistant_actions(status);
CREATE INDEX idx_ai_actions_action_type ON ai_assistant_actions(action_type);
CREATE INDEX idx_ai_actions_target_table ON ai_assistant_actions(target_table);
CREATE INDEX idx_ai_actions_target_record ON ai_assistant_actions(target_record_id);
CREATE INDEX idx_ai_actions_pending ON ai_assistant_actions(status, created_at) WHERE status = 'pending';
CREATE INDEX idx_ai_actions_email_sent ON ai_assistant_actions(email_sent) WHERE email_sent = FALSE;

COMMENT ON TABLE ai_assistant_actions IS 'الإجراءات المقترحة من المساعد الذكي التي تحتاج تأكيد المستخدم قبل التنفيذ';
COMMENT ON COLUMN ai_assistant_actions.action_type IS 'نوع الإجراء: تعديل رحلة، سائق، مركبة، شركة، إلغاء رحلة، إلخ';
COMMENT ON COLUMN ai_assistant_actions.action_description IS 'وصف واضح للإجراء المقترح بلغة يفهمها المستخدم';
COMMENT ON COLUMN ai_assistant_actions.before_data IS 'البيانات الحالية قبل التعديل (للمراجعة والتراجع)';
COMMENT ON COLUMN ai_assistant_actions.proposed_changes IS 'التعديلات المقترحة بصيغة JSON';
COMMENT ON COLUMN ai_assistant_actions.status IS 'حالة الإجراء: pending (بانتظار التأكيد), confirmed (تم التأكيد), rejected (مرفوض), executed (تم التنفيذ), failed (فشل التنفيذ)';
COMMENT ON COLUMN ai_assistant_actions.notification_email IS 'البريد الإلكتروني الذي يستقبل إشعارات الإجراءات - افتراضياً ezetdin@gmail.com';
COMMENT ON COLUMN ai_assistant_actions.email_sent IS 'هل تم إرسال إشعار البريد الإلكتروني';

-- تفعيل RLS
ALTER TABLE ai_assistant_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY ai_actions_select_policy ON ai_assistant_actions
    FOR SELECT USING (user_id = uid());

CREATE POLICY ai_actions_insert_policy ON ai_assistant_actions
    FOR INSERT WITH CHECK (user_id = uid());

CREATE POLICY ai_actions_update_policy ON ai_assistant_actions
    FOR UPDATE USING (user_id = uid()) WITH CHECK (user_id = uid());

CREATE POLICY ai_actions_delete_policy ON ai_assistant_actions
    FOR DELETE USING (user_id = uid());

-- إضافة عمود لتسجيل تفاصيل الخطأ بشكل أوضح عند فشل التنفيذ
ALTER TABLE ai_assistant_actions 
ADD COLUMN IF NOT EXISTS execution_details JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN ai_assistant_actions.execution_details IS 'تفاصيل التنفيذ أو الخطأ بصيغة JSON لتسهيل التشخيص';

-- إضافة عمود لتتبع من قام بالتأكيد
ALTER TABLE ai_assistant_actions 
ADD COLUMN IF NOT EXISTS confirmed_by_user_id BIGINT;

COMMENT ON COLUMN ai_assistant_actions.confirmed_by_user_id IS 'معرف المستخدم الذي أكد الإجراء';

-- إضافة index لتسريع البحث عن الإجراءات الفاشلة
CREATE INDEX IF NOT EXISTS idx_ai_actions_failed 
ON ai_assistant_actions(status, created_at) 
WHERE status = 'failed';

-- ============================================================
-- 1. جدول company_users: ربط المديرين بشركاتهم
-- ============================================================
CREATE TABLE company_users (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,        -- مرجع إلى users.id (المدير/صاحب الشركة)
    company_id BIGINT NOT NULL,     -- مرجع إلى companies.id
    role VARCHAR(50) DEFAULT 'owner' CHECK (role IN ('owner', 'manager')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, company_id)
);

CREATE INDEX idx_company_users_user_id ON company_users(user_id);
CREATE INDEX idx_company_users_company_id ON company_users(company_id);

COMMENT ON TABLE company_users IS 'ربط حسابات المديرين/أصحاب الشركات بشركاتهم';
COMMENT ON COLUMN company_users.user_id IS 'معرف المستخدم من جدول users (user_type = manager)';
COMMENT ON COLUMN company_users.company_id IS 'معرف الشركة من جدول companies';
COMMENT ON COLUMN company_users.role IS 'دور المستخدم في الشركة: owner (صاحب), manager (مدير)';

-- تفعيل RLS
ALTER TABLE company_users ENABLE ROW LEVEL SECURITY;

-- سياسات RLS لجدول company_users
CREATE POLICY company_users_select_policy ON company_users
    FOR SELECT USING (user_id = uid());

CREATE POLICY company_users_insert_policy ON company_users
    FOR INSERT WITH CHECK (user_id = uid());

CREATE POLICY company_users_update_policy ON company_users
    FOR UPDATE USING (user_id = uid()) WITH CHECK (user_id = uid());

CREATE POLICY company_users_delete_policy ON company_users
    FOR DELETE USING (user_id = uid());

-- صلاحيات الأدوار
GRANT SELECT, INSERT, UPDATE, DELETE ON company_users TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON company_users TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE company_users_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE company_users_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================
-- 2. تعديل سياسات RLS على جدول companies
--    إضافة سياسات للمدير ليرى ويعدل شركته فقط
-- ============================================================

-- حذف السياسات القديمة المقيدة
DROP POLICY IF EXISTS companies_select_driver_policy ON companies;
DROP POLICY IF EXISTS companies_insert_admin_policy ON companies;
DROP POLICY IF EXISTS companies_update_admin_policy ON companies;
DROP POLICY IF EXISTS companies_delete_admin_policy ON companies;

-- سياسة SELECT: السائق يرى شركته + المدير يرى شركته
CREATE POLICY companies_select_policy ON companies
    FOR SELECT USING (
        id IN (SELECT company_id FROM company_users WHERE user_id = uid())
        OR
        id IN (SELECT company_id FROM drivers WHERE user_id = uid())
    );

-- سياسة INSERT: المدير فقط يضيف شركة (يتحقق منها في طبقة التطبيق)
CREATE POLICY companies_insert_policy ON companies
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM company_users WHERE user_id = uid() AND company_id = id)
    );

-- سياسة UPDATE: المدير يعدل شركته فقط
CREATE POLICY companies_update_policy ON companies
    FOR UPDATE USING (
        id IN (SELECT company_id FROM company_users WHERE user_id = uid())
    );

-- سياسة DELETE: ممنوع من طبقة المستخدم العادي
CREATE POLICY companies_delete_policy ON companies
    FOR DELETE USING (false);

-- ============================================================
-- 3. تعديل سياسات RLS على جدول vehicles
--    المدير يرى ويدير مركبات شركته
-- ============================================================

-- حذف السياسات القديمة
DROP POLICY IF EXISTS vehicles_select_driver_policy ON vehicles;
DROP POLICY IF EXISTS vehicles_insert_admin_policy ON vehicles;
DROP POLICY IF EXISTS vehicles_update_admin_policy ON vehicles;
DROP POLICY IF EXISTS vehicles_delete_admin_policy ON vehicles;

-- سياسة SELECT: السائق يرى مركبته + المدير يرى مركبات شركته
CREATE POLICY vehicles_select_policy ON vehicles
    FOR SELECT USING (
        id IN (
            SELECT assigned_vehicle_id FROM drivers WHERE user_id = uid() AND assigned_vehicle_id IS NOT NULL
            UNION
            SELECT current_vehicle_id FROM drivers WHERE user_id = uid() AND current_vehicle_id IS NOT NULL
        )
        OR
        company_id IN (SELECT company_id FROM company_users WHERE user_id = uid())
    );

-- سياسة INSERT: المدير يضيف مركبات لشركته
CREATE POLICY vehicles_insert_policy ON vehicles
    FOR INSERT WITH CHECK (
        company_id IN (SELECT company_id FROM company_users WHERE user_id = uid())
    );

-- سياسة UPDATE: المدير يعدل مركبات شركته
CREATE POLICY vehicles_update_policy ON vehicles
    FOR UPDATE USING (
        company_id IN (SELECT company_id FROM company_users WHERE user_id = uid())
    );

-- سياسة DELETE: المدير يحذف مركبات شركته
CREATE POLICY vehicles_delete_policy ON vehicles
    FOR DELETE USING (
        company_id IN (SELECT company_id FROM company_users WHERE user_id = uid())
    );

-- ============================================================
-- 4. تعديل سياسات RLS على جدول drivers
--    المدير يرى ويدير سائقي شركته
-- ============================================================

-- حذف السياسات القديمة
DROP POLICY IF EXISTS drivers_select_policy ON drivers;
DROP POLICY IF EXISTS drivers_insert_policy ON drivers;
DROP POLICY IF EXISTS drivers_update_policy ON drivers;
DROP POLICY IF EXISTS drivers_delete_policy ON drivers;

-- سياسة SELECT: السائق يرى بياناته + المدير يرى سائقي شركته
CREATE POLICY drivers_select_policy ON drivers
    FOR SELECT USING (
        user_id = uid()
        OR
        company_id IN (SELECT company_id FROM company_users WHERE user_id = uid())
    );

-- سياسة INSERT: السائق يسجل نفسه + المدير يضيف سائقاً لشركته
CREATE POLICY drivers_insert_policy ON drivers
    FOR INSERT WITH CHECK (
        user_id = uid()
        OR
        company_id IN (SELECT company_id FROM company_users WHERE user_id = uid())
    );

-- سياسة UPDATE: السائق يعدل بياناته + المدير يعدل سائقي شركته
CREATE POLICY drivers_update_policy ON drivers
    FOR UPDATE USING (
        user_id = uid()
        OR
        company_id IN (SELECT company_id FROM company_users WHERE user_id = uid())
    );

-- سياسة DELETE: المدير يحذف سائقي شركته فقط
CREATE POLICY drivers_delete_policy ON drivers
    FOR DELETE USING (
        user_id = uid()
        OR
        company_id IN (SELECT company_id FROM company_users WHERE user_id = uid())
    );

-- =====================================================
-- 1. إضافة حقل كلمة المرور لجدول الشركات
-- =====================================================
ALTER TABLE companies 
ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);

COMMENT ON COLUMN companies.password_hash IS 'كلمة مرور الشركة المشفرة bcrypt - تستخدم لتسجيل الدخول إلى لوحة تحكم الشركة';

-- تحديث كلمة المرور لجميع الشركات الموجودة حالياً إلى 774411
-- bcrypt hash لكلمة المرور 774411
UPDATE companies 
SET password_hash = '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'
WHERE password_hash IS NULL;

-- =====================================================
-- 2. جدول الملف الشخصي للسائق في بوابة السائق
-- =====================================================
CREATE TABLE IF NOT EXISTS driver_profiles (
    id BIGSERIAL PRIMARY KEY,
    driver_id BIGINT NOT NULL UNIQUE,
    email VARCHAR(255),
    email_verified BOOLEAN DEFAULT false,
    avatar_url TEXT,
    bio TEXT,
    emergency_contact_name VARCHAR(200),
    emergency_contact_phone VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE driver_profiles IS 'الملف الشخصي للسائق في بوابة السائق - بيانات إضافية قابلة للتعديل من السائق';
COMMENT ON COLUMN driver_profiles.driver_id IS 'مرجع إلى drivers.id (علاقة منطقية)';
COMMENT ON COLUMN driver_profiles.email IS 'البريد الإلكتروني للسائق - يمكن تعديله مع التحقق عبر كود';
COMMENT ON COLUMN driver_profiles.email_verified IS 'هل تم التحقق من البريد الإلكتروني';
COMMENT ON COLUMN driver_profiles.avatar_url IS 'رابط الصورة الشخصية للسائق';
COMMENT ON COLUMN driver_profiles.emergency_contact_name IS 'اسم جهة الاتصال في حالات الطوارئ';
COMMENT ON COLUMN driver_profiles.emergency_contact_phone IS 'رقم هاتف جهة الاتصال في حالات الطوارئ';

CREATE INDEX IF NOT EXISTS idx_driver_profiles_driver_id ON driver_profiles(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_profiles_email ON driver_profiles(email);

-- =====================================================
-- 3. جدول كودات التحقق للسائقين (تغيير البريد/كلمة المرور)
-- =====================================================
CREATE TABLE IF NOT EXISTS driver_verification_codes (
    id BIGSERIAL PRIMARY KEY,
    driver_id BIGINT NOT NULL,
    code VARCHAR(10) NOT NULL,
    code_type VARCHAR(50) NOT NULL DEFAULT 'EMAIL_CHANGE',
    target_value VARCHAR(255),
    is_used BOOLEAN DEFAULT false,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE driver_verification_codes IS 'كودات التحقق للسائقين - تستخدم عند تغيير البريد الإلكتروني أو كلمة المرور';
COMMENT ON COLUMN driver_verification_codes.driver_id IS 'مرجع إلى drivers.id';
COMMENT ON COLUMN driver_verification_codes.code IS 'كود التحقق المكون من 6 أرقام';
COMMENT ON COLUMN driver_verification_codes.code_type IS 'نوع الكود: EMAIL_CHANGE, PASSWORD_CHANGE';
COMMENT ON COLUMN driver_verification_codes.target_value IS 'القيمة المستهدفة (البريد الجديد مثلاً)';
COMMENT ON COLUMN driver_verification_codes.is_used IS 'هل تم استخدام الكود';
COMMENT ON COLUMN driver_verification_codes.expires_at IS 'تاريخ انتهاء صلاحية الكود (3 دقائق)';

CREATE INDEX IF NOT EXISTS idx_driver_verification_codes_driver_id ON driver_verification_codes(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_verification_codes_code ON driver_verification_codes(code);
CREATE INDEX IF NOT EXISTS idx_driver_verification_codes_expires_at ON driver_verification_codes(expires_at);

-- =====================================================
-- 4. إنشاء ملف شخصي افتراضي للسائقين الموجودين
-- =====================================================
INSERT INTO driver_profiles (driver_id)
SELECT id FROM drivers
WHERE id NOT IN (SELECT driver_id FROM driver_profiles)
ON CONFLICT (driver_id) DO NOTHING;

-- =====================================================
-- 5. منح الصلاحيات للجداول الجديدة
-- =====================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON driver_profiles TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON driver_profiles TO app20251225073911jaqqaxdfir_v1_user;

GRANT SELECT, INSERT, UPDATE, DELETE ON driver_verification_codes TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON driver_verification_codes TO app20251225073911jaqqaxdfir_v1_user;

GRANT USAGE, SELECT ON SEQUENCE driver_profiles_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE driver_profiles_id_seq TO app20251225073911jaqqaxdfir_v1_user;

GRANT USAGE, SELECT ON SEQUENCE driver_verification_codes_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE driver_verification_codes_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- إضافة حقل قناة الإرسال وبيانات إضافية لجدول الإشعارات
ALTER TABLE notifications
    ADD COLUMN IF NOT EXISTS delivery_channel VARCHAR(20) DEFAULT 'in_app'
        CHECK (delivery_channel IN ('in_app', 'push', 'sms', 'all')),
    ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';

COMMENT ON COLUMN notifications.delivery_channel IS 'قناة إرسال الإشعار: in_app (داخل التطبيق), push (إشعار دفع), sms (رسالة نصية), all (جميع القنوات)';
COMMENT ON COLUMN notifications.metadata IS 'بيانات إضافية مرنة للإشعار (JSON) مثل رابط الرحلة، معرف الفاتورة، إلخ';

-- إضافة حقل dismissed_at لتتبع الإشعارات المُخفاة من السائق
ALTER TABLE user_notifications
    ADD COLUMN IF NOT EXISTS dismissed_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS notification_channel VARCHAR(20) DEFAULT 'in_app';

COMMENT ON COLUMN user_notifications.dismissed_at IS 'وقت إخفاء الإشعار من قِبل السائق (بدون حذفه)';
COMMENT ON COLUMN user_notifications.notification_channel IS 'القناة التي وصل منها الإشعار للمستخدم';

-- إضافة index لتحسين استعلامات الإشعارات غير المقروءة والمخفاة
CREATE INDEX IF NOT EXISTS idx_user_notifications_dismissed
    ON user_notifications(user_id, dismissed_at)
    WHERE dismissed_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_user_notifications_unread_active
    ON user_notifications(user_id, is_read, created_at DESC)
    WHERE is_read = false;

-- إضافة index على metadata لدعم البحث داخل JSON
CREATE INDEX IF NOT EXISTS idx_notifications_metadata
    ON notifications USING gin(metadata);

-- إضافة index على delivery_channel
CREATE INDEX IF NOT EXISTS idx_notifications_delivery_channel
    ON notifications(delivery_channel);

CREATE TABLE privacy_policy_versions (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    version_code VARCHAR(50) NOT NULL UNIQUE,
    language_code VARCHAR(10) NOT NULL DEFAULT 'ar',
    summary TEXT,
    content_url TEXT,
    effective_from TIMESTAMP WITH TIME ZONE NOT NULL,
    effective_to TIMESTAMP WITH TIME ZONE,
    is_current BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cookie_categories (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_required BOOLEAN NOT NULL DEFAULT false,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_consents (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    consent_scope VARCHAR(50) NOT NULL,
    consent_key VARCHAR(100) NOT NULL,
    consent_version VARCHAR(50),
    granted BOOLEAN NOT NULL,
    consent_text_snapshot TEXT,
    consent_method VARCHAR(30) NOT NULL DEFAULT 'settings',
    ip_address INET,
    user_agent TEXT,
    consent_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    withdrawn_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_consents_scope_check CHECK (consent_scope IN ('privacy_policy', 'cookie_category', 'marketing', 'data_processing', 'third_party_sharing')),
    CONSTRAINT user_consents_method_check CHECK (consent_method IN ('banner', 'settings', 'signup', 'support', 'import'))
);

CREATE TABLE data_subject_requests (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    request_type VARCHAR(30) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'submitted',
    request_details TEXT,
    requested_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_at TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    export_file_url TEXT,
    handled_by_user_id BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT data_subject_requests_type_check CHECK (request_type IN ('access', 'rectification', 'erasure', 'portability', 'restriction', 'objection')),
    CONSTRAINT data_subject_requests_status_check CHECK (status IN ('submitted', 'in_review', 'approved', 'rejected', 'completed', 'cancelled'))
);

CREATE TABLE personal_data_breach_incidents (
    id BIGSERIAL PRIMARY KEY,
    incident_code VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    detected_at TIMESTAMP WITH TIME ZONE NOT NULL,
    occurred_at TIMESTAMP WITH TIME ZONE,
    risk_level VARCHAR(20) NOT NULL DEFAULT 'medium',
    authority_notification_required BOOLEAN NOT NULL DEFAULT false,
    user_notification_required BOOLEAN NOT NULL DEFAULT false,
    authority_notified_at TIMESTAMP WITH TIME ZONE,
    users_notified_at TIMESTAMP WITH TIME ZONE,
    report_deadline_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'open',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT personal_data_breach_incidents_risk_check CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    CONSTRAINT personal_data_breach_incidents_status_check CHECK (status IN ('open', 'investigating', 'reported', 'contained', 'closed'))
);

CREATE TABLE data_transfer_registry (
    id BIGSERIAL PRIMARY KEY,
    transfer_code VARCHAR(50) NOT NULL UNIQUE,
    data_category VARCHAR(100) NOT NULL,
    destination_country VARCHAR(100) NOT NULL,
    recipient_type VARCHAR(50) NOT NULL,
    transfer_purpose TEXT NOT NULL,
    legal_basis VARCHAR(100) NOT NULL,
    safeguard_mechanism VARCHAR(100) NOT NULL,
    transfer_frequency VARCHAR(50),
    is_personal_data BOOLEAN NOT NULL DEFAULT true,
    is_active BOOLEAN NOT NULL DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT data_transfer_registry_recipient_type_check CHECK (recipient_type IN ('processor', 'subprocessor', 'partner', 'authority', 'internal_group')),
    CONSTRAINT data_transfer_registry_safeguard_check CHECK (safeguard_mechanism IN ('adequacy_decision', 'scc', 'bcr', 'explicit_consent', 'contract_necessity', 'legal_obligation', 'other'))
);

CREATE INDEX idx_privacy_policy_versions_is_current ON privacy_policy_versions(is_current);
CREATE INDEX idx_privacy_policy_versions_language_code ON privacy_policy_versions(language_code);
CREATE INDEX idx_privacy_policy_versions_effective_from ON privacy_policy_versions(effective_from);

CREATE INDEX idx_cookie_categories_is_active ON cookie_categories(is_active);
CREATE INDEX idx_cookie_categories_display_order ON cookie_categories(display_order);

CREATE INDEX idx_user_consents_user_id ON user_consents(user_id);
CREATE INDEX idx_user_consents_scope ON user_consents(consent_scope);
CREATE INDEX idx_user_consents_key ON user_consents(consent_key);
CREATE INDEX idx_user_consents_time ON user_consents(consent_time);
CREATE INDEX idx_user_consents_user_scope_key ON user_consents(user_id, consent_scope, consent_key);

CREATE INDEX idx_data_subject_requests_user_id ON data_subject_requests(user_id);
CREATE INDEX idx_data_subject_requests_type ON data_subject_requests(request_type);
CREATE INDEX idx_data_subject_requests_status ON data_subject_requests(status);
CREATE INDEX idx_data_subject_requests_requested_at ON data_subject_requests(requested_at);

CREATE INDEX idx_personal_data_breach_incidents_status ON personal_data_breach_incidents(status);
CREATE INDEX idx_personal_data_breach_incidents_detected_at ON personal_data_breach_incidents(detected_at);
CREATE INDEX idx_personal_data_breach_incidents_report_deadline_at ON personal_data_breach_incidents(report_deadline_at);

CREATE INDEX idx_data_transfer_registry_destination_country ON data_transfer_registry(destination_country);
CREATE INDEX idx_data_transfer_registry_is_active ON data_transfer_registry(is_active);
CREATE INDEX idx_data_transfer_registry_safeguard_mechanism ON data_transfer_registry(safeguard_mechanism);

COMMENT ON TABLE privacy_policy_versions IS 'Versioned privacy policy records for GDPR transparency and auditability';
COMMENT ON TABLE cookie_categories IS 'Cookie categories used by consent banner to allow accept or reject of non-essential cookies';
COMMENT ON TABLE user_consents IS 'Auditable user consent records for GDPR compliance';
COMMENT ON TABLE data_subject_requests IS 'GDPR data subject rights requests such as access, rectification, erasure, and portability';
COMMENT ON TABLE personal_data_breach_incidents IS 'Registry of personal data breach incidents including 72-hour reporting deadline';
COMMENT ON TABLE data_transfer_registry IS 'Registry of personal data transfers, including transfers outside the EEA and safeguards';

ALTER TABLE user_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_subject_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_consents_select_policy ON user_consents
    FOR SELECT USING (user_id = uid());

CREATE POLICY user_consents_insert_policy ON user_consents
    FOR INSERT WITH CHECK (user_id = uid());

CREATE POLICY user_consents_update_policy ON user_consents
    FOR UPDATE USING (user_id = uid()) WITH CHECK (user_id = uid());

CREATE POLICY user_consents_delete_policy ON user_consents
    FOR DELETE USING (user_id = uid());

CREATE POLICY data_subject_requests_select_policy ON data_subject_requests
    FOR SELECT USING (user_id = uid());

CREATE POLICY data_subject_requests_insert_policy ON data_subject_requests
    FOR INSERT WITH CHECK (user_id = uid());

CREATE POLICY data_subject_requests_update_policy ON data_subject_requests
    FOR UPDATE USING (user_id = uid()) WITH CHECK (user_id = uid());

CREATE POLICY data_subject_requests_delete_policy ON data_subject_requests
    FOR DELETE USING (user_id = uid());

INSERT INTO privacy_policy_versions (title, version_code, language_code, summary, content_url, effective_from, effective_to, is_current) VALUES
('سياسة الخصوصية الرئيسية', 'PP-2024-01', 'ar', 'الإصدار الأول لسياسة الخصوصية الخاصة بالمنصة.', 'https://example.com/privacy/ar/v1', '2024-01-01 00:00:00+00', '2024-06-30 23:59:59+00', false),
('سياسة الخصوصية الرئيسية', 'PP-2024-07', 'ar', 'تحديث يوضح أغراض المعالجة وحقوق المستخدمين.', 'https://example.com/privacy/ar/v2', '2024-07-01 00:00:00+00', NULL, true),
('Privacy Policy', 'PP-2024-01-EN', 'en', 'Initial English privacy policy version.', 'https://example.com/privacy/en/v1', '2024-01-01 00:00:00+00', '2024-06-30 23:59:59+00', false),
('Privacy Policy', 'PP-2024-07-EN', 'en', 'Updated English privacy policy with clearer consent language.', 'https://example.com/privacy/en/v2', '2024-07-01 00:00:00+00', NULL, true),
('Politique de confidentialité', 'PP-2024-07-FR', 'fr', 'Version française de la politique de confidentialité.', 'https://example.com/privacy/fr/v2', '2024-07-01 00:00:00+00', NULL, false);

INSERT INTO cookie_categories (code, name, description, is_required, display_order, is_active) VALUES
('necessary', 'Necessary Cookies', 'Cookies required for login, security, and core platform functionality.', true, 1, true),
('preferences', 'Preference Cookies', 'Cookies used to remember language and interface preferences.', false, 2, true),
('analytics', 'Analytics Cookies', 'Cookies used to measure usage and improve product performance.', false, 3, true),
('marketing', 'Marketing Cookies', 'Cookies used for advertising and campaign measurement.', false, 4, true),
('third_party', 'Third-Party Integrations', 'Cookies set by embedded services and external integrations.', false, 5, true);

INSERT INTO personal_data_breach_incidents (
    incident_code, title, description, detected_at, occurred_at, risk_level,
    authority_notification_required, user_notification_required,
    authority_notified_at, users_notified_at, report_deadline_at, status
) VALUES
('BR-2024-001', 'Unauthorized access to support dashboard', 'Investigation found a short-lived unauthorized session in the support dashboard.', '2024-03-10 08:00:00+00', '2024-03-10 07:15:00+00', 'medium', true, false, '2024-03-11 12:00:00+00', NULL, '2024-03-13 08:00:00+00', 'reported'),
('BR-2024-002', 'Email attachment sent to wrong recipient', 'A support export containing customer contact details was emailed to the wrong recipient.', '2024-04-22 14:30:00+00', '2024-04-22 14:00:00+00', 'high', true, true, '2024-04-23 09:15:00+00', '2024-04-23 10:00:00+00', '2024-04-25 14:30:00+00', 'contained'),
('BR-2024-003', 'Temporary analytics log over-collection', 'A logging bug captured extra request headers for a limited period.', '2024-05-05 11:00:00+00', '2024-05-04 23:00:00+00', 'low', false, false, NULL, NULL, '2024-05-08 11:00:00+00', 'closed'),
('BR-2024-004', 'Lost encrypted company laptop', 'An employee laptop used for back-office operations was reported lost.', '2024-06-01 16:20:00+00', '2024-06-01 15:45:00+00', 'medium', false, false, NULL, NULL, '2024-06-04 16:20:00+00', 'investigating'),
('BR-2024-005', 'Misconfigured storage access policy', 'A storage bucket policy briefly exposed archived documents internally beyond intended scope.', '2024-06-18 07:50:00+00', '2024-06-18 07:10:00+00', 'critical', true, true, NULL, NULL, '2024-06-21 07:50:00+00', 'open');

INSERT INTO data_transfer_registry (
    transfer_code, data_category, destination_country, recipient_type,
    transfer_purpose, legal_basis, safeguard_mechanism, transfer_frequency,
    is_personal_data, is_active, notes
) VALUES
('DTR-001', 'User account data', 'Germany', 'processor', 'Cloud hosting and managed infrastructure operations.', 'contract_performance', 'adequacy_decision', 'continuous', true, true, 'Data hosted within the EU region.'),
('DTR-002', 'Support communications', 'United States', 'processor', 'Ticketing and customer support processing.', 'legitimate_interest', 'scc', 'continuous', true, true, 'Standard Contractual Clauses signed with provider.'),
('DTR-003', 'Email delivery metadata', 'Ireland', 'processor', 'Transactional email delivery and deliverability monitoring.', 'contract_performance', 'adequacy_decision', 'continuous', true, true, 'Provider operates from EU data centers.'),
('DTR-004', 'Product analytics events', 'Netherlands', 'subprocessor', 'Usage analytics for product improvement and stability monitoring.', 'consent', 'adequacy_decision', 'continuous', true, true, 'Only enabled after analytics consent.'),
('DTR-005', 'Dispute investigation files', 'United Kingdom', 'authority', 'Legal compliance and dispute handling when formally requested.', 'legal_obligation', 'adequacy_decision', 'occasional', true, true, 'Transferred only upon verified legal request.');

ALTER TABLE invoices
    ADD COLUMN vehicle_plate_number VARCHAR(50),
    ADD COLUMN dienstnummer VARCHAR(100),
    ADD COLUMN identificatiecode VARCHAR(100),
    ADD COLUMN toegepast_tarief VARCHAR(100),
    ADD COLUMN meterbedrag NUMERIC(10,2),
    ADD COLUMN ritnummer VARCHAR(100);

CREATE INDEX idx_invoices_vehicle_plate_number ON invoices(vehicle_plate_number);
CREATE INDEX idx_invoices_ritnummer_snapshot ON invoices(ritnummer);

COMMENT ON COLUMN invoices.vehicle_plate_number IS 'رقم لوحة السيارة الظاهر في فاتورة الزبون';
COMMENT ON COLUMN invoices.dienstnummer IS 'Dienstnummer الظاهر في فاتورة الزبون';
COMMENT ON COLUMN invoices.identificatiecode IS 'Identificatiecode الظاهر في فاتورة الزبون';
COMMENT ON COLUMN invoices.toegepast_tarief IS 'Toegepast tarief الظاهر في فاتورة الزبون';
COMMENT ON COLUMN invoices.meterbedrag IS 'Meterbedrag الظاهر في فاتورة الزبون';
COMMENT ON COLUMN invoices.ritnummer IS 'Ritnummer snapshot محفوظ داخل الفاتورة لثبات بيانات المستند';

ALTER TABLE trips
    ADD COLUMN trip_uuid VARCHAR(100),
    ADD COLUMN trip_hash VARCHAR(128),
    ADD COLUMN locked_after_completion BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN locked_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN record_retention_until DATE,
    ADD COLUMN immutable_notes TEXT;

UPDATE trips
SET trip_uuid = md5(
        id::text || '-' ||
        COALESCE(ritnummer, '') || '-' ||
        COALESCE(start_time::text, '') || '-' ||
        COALESCE(driver_id::text, '') || '-' ||
        COALESCE(vehicle_id::text, '')
    ),
    record_retention_until = ((COALESCE(end_time, start_time))::date + INTERVAL '7 years')::date
WHERE trip_uuid IS NULL
   OR record_retention_until IS NULL;

ALTER TABLE trips
    ALTER COLUMN trip_uuid SET NOT NULL;

CREATE UNIQUE INDEX idx_trips_trip_uuid ON app20251225073911jaqqaxdfir_v1.trips USING btree (trip_uuid);
CREATE INDEX idx_trips_locked_after_completion ON app20251225073911jaqqaxdfir_v1.trips USING btree (locked_after_completion);
CREATE INDEX idx_trips_record_retention_until ON app20251225073911jaqqaxdfir_v1.trips USING btree (record_retention_until);

COMMENT ON COLUMN trips.trip_uuid IS 'معرف عالمي ثابت للرحلة لأغراض الامتثال القانوني والتتبع الرقابي';
COMMENT ON COLUMN trips.trip_hash IS 'بصمة تحقق لبيانات الرحلة بعد الإغلاق للمساعدة في كشف أي تلاعب';
COMMENT ON COLUMN trips.locked_after_completion IS 'يصبح true عند إغلاق الرحلة نهائياً لمنع تعديلها تشغيلياً في التطبيق';
COMMENT ON COLUMN trips.locked_at IS 'وقت قفل الرحلة بعد الاكتمال';
COMMENT ON COLUMN trips.record_retention_until IS 'تاريخ الحد الأدنى للاحتفاظ القانوني بالسجل، 7 سنوات';
COMMENT ON COLUMN trips.immutable_notes IS 'ملاحظات امتثال أو تفسير سبب أي استثناء قانوني/تقني على الرحلة';

ALTER TABLE invoices
    ADD COLUMN document_type VARCHAR(30) DEFAULT 'invoice',
    ADD COLUMN legal_document_title VARCHAR(100),
    ADD COLUMN complaint_authority_name VARCHAR(255),
    ADD COLUMN complaint_authority_url TEXT,
    ADD COLUMN driver_name_snapshot VARCHAR(200),
    ADD COLUMN driver_capacity_certificate_snapshot VARCHAR(100),
    ADD COLUMN driver_bestuurderspas_snapshot VARCHAR(100),
    ADD COLUMN vehicle_identifier_snapshot VARCHAR(150),
    ADD COLUMN start_address_snapshot TEXT,
    ADD COLUMN end_address_snapshot TEXT,
    ADD COLUMN start_lat_snapshot NUMERIC(10,8),
    ADD COLUMN start_lon_snapshot NUMERIC(11,8),
    ADD COLUMN end_lat_snapshot NUMERIC(10,8),
    ADD COLUMN end_lon_snapshot NUMERIC(11,8),
    ADD COLUMN distance_km_snapshot NUMERIC(10,2),
    ADD COLUMN tariff_snapshot VARCHAR(150),
    ADD COLUMN final_amount_snapshot NUMERIC(10,2),
    ADD COLUMN trip_uuid_snapshot VARCHAR(100),
    ADD COLUMN chiron_submission_status_snapshot VARCHAR(50),
    ADD COLUMN chiron_transmission_id_snapshot VARCHAR(100),
    ADD COLUMN issued_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE invoices
    ADD CONSTRAINT invoices_document_type_check
    CHECK (document_type IN ('invoice', 'vervoerbewijs', 'invoice_vervoerbewijs'));

CREATE INDEX idx_invoices_document_type ON app20251225073911jaqqaxdfir_v1.invoices USING btree (document_type);
CREATE INDEX idx_invoices_trip_uuid_snapshot ON app20251225073911jaqqaxdfir_v1.invoices USING btree (trip_uuid_snapshot);
CREATE INDEX idx_invoices_chiron_submission_status_snapshot ON app20251225073911jaqqaxdfir_v1.invoices USING btree (chiron_submission_status_snapshot);

COMMENT ON COLUMN invoices.document_type IS 'نوع المستند القانوني: invoice أو vervoerbewijs أو مستند يجمع الاثنين';
COMMENT ON COLUMN invoices.legal_document_title IS 'العنوان القانوني الظاهر على المستند مثل VERVOERBEWIJS';
COMMENT ON COLUMN invoices.complaint_authority_name IS 'الجهة المختصة بالشكاوى كما تظهر على المستند';
COMMENT ON COLUMN invoices.complaint_authority_url IS 'رابط معلومات الشكاوى والتنظيم الرسمي';
COMMENT ON COLUMN invoices.driver_name_snapshot IS 'نسخة ثابتة من اسم السائق وقت إصدار المستند';
COMMENT ON COLUMN invoices.driver_capacity_certificate_snapshot IS 'نسخة ثابتة من رقم شهادة الكفاءة/التعريف المهني للسائق';
COMMENT ON COLUMN invoices.driver_bestuurderspas_snapshot IS 'نسخة ثابتة من رقم Bestuurderspas وقت الإصدار';
COMMENT ON COLUMN invoices.vehicle_identifier_snapshot IS 'تعريف المركبة كما يظهر قانونياً على المستند';
COMMENT ON COLUMN invoices.start_address_snapshot IS 'نسخة ثابتة من عنوان الانطلاق';
COMMENT ON COLUMN invoices.end_address_snapshot IS 'نسخة ثابتة من عنوان الوصول';
COMMENT ON COLUMN invoices.start_lat_snapshot IS 'نسخة ثابتة من GPS نقطة الانطلاق';
COMMENT ON COLUMN invoices.start_lon_snapshot IS 'نسخة ثابتة من GPS نقطة الانطلاق';
COMMENT ON COLUMN invoices.end_lat_snapshot IS 'نسخة ثابتة من GPS نقطة الوصول';
COMMENT ON COLUMN invoices.end_lon_snapshot IS 'نسخة ثابتة من GPS نقطة الوصول';
COMMENT ON COLUMN invoices.distance_km_snapshot IS 'المسافة القانونية الظاهرة على vervoerbewijs';
COMMENT ON COLUMN invoices.tariff_snapshot IS 'التعرفة المطبقة بصياغة قانونية ثابتة';
COMMENT ON COLUMN invoices.final_amount_snapshot IS 'المبلغ النهائي الواجب دفعه كما ظهر وقت الإصدار';
COMMENT ON COLUMN invoices.trip_uuid_snapshot IS 'نسخة ثابتة من المعرف العالمي للرحلة داخل المستند';
COMMENT ON COLUMN invoices.chiron_submission_status_snapshot IS 'حالة إرسال الرحلة إلى Chiron وقت إصدار المستند';
COMMENT ON COLUMN invoices.chiron_transmission_id_snapshot IS 'معرف الإرسال/الرسالة المرتبط بـ Chiron إن وجد';
COMMENT ON COLUMN invoices.issued_at IS 'وقت إصدار المستند الإلكتروني';

ALTER TABLE chiron_sync_log
    ADD COLUMN transmission_type VARCHAR(20),
    ADD COLUMN transmission_id VARCHAR(100),
    ADD COLUMN signed_log_hash VARCHAR(128);

ALTER TABLE chiron_sync_log
    ADD CONSTRAINT chiron_sync_log_transmission_type_check
    CHECK (transmission_type IS NULL OR transmission_type IN ('start', 'arrival', 'update', 'receipt'));

CREATE INDEX idx_chiron_sync_log_transmission_type ON app20251225073911jaqqaxdfir_v1.chiron_sync_log USING btree (transmission_type);
CREATE INDEX idx_chiron_sync_log_transmission_id ON app20251225073911jaqqaxdfir_v1.chiron_sync_log USING btree (transmission_id);

COMMENT ON COLUMN chiron_sync_log.transmission_type IS 'نوع الرسالة المرسلة إلى Chiron مثل start أو arrival';
COMMENT ON COLUMN chiron_sync_log.transmission_id IS 'المعرف المرجعي للإرسال أو الرسالة المستلمة من Chiron';
COMMENT ON COLUMN chiron_sync_log.signed_log_hash IS 'بصمة تحقق للسجل لدعم الأثر التدقيقي وعدم التلاعب';

ALTER TABLE trip_state_transitions
    ADD COLUMN transition_hash VARCHAR(128),
    ADD COLUMN is_system_generated BOOLEAN NOT NULL DEFAULT true;

CREATE INDEX idx_trip_state_transitions_transition_hash ON app20251225073911jaqqaxdfir_v1.trip_state_transitions USING btree (transition_hash);

COMMENT ON COLUMN trip_state_transitions.transition_hash IS 'بصمة تحقق لكل انتقال حالة ضمن الأثر التدقيقي';
COMMENT ON COLUMN trip_state_transitions.is_system_generated IS 'هل الانتقال مولد آلياً من النظام أم أضيف استثنائياً من الإدارة';

CREATE TABLE vehicle_documents (
    id BIGSERIAL PRIMARY KEY,
    vehicle_id BIGINT NOT NULL,
    company_id BIGINT NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_mime_type VARCHAR(100) NOT NULL DEFAULT 'application/pdf',
    file_size_bytes BIGINT,
    document_number VARCHAR(100),
    issued_date DATE,
    expiry_date DATE,
    approval_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    approved_by_user_id BIGINT,
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    is_current BOOLEAN NOT NULL DEFAULT true,
    locked_after_approval BOOLEAN NOT NULL DEFAULT false,
    uploaded_by_user_id BIGINT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT vehicle_documents_document_type_check CHECK (
        document_type IN (
            'controle_technique',
            'assurance',
            'certificat_immatriculation',
            'vignette_taxi'
        )
    ),
    CONSTRAINT vehicle_documents_approval_status_check CHECK (
        approval_status IN ('pending', 'approved', 'rejected', 'expired')
    ),
    CONSTRAINT vehicle_documents_file_mime_type_check CHECK (
        lower(file_mime_type) = 'application/pdf'
    )
);

CREATE INDEX idx_vehicle_documents_vehicle_id ON vehicle_documents(vehicle_id);
CREATE INDEX idx_vehicle_documents_company_id ON vehicle_documents(company_id);
CREATE INDEX idx_vehicle_documents_document_type ON vehicle_documents(document_type);
CREATE INDEX idx_vehicle_documents_approval_status ON vehicle_documents(approval_status);
CREATE INDEX idx_vehicle_documents_expiry_date ON vehicle_documents(expiry_date);
CREATE UNIQUE INDEX idx_vehicle_documents_current_unique
    ON vehicle_documents(vehicle_id, document_type)
    WHERE is_current = true;

CREATE TABLE expense_categories (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    scope VARCHAR(20) NOT NULL DEFAULT 'system',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT expense_categories_scope_check CHECK (
        scope IN ('system', 'company')
    )
);

CREATE INDEX idx_expense_categories_company_id ON expense_categories(company_id);
CREATE INDEX idx_expense_categories_scope ON expense_categories(scope);
CREATE INDEX idx_expense_categories_is_active ON expense_categories(is_active);
CREATE UNIQUE INDEX idx_expense_categories_code_company
    ON expense_categories(company_id, code);

ALTER TABLE expenses
    ADD COLUMN category_id BIGINT,
    ADD COLUMN expense_status VARCHAR(20) NOT NULL DEFAULT 'draft',
    ADD COLUMN approved_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN approved_by_user_id BIGINT;

ALTER TABLE expenses
    ADD CONSTRAINT expenses_expense_status_check CHECK (
        expense_status IN ('draft', 'submitted', 'approved', 'rejected', 'paid', 'cancelled')
    );

CREATE INDEX idx_expenses_category_id ON expenses(category_id);
CREATE INDEX idx_expenses_expense_status ON expenses(expense_status);
CREATE INDEX idx_expenses_company_status_date ON expenses(company_id, expense_status, expense_date);

CREATE TABLE expense_attachments (
    id BIGSERIAL PRIMARY KEY,
    expense_id BIGINT NOT NULL,
    company_id BIGINT NOT NULL,
    uploaded_by_user_id BIGINT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_mime_type VARCHAR(100) NOT NULL DEFAULT 'application/pdf',
    file_size_bytes BIGINT,
    document_type VARCHAR(30) NOT NULL DEFAULT 'receipt',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT expense_attachments_document_type_check CHECK (
        document_type IN ('receipt', 'invoice', 'contract', 'other')
    ),
    CONSTRAINT expense_attachments_file_mime_type_check CHECK (
        lower(file_mime_type) = 'application/pdf'
    )
);

CREATE INDEX idx_expense_attachments_expense_id ON expense_attachments(expense_id);
CREATE INDEX idx_expense_attachments_company_id ON expense_attachments(company_id);
CREATE INDEX idx_expense_attachments_uploaded_by_user_id ON expense_attachments(uploaded_by_user_id);
CREATE INDEX idx_expense_attachments_document_type ON expense_attachments(document_type);

ALTER TABLE invoices
    ADD COLUMN archived_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN archived_by_user_id BIGINT,
    ADD COLUMN archive_reason TEXT,
    ADD COLUMN issuer_legal_name_snapshot VARCHAR(200),
    ADD COLUMN issuer_vat_number_snapshot VARCHAR(50),
    ADD COLUMN issuer_kbo_number_snapshot VARCHAR(50),
    ADD COLUMN issuer_iban_snapshot VARCHAR(34),
    ADD COLUMN issuer_bic_snapshot VARCHAR(20),
    ADD COLUMN client_kbo_number_snapshot VARCHAR(50),
    ADD COLUMN invoice_sequence_year INTEGER,
    ADD COLUMN invoice_sequence_number INTEGER;

ALTER TABLE invoices
    ADD CONSTRAINT invoices_invoice_sequence_year_check CHECK (
        invoice_sequence_year IS NULL OR (invoice_sequence_year BETWEEN 2000 AND 2100)
    );

ALTER TABLE invoices
    ADD CONSTRAINT invoices_invoice_sequence_number_check CHECK (
        invoice_sequence_number IS NULL OR invoice_sequence_number > 0
    );

CREATE INDEX idx_invoices_archived_at ON invoices(archived_at);
CREATE INDEX idx_invoices_invoice_sequence_year ON invoices(invoice_sequence_year);
CREATE UNIQUE INDEX idx_invoices_company_sequence_unique
    ON invoices(issuer_company_id, invoice_sequence_year, invoice_sequence_number)
    WHERE invoice_sequence_year IS NOT NULL
      AND invoice_sequence_number IS NOT NULL
      AND issuer_company_id IS NOT NULL;

CREATE TABLE driver_documents (
    id BIGSERIAL PRIMARY KEY,
    driver_id BIGINT NOT NULL,
    company_id BIGINT NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_mime_type VARCHAR(100) NOT NULL DEFAULT 'application/pdf',
    file_size_bytes BIGINT,
    document_number VARCHAR(100),
    issued_date DATE,
    expiry_date DATE,
    verification_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    verified_by_user_id BIGINT,
    verified_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    is_current BOOLEAN NOT NULL DEFAULT true,
    uploaded_by_user_id BIGINT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT driver_documents_document_type_check CHECK (
        document_type IN (
            'driver_license',
            'bestuurderspas',
            'capacity_certificate',
            'identity_document',
            'work_permit'
        )
    ),
    CONSTRAINT driver_documents_verification_status_check CHECK (
        verification_status IN ('pending', 'approved', 'rejected', 'expired')
    ),
    CONSTRAINT driver_documents_file_mime_type_check CHECK (
        lower(file_mime_type) = 'application/pdf'
    )
);

CREATE INDEX idx_driver_documents_driver_id ON driver_documents(driver_id);
CREATE INDEX idx_driver_documents_company_id ON driver_documents(company_id);
CREATE INDEX idx_driver_documents_document_type ON driver_documents(document_type);
CREATE INDEX idx_driver_documents_verification_status ON driver_documents(verification_status);
CREATE INDEX idx_driver_documents_expiry_date ON driver_documents(expiry_date);
CREATE UNIQUE INDEX idx_driver_documents_current_unique
    ON driver_documents(driver_id, document_type)
    WHERE is_current = true;

ALTER TABLE trip_summaries
    DROP CONSTRAINT IF EXISTS trip_summaries_summary_period_check;

ALTER TABLE trip_summaries
    ADD CONSTRAINT trip_summaries_summary_period_check CHECK (
        summary_period IN ('daily', 'weekly', 'monthly', 'yearly', 'custom')
    );

CREATE INDEX idx_trip_summaries_company_period_dates
    ON trip_summaries(company_id, summary_period, period_start_date, period_end_date);

CREATE TABLE security_audit_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    company_id BIGINT,
    event_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL DEFAULT 'info',
    resource_type VARCHAR(50),
    resource_id VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    request_id VARCHAR(100),
    event_details JSONB DEFAULT '{}'::jsonb,
    occurred_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT security_audit_logs_severity_check CHECK (
        severity IN ('info', 'warning', 'critical')
    )
);

CREATE INDEX idx_security_audit_logs_user_id ON security_audit_logs(user_id);
CREATE INDEX idx_security_audit_logs_company_id ON security_audit_logs(company_id);
CREATE INDEX idx_security_audit_logs_event_type ON security_audit_logs(event_type);
CREATE INDEX idx_security_audit_logs_severity ON security_audit_logs(severity);
CREATE INDEX idx_security_audit_logs_occurred_at ON security_audit_logs(occurred_at);

INSERT INTO vehicle_documents (
    vehicle_id, company_id, document_type, file_name, file_url, file_mime_type, file_size_bytes,
    document_number, issued_date, expiry_date, approval_status, approved_by_user_id, approved_at,
    is_current, locked_after_approval, uploaded_by_user_id, notes
) VALUES
(1, 1, 'controle_technique', 'controle-technique-veh-1.pdf', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 245760, 'CT-2025-0001', '2025-01-10', '2026-01-10', 'approved', 1, CURRENT_TIMESTAMP, true, true, 1, 'وثيقة الفحص الفني للمركبة 1'),
(1, 1, 'assurance', 'assurance-veh-1.pdf', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 198210, 'INS-2025-0001', '2025-02-01', '2026-02-01', 'approved', 1, CURRENT_TIMESTAMP, true, true, 1, 'وثيقة التأمين للمركبة 1'),
(2, 1, 'certificat_immatriculation', 'registration-veh-2.pdf', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 178560, 'REG-2025-0020', '2024-11-20', '2029-11-20', 'approved', 1, CURRENT_TIMESTAMP, true, true, 1, 'شهادة التسجيل للمركبة 2'),
(2, 1, 'vignette_taxi', 'vignette-taxi-veh-2.pdf', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 145900, 'VIG-2025-0020', '2025-01-01', '2025-12-31', 'pending', NULL, true, NULL, false, 1, 'بانتظار الاعتماد'),
(3, 2, 'assurance', 'assurance-veh-3.pdf', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 201300, 'INS-2025-3001', '2025-03-15', '2026-03-15', 'approved', 1, CURRENT_TIMESTAMP, true, true, 2, 'تأمين المركبة 3');

INSERT INTO expense_categories (
    company_id, code, name, description, scope, is_active
) VALUES
(NULL, 'fuel', 'وقود', 'مصاريف الوقود اليومية والشهرية', 'system', true),
(NULL, 'insurance', 'تأمين', 'أقساط التأمين على المركبات والشركة', 'system', true),
(NULL, 'maintenance', 'صيانة', 'الصيانة الدورية والإصلاحات', 'system', true),
(NULL, 'rent', 'إيجار', 'إيجار المكاتب أو المواقف أو المركبات', 'system', true),
(NULL, 'taxes', 'ضرائب', 'الضرائب والرسوم الحكومية', 'system', true);

INSERT INTO expense_attachments (
    expense_id, company_id, uploaded_by_user_id, file_name, file_url, file_mime_type, file_size_bytes, document_type
) VALUES
(1, 1, 1, 'fuel-receipt-001.pdf', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 124000, 'receipt'),
(2, 1, 1, 'insurance-invoice-002.pdf', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 228000, 'invoice'),
(3, 1, 1, 'maintenance-contract-003.pdf', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 302000, 'contract'),
(4, 2, 2, 'rent-invoice-004.pdf', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 156000, 'invoice'),
(5, 2, 2, 'tax-document-005.pdf', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 188000, 'other');

INSERT INTO driver_documents (
    driver_id, company_id, document_type, file_name, file_url, file_mime_type, file_size_bytes,
    document_number, issued_date, expiry_date, verification_status, verified_by_user_id, verified_at,
    is_current, uploaded_by_user_id, notes
) VALUES
(1, 1, 'driver_license', 'driver-license-1.pdf', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 142000, 'DL-2025-1001', '2024-05-01', '2029-05-01', 'approved', 1, CURRENT_TIMESTAMP, true, 1, 'رخصة السائق 1'),
(1, 1, 'bestuurderspas', 'bestuurderspas-1.pdf', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 99000, 'BP-2025-1001', '2025-01-15', '2026-01-15', 'approved', 1, CURRENT_TIMESTAMP, true, 1, 'بطاقة السائق البلجيكية'),
(2, 1, 'capacity_certificate', 'capacity-certificate-2.pdf', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 111000, 'CC-2025-2002', '2025-02-10', '2027-02-10', 'approved', 1, CURRENT_TIMESTAMP, true, 1, 'شهادة الكفاءة'),
(2, 1, 'identity_document', 'identity-document-2.pdf', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 103000, 'ID-2025-2002', '2023-06-01', '2033-06-01', 'approved', 1, CURRENT_TIMESTAMP, true, 1, 'هوية السائق'),
(3, 2, 'work_permit', 'work-permit-3.pdf', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 118000, 'WP-2025-3003', '2025-03-01', '2026-03-01', 'pending', NULL, NULL, true, 2, 'بانتظار التحقق');

INSERT INTO security_audit_logs (
    user_id, company_id, event_type, severity, resource_type, resource_id, ip_address, user_agent, request_id, event_details
) VALUES
(1, 1, 'login_success', 'info', 'auth', 'session-1001', '127.0.0.1', 'Mozilla/5.0', 'req-1001', '{"channel":"web","message":"Successful login"}'),
(1, 1, 'invoice_archive', 'warning', 'invoice', '15', '127.0.0.1', 'Mozilla/5.0', 'req-1002', '{"reason":"Archived after final settlement"}'),
(2, 1, 'trip_force_update_attempt', 'critical', 'trip', '88', '127.0.0.1', 'Mozilla/5.0', 'req-1003', '{"blocked":true,"reason":"Trip is locked after completion"}'),
(3, 2, 'document_upload', 'info', 'driver_document', '7', '127.0.0.1', 'Mozilla/5.0', 'req-1004', '{"document_type":"work_permit"}'),
(NULL, 2, 'rate_limit_triggered', 'warning', 'api', 'next_api/invoices', '127.0.0.1', 'System/1.0', 'req-1005', '{"window_seconds":60,"attempts":45}');
