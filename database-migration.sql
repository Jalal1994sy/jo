
-- ============================================================
-- JOUW DRIVER - Complete Database Migration Script
-- PostgreSQL Migration | 65 Tables
-- ============================================================

-- Step 1: Enable required extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Step 2: Create application schema
CREATE SCHEMA IF NOT EXISTS app20251225073911jaqqaxdfir_v1;
SET search_path TO app20251225073911jaqqaxdfir_v1, public;

-- Step 3: Create database roles
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'app20251225073911jaqqaxdfir_v1_user') THEN
    CREATE ROLE app20251225073911jaqqaxdfir_v1_user;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'app20251225073911jaqqaxdfir_v1_admin_user') THEN
    CREATE ROLE app20251225073911jaqqaxdfir_v1_admin_user;
  END IF;
END
$$;

-- Step 4: Helper function for Chiron timestamp validation
CREATE OR REPLACE FUNCTION validate_chiron_timestamp(ts TIMESTAMPTZ)
RETURNS BOOLEAN LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
  RETURN ts IS NOT NULL
    AND ts >= '2000-01-01 00:00:00+00'::TIMESTAMPTZ
    AND ts <= '2099-12-31 23:59:59+00'::TIMESTAMPTZ;
END;
$$;

GRANT EXECUTE ON FUNCTION validate_chiron_timestamp(TIMESTAMPTZ) TO app20251225073911jaqqaxdfir_v1_user;
GRANT EXECUTE ON FUNCTION validate_chiron_timestamp(TIMESTAMPTZ) TO app20251225073911jaqqaxdfir_v1_admin_user;

-- ============================================================
-- CORE TABLES
-- ============================================================

-- Table: users
CREATE TABLE IF NOT EXISTS users (
  id                BIGSERIAL PRIMARY KEY,
  email             VARCHAR(255) NOT NULL,
  password          VARCHAR(255),
  role              VARCHAR(255) DEFAULT 'app20251225073911jaqqaxdfir_v1_user',
  created_at        TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  user_type         VARCHAR(20)  DEFAULT 'admin',
  auth_provider     VARCHAR(20)  DEFAULT 'email',
  google_id         VARCHAR(255),
  avatar_url        TEXT,
  display_name      VARCHAR(255),
  CONSTRAINT users_email_key        UNIQUE (email),
  CONSTRAINT users_google_id_key    UNIQUE (google_id),
  CONSTRAINT users_auth_provider_check CHECK (auth_provider IN ('email','google','facebook','apple')),
  CONSTRAINT users_user_type_check  CHECK  (user_type     IN ('admin','driver','manager','distributor'))
);
CREATE INDEX IF NOT EXISTS idx_users_user_type     ON users (user_type);
CREATE INDEX IF NOT EXISTS idx_users_google_id     ON users (google_id) WHERE google_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_auth_provider ON users (auth_provider);

COMMENT ON TABLE  users           IS 'System users - authentication table';
COMMENT ON COLUMN users.role      IS 'role enum: app20251225073911jaqqaxdfir_v1_user, app20251225073911jaqqaxdfir_v1_admin_user';
COMMENT ON COLUMN users.user_type IS 'User type: admin, driver, manager, distributor';

GRANT SELECT, INSERT, UPDATE, DELETE ON users TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE users_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;

-- ============================================================

-- Table: companies
CREATE TABLE IF NOT EXISTS companies (
  id                             BIGSERIAL PRIMARY KEY,
  name                           VARCHAR(200) NOT NULL,
  vat_number                     VARCHAR(50),
  address                        TEXT,
  email                          VARCHAR(255),
  phone                          VARCHAR(50),
  logo_url                       TEXT,
  created_at                     TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at                     TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  chiron_mode                    VARCHAR(20)  DEFAULT 'TEST',
  chiron_test_client_id          VARCHAR(255),
  chiron_test_client_secret      VARCHAR(255),
  chiron_test_auth_url           VARCHAR(500) DEFAULT 'https://mow-acc.api.vlaanderen.be/oauth/token',
  chiron_test_api_url            VARCHAR(500) DEFAULT 'https://mow-acc.api.vlaanderen.be/chiron/taxirit',
  chiron_prod_client_id          VARCHAR(255),
  chiron_prod_client_secret      VARCHAR(255),
  chiron_prod_auth_url           VARCHAR(500) DEFAULT 'https://mow.api.vlaanderen.be/oauth/token',
  chiron_prod_api_url            VARCHAR(500) DEFAULT 'https://mow.api.vlaanderen.be/chiron/taxirit',
  kbo_number                     VARCHAR(50),
  client_name                    VARCHAR(200),
  bank_account_iban              VARCHAR(34),
  bank_account_bic               VARCHAR(11),
  bank_account_holder            VARCHAR(200),
  base_rate_per_km               NUMERIC(10,2) DEFAULT 2.00,
  base_rate_per_minute           NUMERIC(10,2) DEFAULT 0.50,
  minimum_fare                   NUMERIC(10,2) DEFAULT 10.00,
  airport_surcharge              NUMERIC(10,2) DEFAULT 5.00,
  night_surcharge_percentage     NUMERIC(5,2)  DEFAULT 20.00,
  peak_hour_surcharge_percentage NUMERIC(5,2)  DEFAULT 15.00,
  night_start_hour               INTEGER       DEFAULT 22,
  night_end_hour                 INTEGER       DEFAULT 6,
  peak_hours                     JSONB         DEFAULT '[{"end":"09:00","start":"07:00"},{"end":"19:00","start":"17:00"}]',
  subscription_status            VARCHAR(50)   DEFAULT 'pending_contract',
  current_contract_id            BIGINT,
  subscription_suspended_at      TIMESTAMPTZ,
  suspension_reason              TEXT,
  last_payment_date              DATE,
  next_payment_due_date          DATE,
  payment_overdue_days           INTEGER       DEFAULT 0,
  created_by_distributor_id      BIGINT,
  password_hash                  VARCHAR(255),
  CONSTRAINT companies_kbo_number_key        UNIQUE (kbo_number),
  CONSTRAINT companies_vat_number_key        UNIQUE (vat_number),
  CONSTRAINT companies_chiron_mode_check     CHECK (chiron_mode        IN ('test','production')),
  CONSTRAINT companies_subscription_status_check CHECK (subscription_status IN ('pending_contract','active','suspended','expired','cancelled'))
);
CREATE INDEX IF NOT EXISTS idx_companies_kbo_number          ON companies (kbo_number);
CREATE INDEX IF NOT EXISTS idx_companies_subscription_status ON companies (subscription_status);
CREATE INDEX IF NOT EXISTS idx_companies_current_contract_id ON companies (current_contract_id);
CREATE INDEX IF NOT EXISTS idx_companies_next_payment_due    ON companies (next_payment_due_date);
CREATE INDEX IF NOT EXISTS idx_companies_created_by_distributor        ON companies (created_by_distributor_id);
CREATE INDEX IF NOT EXISTS idx_companies_created_by_distributor_active ON companies (created_by_distributor_id) WHERE created_by_distributor_id IS NOT NULL;

COMMENT ON TABLE companies IS 'Taxi companies with independent pricing and Chiron configurations for multi-tenant system';

GRANT SELECT, INSERT, UPDATE, DELETE ON companies TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON companies TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE companies_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE companies_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================

-- Table: distributors
CREATE TABLE IF NOT EXISTS distributors (
  id                       BIGSERIAL PRIMARY KEY,
  user_id                  BIGINT       NOT NULL,
  full_name                VARCHAR(200) NOT NULL,
  email                    VARCHAR(255) NOT NULL,
  phone                    VARCHAR(50),
  commission_percentage    NUMERIC(5,2) DEFAULT 0.00,
  is_active                BOOLEAN      DEFAULT TRUE,
  notes                    TEXT,
  created_at               TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at               TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  password_hash            VARCHAR(255),
  last_login_at            TIMESTAMPTZ,
  failed_login_attempts    INTEGER      DEFAULT 0,
  account_locked_until     TIMESTAMPTZ,
  CONSTRAINT distributors_email_key UNIQUE (email)
);
CREATE INDEX IF NOT EXISTS idx_distributors_user_id   ON distributors (user_id);
CREATE INDEX IF NOT EXISTS idx_distributors_email     ON distributors (email);
CREATE INDEX IF NOT EXISTS idx_distributors_is_active ON distributors (is_active);

COMMENT ON TABLE distributors IS 'Distributors - intermediaries who manage multiple companies';

GRANT SELECT, INSERT, UPDATE, DELETE ON distributors TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON distributors TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE distributors_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE distributors_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================

-- Table: drivers
CREATE TABLE IF NOT EXISTS drivers (
  id                            BIGSERIAL PRIMARY KEY,
  user_id                       BIGINT       NOT NULL,
  company_id                    BIGINT       NOT NULL,
  full_name                     VARCHAR(200) NOT NULL,
  national_id                   VARCHAR(50),
  driver_license                VARCHAR(50),
  capacity_certificate_number   VARCHAR(50),
  phone                         VARCHAR(50),
  status                        VARCHAR(20)  DEFAULT 'active',
  created_at                    TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at                    TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  current_trip_id               BIGINT,
  created_by_distributor_id     BIGINT,
  preferred_language            VARCHAR(10)  DEFAULT 'ar',
  current_vehicle_id            BIGINT,
  registration_status           VARCHAR(20)  DEFAULT 'pending',
  registration_submitted_at     TIMESTAMPTZ,
  registration_reviewed_at      TIMESTAMPTZ,
  registration_reviewed_by      BIGINT,
  registration_rejection_reason TEXT,
  bestuurderspas_number         VARCHAR(100),
  assigned_vehicle_id           BIGINT,
  CONSTRAINT drivers_preferred_language_check   CHECK (preferred_language   IN ('ar','en','fr','nl')),
  CONSTRAINT drivers_registration_status_check  CHECK (registration_status  IN ('pending','approved','rejected','under_review')),
  CONSTRAINT drivers_status_check               CHECK (status               IN ('active','inactive','suspended'))
);
CREATE INDEX IF NOT EXISTS idx_drivers_user_id                      ON drivers (user_id);
CREATE INDEX IF NOT EXISTS idx_drivers_company_id                   ON drivers (company_id);
CREATE INDEX IF NOT EXISTS idx_drivers_status                       ON drivers (status);
CREATE INDEX IF NOT EXISTS idx_drivers_current_trip_id              ON drivers (current_trip_id);
CREATE INDEX IF NOT EXISTS idx_drivers_created_by_distributor       ON drivers (created_by_distributor_id);
CREATE INDEX IF NOT EXISTS idx_drivers_created_by_distributor_active ON drivers (created_by_distributor_id) WHERE created_by_distributor_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_drivers_preferred_language           ON drivers (preferred_language);
CREATE INDEX IF NOT EXISTS idx_drivers_current_vehicle_id           ON drivers (current_vehicle_id);
CREATE INDEX IF NOT EXISTS idx_drivers_registration_status          ON drivers (registration_status);
CREATE INDEX IF NOT EXISTS idx_drivers_assigned_vehicle_id          ON drivers (assigned_vehicle_id);
CREATE INDEX IF NOT EXISTS idx_drivers_registration_submitted_at    ON drivers (registration_submitted_at);

COMMENT ON TABLE drivers IS 'Taxi drivers information linked to user accounts';

GRANT SELECT, INSERT, UPDATE, DELETE ON drivers TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON drivers TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE drivers_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE drivers_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================

-- Table: vehicles
CREATE TABLE IF NOT EXISTS vehicles (
  id                        BIGSERIAL PRIMARY KEY,
  company_id                BIGINT       NOT NULL,
  brand                     VARCHAR(100) NOT NULL,
  model                     VARCHAR(100) NOT NULL,
  plate_number              VARCHAR(50)  NOT NULL,
  vin                       VARCHAR(100),
  chiron_vehicle_id         VARCHAR(100),
  documents                 JSONB        DEFAULT '[]',
  status                    VARCHAR(20)  DEFAULT 'active',
  created_at                TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at                TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  created_by_distributor_id BIGINT,
  CONSTRAINT vehicles_plate_number_key UNIQUE (plate_number),
  CONSTRAINT vehicles_status_check     CHECK (status IN ('active','maintenance','inactive'))
);
CREATE INDEX IF NOT EXISTS idx_vehicles_company_id                  ON vehicles (company_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_plate_number                ON vehicles (plate_number);
CREATE INDEX IF NOT EXISTS idx_vehicles_status                      ON vehicles (status);
CREATE INDEX IF NOT EXISTS idx_vehicles_created_by_distributor      ON vehicles (created_by_distributor_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_created_by_distributor_active ON vehicles (created_by_distributor_id) WHERE created_by_distributor_id IS NOT NULL;

COMMENT ON TABLE vehicles IS 'Taxi vehicles registry';

GRANT SELECT, INSERT, UPDATE, DELETE ON vehicles TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON vehicles TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE vehicles_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE vehicles_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================

-- Table: driver_credentials
CREATE TABLE IF NOT EXISTS driver_credentials (
  id                  BIGSERIAL PRIMARY KEY,
  driver_id           BIGINT      NOT NULL,
  phone               VARCHAR(50) NOT NULL,
  password_hash       VARCHAR(255) NOT NULL,
  is_active           BOOLEAN     DEFAULT TRUE,
  last_login_at       TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  vehicle_id          BIGINT,
  company_id          BIGINT,
  preferred_language  VARCHAR(10) DEFAULT 'fr',
  CONSTRAINT driver_credentials_driver_id_key          UNIQUE (driver_id),
  CONSTRAINT driver_credentials_phone_key              UNIQUE (phone),
  CONSTRAINT driver_credentials_preferred_language_check CHECK (preferred_language IN ('ar','en','fr','nl'))
);
CREATE INDEX IF NOT EXISTS idx_driver_credentials_driver_id  ON driver_credentials (driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_credentials_phone      ON driver_credentials (phone);
CREATE INDEX IF NOT EXISTS idx_driver_credentials_is_active  ON driver_credentials (is_active);
CREATE INDEX IF NOT EXISTS idx_driver_credentials_vehicle_id ON driver_credentials (vehicle_id);
CREATE INDEX IF NOT EXISTS idx_driver_credentials_company_id ON driver_credentials (company_id);

COMMENT ON TABLE driver_credentials IS 'Driver login credentials - phone and hashed password for driver app authentication';

GRANT SELECT, INSERT, UPDATE, DELETE ON driver_credentials TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON driver_credentials TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE driver_credentials_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE driver_credentials_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================

-- Table: driver_profiles
CREATE TABLE IF NOT EXISTS driver_profiles (
  id                      BIGSERIAL PRIMARY KEY,
  driver_id               BIGINT       NOT NULL,
  email                   VARCHAR(255),
  email_verified          BOOLEAN      DEFAULT FALSE,
  avatar_url              TEXT,
  bio                     TEXT,
  emergency_contact_name  VARCHAR(200),
  emergency_contact_phone VARCHAR(50),
  created_at              TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at              TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT driver_profiles_driver_id_key UNIQUE (driver_id)
);
CREATE INDEX IF NOT EXISTS idx_driver_profiles_driver_id ON driver_profiles (driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_profiles_email     ON driver_profiles (email);

COMMENT ON TABLE driver_profiles IS 'Extended driver profile data editable by the driver';

GRANT SELECT, INSERT, UPDATE, DELETE ON driver_profiles TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON driver_profiles TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE driver_profiles_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE driver_profiles_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================

-- Table: company_users
CREATE TABLE IF NOT EXISTS company_users (
  id         BIGSERIAL PRIMARY KEY,
  user_id    BIGINT     NOT NULL,
  company_id BIGINT     NOT NULL,
  role       VARCHAR(50) DEFAULT 'owner',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT company_users_user_id_company_id_key UNIQUE (user_id, company_id),
  CONSTRAINT company_users_role_check CHECK (role IN ('owner','manager'))
);
CREATE INDEX IF NOT EXISTS idx_company_users_user_id    ON company_users (user_id);
CREATE INDEX IF NOT EXISTS idx_company_users_company_id ON company_users (company_id);

COMMENT ON TABLE company_users IS 'Links manager/owner accounts to their companies';

GRANT SELECT, INSERT, UPDATE, DELETE ON company_users TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON company_users TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE company_users_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE company_users_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================

-- Table: company_contracts
CREATE TABLE IF NOT EXISTS company_contracts (
  id                           BIGSERIAL PRIMARY KEY,
  company_id                   BIGINT       NOT NULL,
  contract_number              VARCHAR(50)  NOT NULL,
  contract_type                VARCHAR(50)  DEFAULT 'annual_subscription',
  contract_start_date          DATE         NOT NULL,
  contract_end_date            DATE         NOT NULL,
  contract_duration_months     INTEGER      DEFAULT 12,
  monthly_fee                  NUMERIC(10,2) NOT NULL,
  annual_fee                   NUMERIC(10,2) NOT NULL,
  contract_status              VARCHAR(50)  DEFAULT 'pending_signature',
  contract_html_template       TEXT         NOT NULL,
  contract_pdf_url             TEXT,
  auto_renew                   BOOLEAN      DEFAULT TRUE,
  renewal_notice_days          INTEGER      DEFAULT 90,
  suspension_reason            TEXT,
  suspended_at                 TIMESTAMPTZ,
  suspended_by_user_id         BIGINT,
  created_at                   TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at                   TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  signature_token              VARCHAR(100),
  signature_link_sent_at       TIMESTAMPTZ,
  signature_link_expires_at    TIMESTAMPTZ,
  signed_at                    TIMESTAMPTZ,
  signer_ip                    VARCHAR(50),
  signer_user_agent            TEXT,
  last_invoice_generated_at    TIMESTAMPTZ,
  next_invoice_generation_date DATE,
  contract_language            VARCHAR(10)  DEFAULT 'nl',
  CONSTRAINT company_contracts_contract_number_key  UNIQUE (contract_number),
  CONSTRAINT company_contracts_signature_token_key  UNIQUE (signature_token),
  CONSTRAINT company_contracts_contract_language_check CHECK (contract_language IN ('nl','fr','en')),
  CONSTRAINT company_contracts_contract_status_check  CHECK (contract_status   IN ('pending_signature','active','suspended','expired','cancelled'))
);
CREATE INDEX IF NOT EXISTS idx_company_contracts_company_id          ON company_contracts (company_id);
CREATE INDEX IF NOT EXISTS idx_company_contracts_status              ON company_contracts (contract_status);
CREATE INDEX IF NOT EXISTS idx_company_contracts_end_date            ON company_contracts (contract_end_date);
CREATE INDEX IF NOT EXISTS idx_company_contracts_signature_token     ON company_contracts (signature_token);
CREATE INDEX IF NOT EXISTS idx_company_contracts_next_invoice_date   ON company_contracts (next_invoice_generation_date);
CREATE INDEX IF NOT EXISTS idx_company_contracts_language            ON company_contracts (contract_language);

COMMENT ON TABLE company_contracts IS 'Annual subscription contracts with e-signature support';

GRANT SELECT, INSERT, UPDATE, DELETE ON company_contracts TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON company_contracts TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE company_contracts_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE company_contracts_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================

-- Table: contract_signatures
CREATE TABLE IF NOT EXISTS contract_signatures (
  id                  BIGSERIAL PRIMARY KEY,
  contract_id         BIGINT       NOT NULL,
  company_id          BIGINT       NOT NULL,
  signer_name         VARCHAR(200) NOT NULL,
  signer_email        VARCHAR(255) NOT NULL,
  signer_position     VARCHAR(100),
  signature_data      TEXT,
  signature_ip        VARCHAR(50),
  signature_user_agent TEXT,
  signed_at           TIMESTAMPTZ  NOT NULL,
  signature_method    VARCHAR(50)  DEFAULT 'electronic',
  verification_code   VARCHAR(100),
  is_verified         BOOLEAN      DEFAULT FALSE,
  created_at          TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT contract_signatures_signature_method_check CHECK (signature_method IN ('electronic','digital_certificate','manual'))
);
CREATE INDEX IF NOT EXISTS idx_contract_signatures_contract_id ON contract_signatures (contract_id);
CREATE INDEX IF NOT EXISTS idx_contract_signatures_company_id  ON contract_signatures (company_id);
CREATE INDEX IF NOT EXISTS idx_contract_signatures_signed_at   ON contract_signatures (signed_at);

COMMENT ON TABLE contract_signatures IS 'Electronic contract signatures for companies';

GRANT SELECT, INSERT, UPDATE, DELETE ON contract_signatures TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON contract_signatures TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE contract_signatures_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE contract_signatures_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================
-- TRIPS
-- ============================================================

-- Table: trips
CREATE TABLE IF NOT EXISTS trips (
  id                       BIGSERIAL PRIMARY KEY,
  user_id                  BIGINT      NOT NULL,
  company_id               BIGINT      NOT NULL,
  driver_id                BIGINT      NOT NULL,
  vehicle_id               BIGINT      NOT NULL,
  start_time               TIMESTAMPTZ NOT NULL,
  end_time                 TIMESTAMPTZ,
  start_lat                NUMERIC(10,8),
  start_lon                NUMERIC(11,8),
  end_lat                  NUMERIC(10,8),
  end_lon                  NUMERIC(11,8),
  start_address            TEXT,
  end_address              TEXT,
  distance_km              NUMERIC(10,2),
  duration_minutes         INTEGER,
  price                    NUMERIC(10,2),
  status                   VARCHAR(20)  DEFAULT 'pending',
  chiron_trip_id           VARCHAR(100),
  chiron_sync_attempts     INTEGER      DEFAULT 0,
  last_sync_attempt        TIMESTAMPTZ,
  sync_error_message       TEXT,
  created_at               TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at               TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  estimated_distance_km    NUMERIC(10,2),
  estimated_duration_min   INTEGER,
  proposed_price           NUMERIC(10,2),
  ritnummer                VARCHAR(100),
  chiron_environment       VARCHAR(20),
  passenger_name           VARCHAR(200),
  initial_proposed_price   NUMERIC(10,2),
  driver_adjusted_price    NUMERIC(10,2),
  price_adjustment_reason  VARCHAR(200),
  is_airport_trip          BOOLEAN      DEFAULT FALSE,
  is_night_trip            BOOLEAN      DEFAULT FALSE,
  is_peak_hour_trip        BOOLEAN      DEFAULT FALSE,
  actual_distance_km       NUMERIC(10,2),
  actual_duration_minutes  INTEGER,
  payment_method           VARCHAR(50),
  start_location           geography,
  end_location             geography,
  ride_type                VARCHAR(20)  DEFAULT 'INTERNAL',
  external_source          VARCHAR(20),
  external_ride_number     VARCHAR(100),
  currency                 VARCHAR(3)   DEFAULT 'EUR',
  chiron_sync_state        VARCHAR(20)  DEFAULT 'CREATED',
  start_sync_response      JSONB,
  arrival_sync_response    JSONB,
  start_accepted_at        TIMESTAMPTZ,
  arrival_sent_at          TIMESTAMPTZ,
  start_sent_at            TIMESTAMPTZ,
  start_retry_count        INTEGER      DEFAULT 0,
  arrival_retry_count      INTEGER      DEFAULT 0,
  validation_status        VARCHAR(20)  DEFAULT 'pending',
  validation_errors        JSONB        DEFAULT '[]',
  last_validation_at       TIMESTAMPTZ,
  start_accepted           BOOLEAN      NOT NULL DEFAULT FALSE,
  start_message_id         VARCHAR(100),
  arrival_allowed          BOOLEAN      NOT NULL DEFAULT FALSE,
  last_chiron_status       VARCHAR(50),
  start_http_status        INTEGER,
  arrival_http_status      INTEGER,
  vertrek_lat              NUMERIC(10,6),
  vertrek_lon              NUMERIC(11,6),
  aankomst_lat             NUMERIC(10,6),
  aankomst_lon             NUMERIC(11,6),
  CONSTRAINT trips_ritnummer_key            UNIQUE (ritnummer),
  CONSTRAINT trips_start_time_valid_check   CHECK (validate_chiron_timestamp(start_time)),
  CONSTRAINT trips_end_time_valid_check     CHECK (end_time IS NULL OR validate_chiron_timestamp(end_time)),
  CONSTRAINT trips_start_lat_decimals_check CHECK (start_lat IS NULL OR CAST(start_lat AS TEXT) ~ E'^\\-?[0-9]+\\.[0-9]{5,}$'),
  CONSTRAINT trips_start_lon_decimals_check CHECK (start_lon IS NULL OR CAST(start_lon AS TEXT) ~ E'^\\-?[0-9]+\\.[0-9]{5,}$'),
  CONSTRAINT trips_end_lat_decimals_check   CHECK (end_lat   IS NULL OR CAST(end_lat   AS TEXT) ~ E'^\\-?[0-9]+\\.[0-9]{5,}$'),
  CONSTRAINT trips_end_lon_decimals_check   CHECK (end_lon   IS NULL OR CAST(end_lon   AS TEXT) ~ E'^\\-?[0-9]+\\.[0-9]{5,}$'),
  CONSTRAINT trips_status_check             CHECK (status         IN ('in_progress','completed','pending','success','failed','cancelled')),
  CONSTRAINT trips_chiron_environment_check CHECK (chiron_environment IS NULL OR chiron_environment IN ('test','production')),
  CONSTRAINT trips_ride_type_check          CHECK (ride_type      IN ('internal','external')),
  CONSTRAINT trips_external_source_check    CHECK (external_source IS NULL OR external_source IN ('bolt','uber','heetch')),
  CONSTRAINT trips_chiron_sync_state_check  CHECK (chiron_sync_state IN ('created','start_sent','start_accepted','arrival_sent','completed','failed'))
);
CREATE INDEX IF NOT EXISTS idx_trips_user_id                ON trips (user_id);
CREATE INDEX IF NOT EXISTS idx_trips_company_id             ON trips (company_id);
CREATE INDEX IF NOT EXISTS idx_trips_driver_id              ON trips (driver_id);
CREATE INDEX IF NOT EXISTS idx_trips_vehicle_id             ON trips (vehicle_id);
CREATE INDEX IF NOT EXISTS idx_trips_status                 ON trips (status);
CREATE INDEX IF NOT EXISTS idx_trips_start_time             ON trips (start_time);
CREATE INDEX IF NOT EXISTS idx_trips_chiron_trip_id         ON trips (chiron_trip_id);
CREATE INDEX IF NOT EXISTS idx_trips_ritnummer              ON trips (ritnummer);
CREATE INDEX IF NOT EXISTS idx_trips_is_airport_trip        ON trips (is_airport_trip);
CREATE INDEX IF NOT EXISTS idx_trips_is_night_trip          ON trips (is_night_trip);
CREATE INDEX IF NOT EXISTS idx_trips_is_peak_hour_trip      ON trips (is_peak_hour_trip);
CREATE INDEX IF NOT EXISTS idx_trips_payment_method         ON trips (payment_method);
CREATE INDEX IF NOT EXISTS idx_trips_start_location_gist    ON trips USING GIST (start_location);
CREATE INDEX IF NOT EXISTS idx_trips_end_location_gist      ON trips USING GIST (end_location);
CREATE INDEX IF NOT EXISTS idx_trips_ride_type              ON trips (ride_type);
CREATE INDEX IF NOT EXISTS idx_trips_external_source        ON trips (external_source);
CREATE INDEX IF NOT EXISTS idx_trips_external_ride_number   ON trips (external_ride_number);
CREATE INDEX IF NOT EXISTS idx_trips_chiron_sync_state      ON trips (chiron_sync_state);
CREATE INDEX IF NOT EXISTS idx_trips_validation_status      ON trips (validation_status);
CREATE INDEX IF NOT EXISTS idx_trips_start_accepted         ON trips (start_accepted);
CREATE INDEX IF NOT EXISTS idx_trips_arrival_allowed        ON trips (arrival_allowed);
CREATE INDEX IF NOT EXISTS idx_trips_sync_state_created     ON trips (chiron_sync_state, created_at);

COMMENT ON TABLE trips IS 'Taxi trips - supports internal and external (Bolt/Uber/Heetch) rides. Acts as Chiron data relay.';

GRANT SELECT, INSERT, UPDATE, DELETE ON trips TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON trips TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE trips_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE trips_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================

-- Table: trip_locations
CREATE TABLE IF NOT EXISTS trip_locations (
  id               BIGSERIAL PRIMARY KEY,
  trip_id          BIGINT        NOT NULL,
  driver_id        BIGINT        NOT NULL,
  latitude         NUMERIC(10,8) NOT NULL,
  longitude        NUMERIC(11,8) NOT NULL,
  speed_kmh        NUMERIC(5,2),
  heading          NUMERIC(5,2),
  accuracy_meters  NUMERIC(6,2),
  recorded_at      TIMESTAMPTZ   DEFAULT CURRENT_TIMESTAMP,
  created_at       TIMESTAMPTZ   DEFAULT CURRENT_TIMESTAMP,
  location         geography,
  CONSTRAINT trip_locations_latitude_decimals_check  CHECK (CAST(latitude  AS TEXT) ~ E'^\\-?[0-9]+\\.[0-9]{5,}$'),
  CONSTRAINT trip_locations_longitude_decimals_check CHECK (CAST(longitude AS TEXT) ~ E'^\\-?[0-9]+\\.[0-9]{5,}$')
);
CREATE INDEX IF NOT EXISTS idx_trip_locations_trip_id       ON trip_locations (trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_locations_driver_id     ON trip_locations (driver_id);
CREATE INDEX IF NOT EXISTS idx_trip_locations_recorded_at   ON trip_locations (recorded_at);
CREATE INDEX IF NOT EXISTS idx_trip_locations_location_gist ON trip_locations USING GIST (location);

COMMENT ON TABLE trip_locations IS 'Real-time GPS tracking during a trip for route display';

GRANT SELECT, INSERT, UPDATE, DELETE ON trip_locations TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON trip_locations TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE trip_locations_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE trip_locations_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================

-- Table: trip_state_transitions
CREATE TABLE IF NOT EXISTS trip_state_transitions (
  id                BIGSERIAL PRIMARY KEY,
  trip_id           BIGINT      NOT NULL,
  from_state        VARCHAR(20),
  to_state          VARCHAR(20) NOT NULL,
  transition_reason TEXT,
  http_status_code  INTEGER,
  chiron_response   JSONB,
  error_message     TEXT,
  transitioned_at   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT trip_state_transitions_to_state_check CHECK (to_state IN ('created','start_sent','start_accepted','arrival_sent','completed','failed'))
);
CREATE INDEX IF NOT EXISTS idx_trip_state_transitions_trip_id        ON trip_state_transitions (trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_state_transitions_to_state       ON trip_state_transitions (to_state);
CREATE INDEX IF NOT EXISTS idx_trip_state_transitions_transitioned_at ON trip_state_transitions (transitioned_at);

COMMENT ON TABLE trip_state_transitions IS 'Trip state change log - prevents CH1210 errors';

GRANT SELECT, INSERT, UPDATE, DELETE ON trip_state_transitions TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON trip_state_transitions TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE trip_state_transitions_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE trip_state_transitions_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================

-- Table: trip_summaries
CREATE TABLE IF NOT EXISTS trip_summaries (
  id                      BIGSERIAL PRIMARY KEY,
  user_id                 BIGINT       NOT NULL,
  driver_id               BIGINT       NOT NULL,
  company_id              BIGINT       NOT NULL,
  summary_period          VARCHAR(20)  NOT NULL,
  period_start_date       DATE         NOT NULL,
  period_end_date         DATE         NOT NULL,
  total_trips             INTEGER      DEFAULT 0,
  completed_trips         INTEGER      DEFAULT 0,
  cancelled_trips         INTEGER      DEFAULT 0,
  total_revenue           NUMERIC(10,2) DEFAULT 0.00,
  total_distance_km       NUMERIC(10,2) DEFAULT 0.00,
  total_duration_minutes  INTEGER      DEFAULT 0,
  cash_amount             NUMERIC(10,2) DEFAULT 0.00,
  card_amount             NUMERIC(10,2) DEFAULT 0.00,
  bank_transfer_amount    NUMERIC(10,2) DEFAULT 0.00,
  bancontact_amount       NUMERIC(10,2) DEFAULT 0.00,
  total_tax_amount        NUMERIC(10,2) DEFAULT 0.00,
  tax_rate_6_amount       NUMERIC(10,2) DEFAULT 0.00,
  tax_rate_21_amount      NUMERIC(10,2) DEFAULT 0.00,
  total_before_tax        NUMERIC(10,2) DEFAULT 0.00,
  total_after_tax         NUMERIC(10,2) DEFAULT 0.00,
  airport_trips_count     INTEGER      DEFAULT 0,
  airport_trips_amount    NUMERIC(10,2) DEFAULT 0.00,
  night_trips_count       INTEGER      DEFAULT 0,
  night_trips_amount      NUMERIC(10,2) DEFAULT 0.00,
  peak_hour_trips_count   INTEGER      DEFAULT 0,
  peak_hour_trips_amount  NUMERIC(10,2) DEFAULT 0.00,
  external_trips_count    INTEGER      DEFAULT 0,
  external_trips_amount   NUMERIC(10,2) DEFAULT 0.00,
  bolt_trips_count        INTEGER      DEFAULT 0,
  bolt_trips_amount       NUMERIC(10,2) DEFAULT 0.00,
  uber_trips_count        INTEGER      DEFAULT 0,
  uber_trips_amount       NUMERIC(10,2) DEFAULT 0.00,
  heetch_trips_count      INTEGER      DEFAULT 0,
  heetch_trips_amount     NUMERIC(10,2) DEFAULT 0.00,
  summary_notes           TEXT,
  generated_at            TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  created_at              TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at              TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT trip_summaries_summary_period_check CHECK (summary_period IN ('daily','weekly','monthly','custom'))
);
CREATE INDEX IF NOT EXISTS idx_trip_summaries_user_id       ON trip_summaries (user_id);
CREATE INDEX IF NOT EXISTS idx_trip_summaries_driver_id     ON trip_summaries (driver_id);
CREATE INDEX IF NOT EXISTS idx_trip_summaries_company_id    ON trip_summaries (company_id);
CREATE INDEX IF NOT EXISTS idx_trip_summaries_period        ON trip_summaries (summary_period);
CREATE INDEX IF NOT EXISTS idx_trip_summaries_period_dates  ON trip_summaries (period_start_date, period_end_date);
CREATE INDEX IF NOT EXISTS idx_trip_summaries_generated_at  ON trip_summaries (generated_at);

COMMENT ON TABLE trip_summaries IS 'Trip summaries with detailed tax info for accounting';

GRANT SELECT, INSERT, UPDATE, DELETE ON trip_summaries TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON trip_summaries TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE trip_summaries_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE trip_summaries_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================
-- FINANCIAL
-- ============================================================

-- Table: expenses
CREATE TABLE IF NOT EXISTS expenses (
  id           BIGSERIAL PRIMARY KEY,
  user_id      BIGINT        NOT NULL,
  company_id   BIGINT        NOT NULL,
  type         VARCHAR(100)  NOT NULL,
  amount       NUMERIC(10,2) NOT NULL,
  expense_date DATE          NOT NULL,
  description  TEXT,
  receipt_url  TEXT,
  created_at   TIMESTAMPTZ   DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMPTZ   DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_expenses_user_id      ON expenses (user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_company_id   ON expenses (company_id);
CREATE INDEX IF NOT EXISTS idx_expenses_expense_date ON expenses (expense_date);

COMMENT ON TABLE expenses IS 'Company expenses tracking';

GRANT SELECT, INSERT, UPDATE, DELETE ON expenses TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON expenses TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE expenses_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE expenses_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================

-- Table: invoices
CREATE TABLE IF NOT EXISTS invoices (
  id                         BIGSERIAL PRIMARY KEY,
  user_id                    BIGINT        NOT NULL,
  company_id                 BIGINT        NOT NULL,
  invoice_number             VARCHAR(50)   NOT NULL,
  client_name                VARCHAR(200)  NOT NULL,
  client_address             TEXT,
  client_vat                 VARCHAR(50),
  items                      JSONB         NOT NULL,
  total_htva                 NUMERIC(10,2) NOT NULL,
  vat_rate                   NUMERIC(5,2)  DEFAULT 21.00,
  total_tvac                 NUMERIC(10,2) NOT NULL,
  pdf_url                    TEXT,
  invoice_date               DATE          NOT NULL,
  due_date                   DATE,
  status                     VARCHAR(20)   DEFAULT 'draft',
  created_at                 TIMESTAMPTZ   DEFAULT CURRENT_TIMESTAMP,
  updated_at                 TIMESTAMPTZ   DEFAULT CURRENT_TIMESTAMP,
  invoice_type               VARCHAR(50)   DEFAULT 'one_time',
  recurrence_period          VARCHAR(20),
  next_invoice_date          DATE,
  parent_invoice_id          BIGINT,
  sent_at                    TIMESTAMPTZ,
  send_attempts              INTEGER       DEFAULT 0,
  send_error                 TEXT,
  client_phone               VARCHAR(50),
  client_email               VARCHAR(255),
  invoice_language           VARCHAR(10)   DEFAULT 'nl',
  payment_method             VARCHAR(50),
  payment_reference          VARCHAR(100),
  bank_account               VARCHAR(100),
  invoice_category           VARCHAR(20)   DEFAULT 'trip',
  bic_code                   VARCHAR(20),
  qr_code_url                TEXT,
  payment_status             VARCHAR(20)   DEFAULT 'pending',
  paid_at                    TIMESTAMPTZ,
  payment_confirmation_number VARCHAR(100),
  overdue_days               INTEGER       DEFAULT 0,
  reminder_sent_count        INTEGER       DEFAULT 0,
  last_reminder_sent_at      TIMESTAMPTZ,
  contract_id                BIGINT,
  is_auto_generated          BOOLEAN       DEFAULT FALSE,
  generation_month           INTEGER,
  generation_year            INTEGER,
  structured_reference       VARCHAR(20),
  issuer_company_id          BIGINT,
  client_company_id          BIGINT,
  trip_id                    BIGINT,
  trip_time                  TIMETZ,
  trip_datetime              TIMESTAMPTZ,
  CONSTRAINT invoices_invoice_number_key  UNIQUE (invoice_number),
  CONSTRAINT invoices_invoice_category_check CHECK (invoice_category IN ('trip','company')),
  CONSTRAINT invoices_recurrence_period_check CHECK (recurrence_period IS NULL OR recurrence_period IN ('monthly','quarterly','yearly')),
  CONSTRAINT invoices_status_check        CHECK (status         IN ('draft','sent','paid','cancelled','overdue')),
  CONSTRAINT invoices_payment_status_check CHECK (payment_status IN ('pending','paid','overdue','cancelled','refunded')),
  CONSTRAINT invoices_invoice_type_check  CHECK (invoice_type   IN ('one_time','subscription','recurring'))
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_invoices_structured_reference ON invoices (structured_reference) WHERE structured_reference IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_invoices_user_id           ON invoices (user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_company_id        ON invoices (company_id);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_number    ON invoices (invoice_number);
CREATE INDEX IF NOT EXISTS idx_invoices_status            ON invoices (status);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_type      ON invoices (invoice_type);
CREATE INDEX IF NOT EXISTS idx_invoices_next_invoice_date ON invoices (next_invoice_date);
CREATE INDEX IF NOT EXISTS idx_invoices_parent_invoice_id ON invoices (parent_invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoices_category          ON invoices (invoice_category);
CREATE INDEX IF NOT EXISTS idx_invoices_payment_status    ON invoices (payment_status);
CREATE INDEX IF NOT EXISTS idx_invoices_contract_id       ON invoices (contract_id);
CREATE INDEX IF NOT EXISTS idx_invoices_is_auto_generated ON invoices (is_auto_generated);
CREATE INDEX IF NOT EXISTS idx_invoices_overdue_days      ON invoices (overdue_days);
CREATE INDEX IF NOT EXISTS idx_invoices_generation_period ON invoices (generation_year, generation_month);
CREATE INDEX IF NOT EXISTS idx_invoices_issuer_company_id ON invoices (issuer_company_id);
CREATE INDEX IF NOT EXISTS idx_invoices_client_company_id ON invoices (client_company_id);
CREATE INDEX IF NOT EXISTS idx_invoices_company_status    ON invoices (company_id, status);
CREATE INDEX IF NOT EXISTS idx_invoices_trip_id           ON invoices (trip_id);
CREATE INDEX IF NOT EXISTS idx_invoices_trip_id_status    ON invoices (trip_id, status) WHERE trip_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_invoices_trip_datetime     ON invoices (trip_datetime) WHERE trip_datetime IS NOT NULL;

COMMENT ON TABLE invoices IS 'Independent invoices - issuer_company_id is your company, client_company_id is the recipient';

GRANT SELECT, INSERT, UPDATE, DELETE ON invoices TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON invoices TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE invoices_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE invoices_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================

-- Table: invoice_delivery_log
CREATE TABLE IF NOT EXISTS invoice_delivery_log (
  id               BIGSERIAL PRIMARY KEY,
  invoice_id       BIGINT      NOT NULL,
  delivery_method  VARCHAR(50) NOT NULL,
  recipient_email  VARCHAR(255),
  recipient_phone  VARCHAR(50),
  delivery_status  VARCHAR(20) DEFAULT 'pending',
  sent_at          TIMESTAMPTZ,
  delivered_at     TIMESTAMPTZ,
  error_message    TEXT,
  retry_count      INTEGER     DEFAULT 0,
  created_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT invoice_delivery_log_delivery_method_check CHECK (delivery_method IN ('email','sms','whatsapp','postal')),
  CONSTRAINT invoice_delivery_log_delivery_status_check CHECK (delivery_status  IN ('pending','sent','delivered','failed','bounced'))
);
CREATE INDEX IF NOT EXISTS idx_invoice_delivery_log_invoice_id      ON invoice_delivery_log (invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_delivery_log_delivery_status ON invoice_delivery_log (delivery_status);
CREATE INDEX IF NOT EXISTS idx_invoice_delivery_log_sent_at         ON invoice_delivery_log (sent_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON invoice_delivery_log TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON invoice_delivery_log TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE invoice_delivery_log_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE invoice_delivery_log_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: invoice_edit_history
CREATE TABLE IF NOT EXISTS invoice_edit_history (
  id                  BIGSERIAL PRIMARY KEY,
  invoice_id          BIGINT       NOT NULL,
  edited_by_user_id   BIGINT       NOT NULL,
  field_name          VARCHAR(100) NOT NULL,
  old_value           TEXT,
  new_value           TEXT,
  edit_reason         TEXT,
  edited_at           TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_invoice_edit_history_invoice_id ON invoice_edit_history (invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_edit_history_edited_by  ON invoice_edit_history (edited_by_user_id);
CREATE INDEX IF NOT EXISTS idx_invoice_edit_history_edited_at  ON invoice_edit_history (edited_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON invoice_edit_history TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON invoice_edit_history TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE invoice_edit_history_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE invoice_edit_history_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: invoice_share_links
CREATE TABLE IF NOT EXISTS invoice_share_links (
  id             BIGSERIAL PRIMARY KEY,
  invoice_id     BIGINT       NOT NULL,
  share_token    VARCHAR(100) NOT NULL,
  qr_code_url    TEXT,
  view_count     INTEGER      DEFAULT 0,
  last_viewed_at TIMESTAMPTZ,
  expires_at     TIMESTAMPTZ,
  is_active      BOOLEAN      DEFAULT TRUE,
  created_at     TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT invoice_share_links_share_token_key UNIQUE (share_token)
);
CREATE INDEX IF NOT EXISTS idx_invoice_share_links_invoice_id  ON invoice_share_links (invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_share_links_share_token ON invoice_share_links (share_token);
CREATE INDEX IF NOT EXISTS idx_invoice_share_links_is_active   ON invoice_share_links (is_active);
CREATE INDEX IF NOT EXISTS idx_invoice_share_links_expires_at  ON invoice_share_links (expires_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON invoice_share_links TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON invoice_share_links TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE invoice_share_links_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE invoice_share_links_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: invoice_view_log
CREATE TABLE IF NOT EXISTS invoice_view_log (
  id                 BIGSERIAL PRIMARY KEY,
  share_link_id      BIGINT      NOT NULL,
  invoice_id         BIGINT      NOT NULL,
  viewer_ip          VARCHAR(50),
  viewer_user_agent  TEXT,
  viewed_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_at         TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_invoice_view_log_share_link_id ON invoice_view_log (share_link_id);
CREATE INDEX IF NOT EXISTS idx_invoice_view_log_invoice_id    ON invoice_view_log (invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_view_log_viewed_at     ON invoice_view_log (viewed_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON invoice_view_log TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON invoice_view_log TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE invoice_view_log_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE invoice_view_log_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================
-- NOTIFICATIONS & MESSAGES
-- ============================================================

-- Table: notifications
CREATE TABLE IF NOT EXISTS notifications (
  id                   BIGSERIAL PRIMARY KEY,
  title                VARCHAR(200) NOT NULL,
  message              TEXT         NOT NULL,
  notification_type    VARCHAR(50)  DEFAULT 'announcement',
  priority             VARCHAR(20)  DEFAULT 'normal',
  target_audience      VARCHAR(50)  DEFAULT 'all_drivers',
  target_company_id    BIGINT,
  icon_url             TEXT,
  action_url           TEXT,
  is_active            BOOLEAN      DEFAULT TRUE,
  scheduled_at         TIMESTAMPTZ,
  expires_at           TIMESTAMPTZ,
  created_by_user_id   BIGINT       NOT NULL,
  created_at           TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at           TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  delivery_channel     VARCHAR(20)  DEFAULT 'in_app',
  metadata             JSONB        DEFAULT '{}',
  CONSTRAINT notifications_notification_type_check CHECK (notification_type  IN ('news','announcement','update','alert','promotion')),
  CONSTRAINT notifications_priority_check          CHECK (priority           IN ('low','normal','high','urgent')),
  CONSTRAINT notifications_target_audience_check   CHECK (target_audience    IN ('all_drivers','specific_company','active_drivers')),
  CONSTRAINT notifications_delivery_channel_check  CHECK (delivery_channel   IN ('in_app','push','sms','all'))
);
CREATE INDEX IF NOT EXISTS idx_notifications_type             ON notifications (notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_priority         ON notifications (priority);
CREATE INDEX IF NOT EXISTS idx_notifications_target_audience  ON notifications (target_audience);
CREATE INDEX IF NOT EXISTS idx_notifications_target_company_id ON notifications (target_company_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_active        ON notifications (is_active);
CREATE INDEX IF NOT EXISTS idx_notifications_scheduled_at     ON notifications (scheduled_at);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at       ON notifications (created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_delivery_channel ON notifications (delivery_channel);
CREATE INDEX IF NOT EXISTS idx_notifications_metadata         ON notifications USING GIN (metadata);

GRANT SELECT, INSERT, UPDATE, DELETE ON notifications TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON notifications TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE notifications_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE notifications_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: user_notifications
CREATE TABLE IF NOT EXISTS user_notifications (
  id                    BIGSERIAL PRIMARY KEY,
  user_id               BIGINT      NOT NULL,
  notification_id       BIGINT      NOT NULL,
  is_read               BOOLEAN     DEFAULT FALSE,
  read_at               TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  dismissed_at          TIMESTAMPTZ,
  notification_channel  VARCHAR(20) DEFAULT 'in_app',
  CONSTRAINT user_notifications_user_id_notification_id_key UNIQUE (user_id, notification_id)
);
CREATE INDEX IF NOT EXISTS idx_user_notifications_user_id         ON user_notifications (user_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_notification_id ON user_notifications (notification_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_is_read         ON user_notifications (is_read);
CREATE INDEX IF NOT EXISTS idx_user_notifications_user_read       ON user_notifications (user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_user_notifications_dismissed       ON user_notifications (user_id, dismissed_at) WHERE dismissed_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_user_notifications_unread_active   ON user_notifications (user_id, is_read, created_at DESC) WHERE is_read = FALSE;

GRANT SELECT, INSERT, UPDATE, DELETE ON user_notifications TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_notifications TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE user_notifications_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE user_notifications_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: internal_messages
CREATE TABLE IF NOT EXISTS internal_messages (
  id                   BIGSERIAL PRIMARY KEY,
  sender_user_id       BIGINT       NOT NULL,
  sender_type          VARCHAR(20)  NOT NULL,
  subject              VARCHAR(200) NOT NULL,
  message_body         TEXT         NOT NULL,
  message_priority     VARCHAR(20)  DEFAULT 'normal',
  recipient_type       VARCHAR(20)  NOT NULL,
  target_company_id    BIGINT,
  is_broadcast         BOOLEAN      DEFAULT FALSE,
  parent_message_id    BIGINT,
  created_at           TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at           TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  sender_name          VARCHAR(200),
  status               VARCHAR(20)  DEFAULT 'open',
  last_activity_at     TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  is_locked            BOOLEAN      DEFAULT FALSE,
  resolved_at          TIMESTAMPTZ,
  resolved_by_user_id  BIGINT,
  CONSTRAINT internal_messages_sender_type_check     CHECK (sender_type     IN ('admin','driver','manager','distributor')),
  CONSTRAINT internal_messages_message_priority_check CHECK (message_priority IN ('low','normal','high','urgent')),
  CONSTRAINT internal_messages_recipient_type_check  CHECK (recipient_type  IN ('individual','company','all_drivers','all_active_drivers')),
  CONSTRAINT internal_messages_status_check          CHECK (status          IN ('open','resolved'))
);
CREATE INDEX IF NOT EXISTS idx_internal_messages_sender          ON internal_messages (sender_user_id);
CREATE INDEX IF NOT EXISTS idx_internal_messages_sender_type     ON internal_messages (sender_type);
CREATE INDEX IF NOT EXISTS idx_internal_messages_priority        ON internal_messages (message_priority);
CREATE INDEX IF NOT EXISTS idx_internal_messages_recipient_type  ON internal_messages (recipient_type);
CREATE INDEX IF NOT EXISTS idx_internal_messages_target_company  ON internal_messages (target_company_id);
CREATE INDEX IF NOT EXISTS idx_internal_messages_parent          ON internal_messages (parent_message_id);
CREATE INDEX IF NOT EXISTS idx_internal_messages_created_at      ON internal_messages (created_at);
CREATE INDEX IF NOT EXISTS idx_internal_messages_status          ON internal_messages (status);
CREATE INDEX IF NOT EXISTS idx_internal_messages_last_activity   ON internal_messages (last_activity_at);
CREATE INDEX IF NOT EXISTS idx_internal_messages_is_locked       ON internal_messages (is_locked);

GRANT SELECT, INSERT, UPDATE, DELETE ON internal_messages TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON internal_messages TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE internal_messages_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE internal_messages_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: message_recipients
CREATE TABLE IF NOT EXISTS message_recipients (
  id                  BIGSERIAL PRIMARY KEY,
  message_id          BIGINT      NOT NULL,
  recipient_user_id   BIGINT      NOT NULL,
  recipient_driver_id BIGINT,
  is_read             BOOLEAN     DEFAULT FALSE,
  read_at             TIMESTAMPTZ,
  is_archived         BOOLEAN     DEFAULT FALSE,
  archived_at         TIMESTAMPTZ,
  is_deleted          BOOLEAN     DEFAULT FALSE,
  deleted_at          TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT message_recipients_message_id_recipient_user_id_key UNIQUE (message_id, recipient_user_id)
);
CREATE INDEX IF NOT EXISTS idx_message_recipients_message_id       ON message_recipients (message_id);
CREATE INDEX IF NOT EXISTS idx_message_recipients_recipient_user   ON message_recipients (recipient_user_id);
CREATE INDEX IF NOT EXISTS idx_message_recipients_recipient_driver ON message_recipients (recipient_driver_id);
CREATE INDEX IF NOT EXISTS idx_message_recipients_is_read          ON message_recipients (is_read);
CREATE INDEX IF NOT EXISTS idx_message_recipients_unread           ON message_recipients (recipient_user_id, is_read) WHERE is_read = FALSE;

GRANT SELECT, INSERT, UPDATE, DELETE ON message_recipients TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON message_recipients TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE message_recipients_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE message_recipients_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: message_replies
CREATE TABLE IF NOT EXISTS message_replies (
  id                BIGSERIAL PRIMARY KEY,
  parent_message_id BIGINT NOT NULL,
  reply_message_id  BIGINT NOT NULL,
  sender_user_id    BIGINT NOT NULL,
  reply_body        TEXT   NOT NULL,
  created_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT message_replies_parent_message_id_reply_message_id_key UNIQUE (parent_message_id, reply_message_id)
);
CREATE INDEX IF NOT EXISTS idx_message_replies_parent ON message_replies (parent_message_id);
CREATE INDEX IF NOT EXISTS idx_message_replies_reply  ON message_replies (reply_message_id);
CREATE INDEX IF NOT EXISTS idx_message_replies_sender ON message_replies (sender_user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON message_replies TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON message_replies TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE message_replies_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE message_replies_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: message_attachments
CREATE TABLE IF NOT EXISTS message_attachments (
  id                  BIGSERIAL PRIMARY KEY,
  message_id          BIGINT       NOT NULL,
  file_name           VARCHAR(255) NOT NULL,
  file_url            TEXT         NOT NULL,
  file_type           VARCHAR(100),
  file_size_bytes     BIGINT,
  uploaded_by_user_id BIGINT       NOT NULL,
  created_at          TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_message_attachments_message_id   ON message_attachments (message_id);
CREATE INDEX IF NOT EXISTS idx_message_attachments_uploaded_by  ON message_attachments (uploaded_by_user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON message_attachments TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON message_attachments TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE message_attachments_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE message_attachments_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: message_statistics
CREATE TABLE IF NOT EXISTS message_statistics (
  id                       BIGSERIAL PRIMARY KEY,
  user_id                  BIGINT     NOT NULL,
  total_sent               BIGINT     DEFAULT 0,
  total_received           BIGINT     DEFAULT 0,
  total_read               BIGINT     DEFAULT 0,
  total_unread             BIGINT     DEFAULT 0,
  total_archived           BIGINT     DEFAULT 0,
  last_message_sent_at     TIMESTAMPTZ,
  last_message_received_at TIMESTAMPTZ,
  created_at               TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at               TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT message_statistics_user_id_key UNIQUE (user_id)
);
CREATE INDEX IF NOT EXISTS idx_message_statistics_user_id ON message_statistics (user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON message_statistics TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON message_statistics TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE message_statistics_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE message_statistics_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================
-- AUTH & SESSIONS
-- ============================================================

-- Table: sessions
CREATE TABLE IF NOT EXISTS sessions (
  id         BIGSERIAL PRIMARY KEY,
  user_id    BIGINT       NOT NULL,
  ip         VARCHAR(255) NOT NULL,
  user_agent VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  refresh_at TIMESTAMPTZ
);

GRANT SELECT, INSERT, UPDATE, DELETE ON sessions TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE sessions_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;

-- Table: refresh_tokens
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id         BIGSERIAL PRIMARY KEY,
  user_id    BIGINT      NOT NULL,
  token      TEXT        NOT NULL,
  session_id BIGINT      NOT NULL,
  revoked    BOOLEAN     NOT NULL DEFAULT FALSE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

GRANT SELECT, INSERT, UPDATE, DELETE ON refresh_tokens TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE refresh_tokens_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;

-- Table: user_passcode
CREATE TABLE IF NOT EXISTS user_passcode (
  id           BIGSERIAL PRIMARY KEY,
  passcode     VARCHAR(255) NOT NULL,
  passcode_type VARCHAR(255) NOT NULL DEFAULT 'EMAIL',
  pass_object  VARCHAR(255) NOT NULL,
  valid_until  TIMESTAMPTZ  NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '3 minutes'),
  retry_count  INTEGER      NOT NULL DEFAULT 0,
  revoked      BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_pass_object ON user_passcode (pass_object);

GRANT SELECT, INSERT, UPDATE, DELETE ON user_passcode TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE user_passcode_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;

-- Table: user_oauth_providers
CREATE TABLE IF NOT EXISTS user_oauth_providers (
  id                  BIGSERIAL PRIMARY KEY,
  user_id             BIGINT       NOT NULL,
  provider            VARCHAR(20)  NOT NULL,
  provider_user_id    VARCHAR(255) NOT NULL,
  provider_email      VARCHAR(255),
  provider_name       VARCHAR(255),
  provider_avatar_url TEXT,
  access_token        TEXT,
  refresh_token       TEXT,
  token_expires_at    TIMESTAMPTZ,
  raw_profile         JSONB,
  is_active           BOOLEAN      DEFAULT TRUE,
  created_at          TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT user_oauth_providers_provider_provider_user_id_key UNIQUE (provider, provider_user_id),
  CONSTRAINT user_oauth_providers_provider_check CHECK (provider IN ('google','facebook','apple'))
);
CREATE INDEX IF NOT EXISTS idx_oauth_providers_user_id          ON user_oauth_providers (user_id);
CREATE INDEX IF NOT EXISTS idx_oauth_providers_provider         ON user_oauth_providers (provider);
CREATE INDEX IF NOT EXISTS idx_oauth_providers_provider_user_id ON user_oauth_providers (provider, provider_user_id);
CREATE INDEX IF NOT EXISTS idx_oauth_providers_provider_email   ON user_oauth_providers (provider_email) WHERE provider_email IS NOT NULL;

GRANT SELECT, INSERT, UPDATE, DELETE ON user_oauth_providers TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_oauth_providers TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE user_oauth_providers_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE user_oauth_providers_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================
-- DISTRIBUTORS & APPROVAL
-- ============================================================

-- Table: distributor_companies
CREATE TABLE IF NOT EXISTS distributor_companies (
  id                   BIGSERIAL PRIMARY KEY,
  distributor_id       BIGINT      NOT NULL,
  company_id           BIGINT      NOT NULL,
  assigned_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  assigned_by_user_id  BIGINT      NOT NULL,
  is_active            BOOLEAN     DEFAULT TRUE,
  notes                TEXT,
  created_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT distributor_companies_distributor_id_company_id_key UNIQUE (distributor_id, company_id)
);
CREATE INDEX IF NOT EXISTS idx_distributor_companies_distributor_id ON distributor_companies (distributor_id);
CREATE INDEX IF NOT EXISTS idx_distributor_companies_company_id     ON distributor_companies (company_id);
CREATE INDEX IF NOT EXISTS idx_distributor_companies_is_active      ON distributor_companies (is_active);

GRANT SELECT, INSERT, UPDATE, DELETE ON distributor_companies TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON distributor_companies TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE distributor_companies_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE distributor_companies_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: distributor_permissions
CREATE TABLE IF NOT EXISTS distributor_permissions (
  id                  BIGSERIAL PRIMARY KEY,
  distributor_id      BIGINT      NOT NULL,
  permission_type     VARCHAR(50) NOT NULL,
  is_granted          BOOLEAN     DEFAULT TRUE,
  granted_by_user_id  BIGINT      NOT NULL,
  granted_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  notes               TEXT,
  CONSTRAINT distributor_permissions_distributor_id_permission_type_key UNIQUE (distributor_id, permission_type),
  CONSTRAINT distributor_permissions_permission_type_check CHECK (permission_type IN ('add_company','add_vehicle','add_driver','view_invoices','view_expenses','view_reports','manage_contracts','view_analytics'))
);
CREATE INDEX IF NOT EXISTS idx_distributor_permissions_distributor_id  ON distributor_permissions (distributor_id);
CREATE INDEX IF NOT EXISTS idx_distributor_permissions_permission_type ON distributor_permissions (permission_type);
CREATE INDEX IF NOT EXISTS idx_distributor_permissions_is_granted      ON distributor_permissions (is_granted);

GRANT SELECT, INSERT, UPDATE, DELETE ON distributor_permissions TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON distributor_permissions TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE distributor_permissions_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE distributor_permissions_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: distributor_sessions
CREATE TABLE IF NOT EXISTS distributor_sessions (
  id               BIGSERIAL PRIMARY KEY,
  distributor_id   BIGINT      NOT NULL,
  token            TEXT        NOT NULL,
  ip_address       VARCHAR(50),
  user_agent       TEXT,
  expires_at       TIMESTAMPTZ NOT NULL,
  is_active        BOOLEAN     DEFAULT TRUE,
  last_activity_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT distributor_sessions_token_key UNIQUE (token)
);
CREATE INDEX IF NOT EXISTS idx_distributor_sessions_distributor_id ON distributor_sessions (distributor_id);
CREATE INDEX IF NOT EXISTS idx_distributor_sessions_token          ON distributor_sessions (token);
CREATE INDEX IF NOT EXISTS idx_distributor_sessions_is_active      ON distributor_sessions (is_active);
CREATE INDEX IF NOT EXISTS idx_distributor_sessions_expires_at     ON distributor_sessions (expires_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON distributor_sessions TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON distributor_sessions TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE distributor_sessions_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE distributor_sessions_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: distributor_activity_log
CREATE TABLE IF NOT EXISTS distributor_activity_log (
  id                 BIGSERIAL PRIMARY KEY,
  distributor_id     BIGINT      NOT NULL,
  activity_type      VARCHAR(50) NOT NULL,
  entity_type        VARCHAR(50),
  entity_id          BIGINT,
  activity_details   JSONB,
  ip_address         VARCHAR(50),
  user_agent         TEXT,
  created_at         TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT distributor_activity_log_activity_type_check CHECK (activity_type IN ('login','logout','create_company','create_driver','create_vehicle','request_update','request_delete','view_invoice','view_report'))
);
CREATE INDEX IF NOT EXISTS idx_distributor_activity_log_distributor_id ON distributor_activity_log (distributor_id);
CREATE INDEX IF NOT EXISTS idx_distributor_activity_log_activity_type  ON distributor_activity_log (activity_type);
CREATE INDEX IF NOT EXISTS idx_distributor_activity_log_created_at     ON distributor_activity_log (created_at);
CREATE INDEX IF NOT EXISTS idx_distributor_activity_log_entity         ON distributor_activity_log (entity_type, entity_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON distributor_activity_log TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON distributor_activity_log TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE distributor_activity_log_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE distributor_activity_log_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================
-- APPROVAL SYSTEM
-- ============================================================

-- Table: approval_requests
CREATE TABLE IF NOT EXISTS approval_requests (
  id                    BIGSERIAL PRIMARY KEY,
  request_type          VARCHAR(50) NOT NULL,
  entity_type           VARCHAR(50) NOT NULL,
  entity_id             BIGINT      NOT NULL,
  requested_by_user_id  BIGINT      NOT NULL,
  distributor_id        BIGINT,
  request_data          JSONB       NOT NULL,
  current_data          JSONB,
  request_reason        TEXT,
  status                VARCHAR(20) DEFAULT 'pending',
  reviewed_by_user_id   BIGINT,
  reviewed_at           TIMESTAMPTZ,
  review_notes          TEXT,
  created_at            TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at            TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  entity_name           VARCHAR(200),
  priority              VARCHAR(20) DEFAULT 'normal',
  auto_approve_eligible BOOLEAN     DEFAULT FALSE,
  CONSTRAINT approval_requests_request_type_check CHECK (request_type IN ('register','update','delete')),
  CONSTRAINT approval_requests_entity_type_check  CHECK (entity_type  IN ('company','vehicle','driver','invoice','expense','driver_registration')),
  CONSTRAINT approval_requests_status_check       CHECK (status       IN ('pending','approved','rejected','cancelled')),
  CONSTRAINT approval_requests_priority_check     CHECK (priority     IN ('low','normal','high','urgent'))
);
CREATE INDEX IF NOT EXISTS idx_approval_requests_request_type      ON approval_requests (request_type);
CREATE INDEX IF NOT EXISTS idx_approval_requests_entity_type       ON approval_requests (entity_type);
CREATE INDEX IF NOT EXISTS idx_approval_requests_entity_id         ON approval_requests (entity_id);
CREATE INDEX IF NOT EXISTS idx_approval_requests_requested_by      ON approval_requests (requested_by_user_id);
CREATE INDEX IF NOT EXISTS idx_approval_requests_distributor_id    ON approval_requests (distributor_id);
CREATE INDEX IF NOT EXISTS idx_approval_requests_status            ON approval_requests (status);
CREATE INDEX IF NOT EXISTS idx_approval_requests_created_at        ON approval_requests (created_at);
CREATE INDEX IF NOT EXISTS idx_approval_requests_distributor_status ON approval_requests (distributor_id, status);
CREATE INDEX IF NOT EXISTS idx_approval_requests_priority          ON approval_requests (priority);
CREATE INDEX IF NOT EXISTS idx_approval_requests_entity_name       ON approval_requests (entity_name);
CREATE INDEX IF NOT EXISTS idx_approval_requests_pending_high_priority ON approval_requests (status, priority) WHERE status = 'pending' AND priority IN ('high','urgent');

GRANT SELECT, INSERT, UPDATE, DELETE ON approval_requests TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON approval_requests TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE approval_requests_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE approval_requests_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: approval_auto_rules
CREATE TABLE IF NOT EXISTS approval_auto_rules (
  id                  BIGSERIAL PRIMARY KEY,
  rule_name           VARCHAR(100) NOT NULL,
  entity_type         VARCHAR(50)  NOT NULL,
  request_type        VARCHAR(50)  NOT NULL,
  conditions          JSONB        NOT NULL,
  is_active           BOOLEAN      DEFAULT TRUE,
  created_by_user_id  BIGINT       NOT NULL,
  created_at          TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT approval_auto_rules_entity_type_check  CHECK (entity_type  IN ('company','vehicle','driver','invoice','expense')),
  CONSTRAINT approval_auto_rules_request_type_check CHECK (request_type IN ('update','delete'))
);
CREATE INDEX IF NOT EXISTS idx_approval_auto_rules_entity_type ON approval_auto_rules (entity_type);
CREATE INDEX IF NOT EXISTS idx_approval_auto_rules_is_active   ON approval_auto_rules (is_active);

GRANT SELECT, INSERT, UPDATE, DELETE ON approval_auto_rules TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON approval_auto_rules TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE approval_auto_rules_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE approval_auto_rules_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: approval_execution_log
CREATE TABLE IF NOT EXISTS approval_execution_log (
  id                   BIGSERIAL PRIMARY KEY,
  approval_request_id  BIGINT      NOT NULL,
  executed_by_user_id  BIGINT      NOT NULL,
  execution_type       VARCHAR(50) NOT NULL,
  entity_type          VARCHAR(50) NOT NULL,
  entity_id            BIGINT      NOT NULL,
  previous_data        JSONB,
  new_data             JSONB,
  execution_status     VARCHAR(20) DEFAULT 'success',
  error_message        TEXT,
  executed_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT approval_execution_log_execution_type_check   CHECK (execution_type   IN ('update','delete','restore')),
  CONSTRAINT approval_execution_log_entity_type_check      CHECK (entity_type      IN ('company','vehicle','driver','invoice','expense')),
  CONSTRAINT approval_execution_log_execution_status_check CHECK (execution_status IN ('success','failed','rolled_back'))
);
CREATE INDEX IF NOT EXISTS idx_approval_execution_log_request_id  ON approval_execution_log (approval_request_id);
CREATE INDEX IF NOT EXISTS idx_approval_execution_log_entity       ON approval_execution_log (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_approval_execution_log_executed_by  ON approval_execution_log (executed_by_user_id);
CREATE INDEX IF NOT EXISTS idx_approval_execution_log_executed_at  ON approval_execution_log (executed_at);
CREATE INDEX IF NOT EXISTS idx_approval_execution_log_status       ON approval_execution_log (execution_status);

GRANT SELECT, INSERT, UPDATE, DELETE ON approval_execution_log TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON approval_execution_log TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE approval_execution_log_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE approval_execution_log_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: approval_history
CREATE TABLE IF NOT EXISTS approval_history (
  id                   BIGSERIAL PRIMARY KEY,
  approval_request_id  BIGINT      NOT NULL,
  action               VARCHAR(50) NOT NULL,
  performed_by_user_id BIGINT      NOT NULL,
  action_notes         TEXT,
  action_data          JSONB,
  created_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT approval_history_action_check CHECK (action IN ('submitted','approved','rejected','cancelled','executed'))
);
CREATE INDEX IF NOT EXISTS idx_approval_history_request_id    ON approval_history (approval_request_id);
CREATE INDEX IF NOT EXISTS idx_approval_history_action        ON approval_history (action);
CREATE INDEX IF NOT EXISTS idx_approval_history_performed_by  ON approval_history (performed_by_user_id);
CREATE INDEX IF NOT EXISTS idx_approval_history_created_at    ON approval_history (created_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON approval_history TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON approval_history TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE approval_history_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE approval_history_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: approval_statistics
CREATE TABLE IF NOT EXISTS approval_statistics (
  id                          BIGSERIAL PRIMARY KEY,
  distributor_id              BIGINT,
  period_start                DATE         NOT NULL,
  period_end                  DATE         NOT NULL,
  total_requests              INTEGER      DEFAULT 0,
  approved_requests           INTEGER      DEFAULT 0,
  rejected_requests           INTEGER      DEFAULT 0,
  pending_requests            INTEGER      DEFAULT 0,
  cancelled_requests          INTEGER      DEFAULT 0,
  average_approval_time_hours NUMERIC(10,2),
  created_at                  TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at                  TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_approval_statistics_distributor_id ON approval_statistics (distributor_id);
CREATE INDEX IF NOT EXISTS idx_approval_statistics_period         ON approval_statistics (period_start, period_end);

GRANT SELECT, INSERT, UPDATE, DELETE ON approval_statistics TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON approval_statistics TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE approval_statistics_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE approval_statistics_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================
-- DRIVER REGISTRATION
-- ============================================================

-- Table: driver_registration_requests
CREATE TABLE IF NOT EXISTS driver_registration_requests (
  id                          BIGSERIAL PRIMARY KEY,
  approval_request_id         BIGINT,
  driver_id                   BIGINT,
  company_id                  BIGINT       NOT NULL,
  full_name                   VARCHAR(200) NOT NULL,
  phone                       VARCHAR(50)  NOT NULL,
  email                       VARCHAR(255),
  company_address             TEXT,
  vehicle_brand               VARCHAR(100) NOT NULL,
  vehicle_model               VARCHAR(100) NOT NULL,
  vehicle_vin                 VARCHAR(100),
  vehicle_plate_number        VARCHAR(50)  NOT NULL,
  vehicle_id                  BIGINT,
  tva_number                  VARCHAR(50),
  driver_license_number       VARCHAR(100) NOT NULL,
  bestuurderspas_number       VARCHAR(100),
  driver_license_doc_url      TEXT,
  bestuurderspas_doc_url      TEXT,
  vehicle_registration_doc_url TEXT,
  additional_docs             JSONB        DEFAULT '[]',
  payment_status              VARCHAR(20)  DEFAULT 'pending',
  payment_reference           VARCHAR(200),
  payment_amount              NUMERIC(10,2),
  payment_date                TIMESTAMPTZ,
  status                      VARCHAR(20)  DEFAULT 'pending',
  rejection_reason            TEXT,
  reviewed_by_user_id         BIGINT,
  reviewed_at                 TIMESTAMPTZ,
  review_notes                TEXT,
  preferred_language          VARCHAR(10)  DEFAULT 'fr',
  submitted_at                TIMESTAMPTZ,
  created_at                  TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at                  TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT driver_registration_requests_status_check           CHECK (status           IN ('draft','pending','under_review','approved','rejected','cancelled')),
  CONSTRAINT driver_registration_requests_payment_status_check   CHECK (payment_status   IN ('pending','paid','failed','refunded')),
  CONSTRAINT driver_registration_requests_preferred_language_check CHECK (preferred_language IN ('ar','en','fr','nl'))
);
CREATE INDEX IF NOT EXISTS idx_drr_company_id           ON driver_registration_requests (company_id);
CREATE INDEX IF NOT EXISTS idx_drr_status               ON driver_registration_requests (status);
CREATE INDEX IF NOT EXISTS idx_drr_payment_status       ON driver_registration_requests (payment_status);
CREATE INDEX IF NOT EXISTS idx_drr_driver_id            ON driver_registration_requests (driver_id);
CREATE INDEX IF NOT EXISTS idx_drr_approval_request_id  ON driver_registration_requests (approval_request_id);
CREATE INDEX IF NOT EXISTS idx_drr_submitted_at         ON driver_registration_requests (submitted_at);
CREATE INDEX IF NOT EXISTS idx_drr_vehicle_plate        ON driver_registration_requests (vehicle_plate_number);
CREATE INDEX IF NOT EXISTS idx_drr_pending              ON driver_registration_requests (status, payment_status) WHERE status IN ('pending','under_review');

GRANT SELECT, INSERT, UPDATE, DELETE ON driver_registration_requests TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON driver_registration_requests TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE driver_registration_requests_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE driver_registration_requests_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: driver_registration_steps
CREATE TABLE IF NOT EXISTS driver_registration_steps (
  id                      BIGSERIAL PRIMARY KEY,
  registration_request_id BIGINT       NOT NULL,
  step_number             INTEGER      NOT NULL,
  step_name               VARCHAR(100) NOT NULL,
  step_status             VARCHAR(20)  DEFAULT 'pending',
  step_data               JSONB        DEFAULT '{}',
  completed_at            TIMESTAMPTZ,
  created_at              TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at              TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT driver_registration_steps_registration_request_id_step_numb_key UNIQUE (registration_request_id, step_number),
  CONSTRAINT driver_registration_steps_step_status_check CHECK (step_status IN ('pending','in_progress','completed','skipped'))
);
CREATE INDEX IF NOT EXISTS idx_drs_registration_request_id ON driver_registration_steps (registration_request_id);
CREATE INDEX IF NOT EXISTS idx_drs_step_status             ON driver_registration_steps (step_status);

GRANT SELECT, INSERT, UPDATE, DELETE ON driver_registration_steps TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON driver_registration_steps TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE driver_registration_steps_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE driver_registration_steps_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: driver_verification_codes
CREATE TABLE IF NOT EXISTS driver_verification_codes (
  id           BIGSERIAL PRIMARY KEY,
  driver_id    BIGINT      NOT NULL,
  code         VARCHAR(10) NOT NULL,
  code_type    VARCHAR(50) NOT NULL DEFAULT 'EMAIL_CHANGE',
  target_value VARCHAR(255),
  is_used      BOOLEAN     DEFAULT FALSE,
  expires_at   TIMESTAMPTZ NOT NULL,
  created_at   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_driver_verification_codes_driver_id  ON driver_verification_codes (driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_verification_codes_code       ON driver_verification_codes (code);
CREATE INDEX IF NOT EXISTS idx_driver_verification_codes_expires_at ON driver_verification_codes (expires_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON driver_verification_codes TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON driver_verification_codes TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE driver_verification_codes_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE driver_verification_codes_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================
-- PLATFORM CONTRACTS
-- ============================================================

-- Table: platform_contracts
CREATE TABLE IF NOT EXISTS platform_contracts (
  id                  BIGSERIAL PRIMARY KEY,
  company_id          BIGINT       NOT NULL,
  platform_name       VARCHAR(20)  NOT NULL,
  contract_number     VARCHAR(100) NOT NULL,
  contractor_name     VARCHAR(200) NOT NULL,
  contract_start_date DATE,
  contract_end_date   DATE,
  is_active           BOOLEAN      DEFAULT TRUE,
  notes               TEXT,
  created_at          TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT platform_contracts_company_id_platform_name_key UNIQUE (company_id, platform_name),
  CONSTRAINT platform_contracts_platform_name_check CHECK (LOWER(platform_name) IN ('uber','bolt','heetch'))
);
CREATE INDEX IF NOT EXISTS idx_platform_contracts_company_id    ON platform_contracts (company_id);
CREATE INDEX IF NOT EXISTS idx_platform_contracts_platform_name ON platform_contracts (platform_name);
CREATE INDEX IF NOT EXISTS idx_platform_contracts_is_active     ON platform_contracts (is_active);

GRANT SELECT, INSERT, UPDATE, DELETE ON platform_contracts TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON platform_contracts TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE platform_contracts_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE platform_contracts_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================
-- CHIRON INTEGRATION
-- ============================================================

-- Table: chiron_tokens
CREATE TABLE IF NOT EXISTS chiron_tokens (
  id           BIGSERIAL PRIMARY KEY,
  company_id   BIGINT      NOT NULL,
  environment  VARCHAR(20) NOT NULL,
  access_token TEXT        NOT NULL,
  token_type   VARCHAR(50) DEFAULT 'Bearer',
  expires_at   TIMESTAMPTZ NOT NULL,
  scope        TEXT,
  created_at   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chiron_tokens_environment_check CHECK (environment IN ('test','production'))
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_chiron_tokens_company_env ON chiron_tokens (company_id, environment);
CREATE INDEX IF NOT EXISTS idx_chiron_tokens_company_id        ON chiron_tokens (company_id);
CREATE INDEX IF NOT EXISTS idx_chiron_tokens_environment       ON chiron_tokens (environment);
CREATE INDEX IF NOT EXISTS idx_chiron_tokens_expires_at        ON chiron_tokens (expires_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_tokens TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_tokens TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_tokens_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_tokens_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: chiron_api_config
CREATE TABLE IF NOT EXISTS chiron_api_config (
  id           BIGSERIAL PRIMARY KEY,
  environment  VARCHAR(20)  NOT NULL,
  config_key   VARCHAR(100) NOT NULL,
  config_value TEXT         NOT NULL,
  config_type  VARCHAR(50)  NOT NULL,
  description  TEXT,
  is_active    BOOLEAN      DEFAULT TRUE,
  created_at   TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chiron_api_config_environment_config_key_key UNIQUE (environment, config_key),
  CONSTRAINT chiron_api_config_environment_check  CHECK (environment  IN ('test','production')),
  CONSTRAINT chiron_api_config_config_type_check  CHECK (config_type  IN ('url','timeout','retry','validation','format'))
);
CREATE INDEX IF NOT EXISTS idx_chiron_api_config_environment ON chiron_api_config (environment);
CREATE INDEX IF NOT EXISTS idx_chiron_api_config_config_key  ON chiron_api_config (config_key);
CREATE INDEX IF NOT EXISTS idx_chiron_api_config_is_active   ON chiron_api_config (is_active);

GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_api_config TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_api_config TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_api_config_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_api_config_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: chiron_error_codes
CREATE TABLE IF NOT EXISTS chiron_error_codes (
  id                     BIGSERIAL PRIMARY KEY,
  error_code             VARCHAR(20) NOT NULL,
  error_category         VARCHAR(50) NOT NULL,
  error_description_nl   TEXT        NOT NULL,
  error_description_ar   TEXT        NOT NULL,
  solution_steps         TEXT        NOT NULL,
  prevention_tips        TEXT,
  is_critical            BOOLEAN     DEFAULT FALSE,
  created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chiron_error_codes_error_code_key UNIQUE (error_code),
  CONSTRAINT chiron_error_codes_category_check CHECK (error_category IN ('validation','authentication','business_logic','technical','data_format'))
);
CREATE INDEX IF NOT EXISTS idx_chiron_error_codes_error_code  ON chiron_error_codes (error_code);
CREATE INDEX IF NOT EXISTS idx_chiron_error_codes_category    ON chiron_error_codes (error_category);
CREATE INDEX IF NOT EXISTS idx_chiron_error_codes_is_critical ON chiron_error_codes (is_critical);

GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_error_codes TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_error_codes TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_error_codes_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_error_codes_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: chiron_message_log
CREATE TABLE IF NOT EXISTS chiron_message_log (
  id                BIGSERIAL PRIMARY KEY,
  trip_id           BIGINT,
  test_trip_id      BIGINT,
  ritnummer         VARCHAR(100) NOT NULL,
  message_type      VARCHAR(20)  NOT NULL,
  message_status    VARCHAR(50)  NOT NULL,
  http_status_code  INTEGER,
  request_payload   JSONB,
  response_payload  JSONB,
  error_code        VARCHAR(20),
  error_message     TEXT,
  sent_at           TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  created_at        TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chiron_message_log_message_type_check CHECK (message_type IN ('vertrek','aankomst'))
);
CREATE INDEX IF NOT EXISTS idx_chiron_message_log_trip_id      ON chiron_message_log (trip_id);
CREATE INDEX IF NOT EXISTS idx_chiron_message_log_test_trip_id ON chiron_message_log (test_trip_id);
CREATE INDEX IF NOT EXISTS idx_chiron_message_log_ritnummer    ON chiron_message_log (ritnummer);
CREATE INDEX IF NOT EXISTS idx_chiron_message_log_message_type ON chiron_message_log (message_type);
CREATE INDEX IF NOT EXISTS idx_chiron_message_log_error_code   ON chiron_message_log (error_code);
CREATE INDEX IF NOT EXISTS idx_chiron_message_log_sent_at      ON chiron_message_log (sent_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_message_log TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_message_log TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_message_log_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_message_log_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: chiron_oauth_log
CREATE TABLE IF NOT EXISTS chiron_oauth_log (
  id               BIGSERIAL PRIMARY KEY,
  company_id       BIGINT      NOT NULL,
  environment      VARCHAR(20) NOT NULL,
  request_type     VARCHAR(50) NOT NULL,
  http_status_code INTEGER,
  success          BOOLEAN     DEFAULT FALSE,
  error_message    TEXT,
  response_data    JSONB,
  created_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chiron_oauth_log_environment_check  CHECK (environment  IN ('test','production')),
  CONSTRAINT chiron_oauth_log_request_type_check CHECK (request_type IN ('token_request','token_refresh'))
);
CREATE INDEX IF NOT EXISTS idx_chiron_oauth_log_company_id   ON chiron_oauth_log (company_id);
CREATE INDEX IF NOT EXISTS idx_chiron_oauth_log_environment  ON chiron_oauth_log (environment);
CREATE INDEX IF NOT EXISTS idx_chiron_oauth_log_success      ON chiron_oauth_log (success);
CREATE INDEX IF NOT EXISTS idx_chiron_oauth_log_created_at   ON chiron_oauth_log (created_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_oauth_log TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_oauth_log TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_oauth_log_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_oauth_log_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: chiron_sequence_rules
CREATE TABLE IF NOT EXISTS chiron_sequence_rules (
  id               BIGSERIAL PRIMARY KEY,
  rule_name        VARCHAR(100) NOT NULL,
  from_state       VARCHAR(50),
  to_state         VARCHAR(50) NOT NULL,
  required_status  VARCHAR(50),
  is_allowed       BOOLEAN     DEFAULT TRUE,
  error_code       VARCHAR(20),
  error_message    TEXT,
  created_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chiron_sequence_rules_rule_name_key UNIQUE (rule_name)
);
CREATE INDEX IF NOT EXISTS idx_chiron_sequence_rules_from_to ON chiron_sequence_rules (from_state, to_state);

GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_sequence_rules TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_sequence_rules TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_sequence_rules_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_sequence_rules_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: chiron_sync_log
CREATE TABLE IF NOT EXISTS chiron_sync_log (
  id               BIGSERIAL PRIMARY KEY,
  trip_id          BIGINT      NOT NULL,
  attempt_number   INTEGER     NOT NULL,
  status           VARCHAR(20) NOT NULL,
  request_payload  JSONB,
  response_payload JSONB,
  error_message    TEXT,
  http_status_code INTEGER,
  created_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chiron_sync_log_status_check CHECK (status IN ('success','failed','pending'))
);
CREATE INDEX IF NOT EXISTS idx_chiron_sync_log_trip_id ON chiron_sync_log (trip_id);
CREATE INDEX IF NOT EXISTS idx_chiron_sync_log_status  ON chiron_sync_log (status);

GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_sync_log TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_sync_log TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_sync_log_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_sync_log_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: chiron_validation_log
CREATE TABLE IF NOT EXISTS chiron_validation_log (
  id                BIGSERIAL PRIMARY KEY,
  trip_id           BIGINT,
  test_trip_id      BIGINT,
  validation_type   VARCHAR(50)  NOT NULL,
  field_name        VARCHAR(100) NOT NULL,
  field_value       TEXT,
  is_valid          BOOLEAN      NOT NULL,
  validation_error  TEXT,
  error_code        VARCHAR(20),
  corrected_value   TEXT,
  validated_at      TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chiron_validation_log_validation_type_check CHECK (validation_type IN ('pre_send','post_error','manual_check'))
);
CREATE INDEX IF NOT EXISTS idx_chiron_validation_log_trip_id      ON chiron_validation_log (trip_id);
CREATE INDEX IF NOT EXISTS idx_chiron_validation_log_test_trip_id ON chiron_validation_log (test_trip_id);
CREATE INDEX IF NOT EXISTS idx_chiron_validation_log_is_valid     ON chiron_validation_log (is_valid);
CREATE INDEX IF NOT EXISTS idx_chiron_validation_log_error_code   ON chiron_validation_log (error_code);
CREATE INDEX IF NOT EXISTS idx_chiron_validation_log_validated_at ON chiron_validation_log (validated_at);
CREATE INDEX IF NOT EXISTS idx_chiron_validation_log_invalid_coords ON chiron_validation_log (field_name, is_valid) WHERE field_name IN ('start_lat','start_lon','end_lat','end_lon') AND is_valid = FALSE;

GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_validation_log TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_validation_log TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_validation_log_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_validation_log_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: chiron_validation_rules
CREATE TABLE IF NOT EXISTS chiron_validation_rules (
  id                 BIGSERIAL PRIMARY KEY,
  field_name         VARCHAR(100) NOT NULL,
  field_type         VARCHAR(50)  NOT NULL,
  min_decimal_places INTEGER,
  max_decimal_places INTEGER,
  min_value          NUMERIC(20,10),
  max_value          NUMERIC(20,10),
  regex_pattern      TEXT,
  is_required        BOOLEAN      DEFAULT TRUE,
  error_code         VARCHAR(20),
  validation_message TEXT,
  created_at         TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at         TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chiron_validation_rules_field_name_key  UNIQUE (field_name),
  CONSTRAINT chiron_validation_rules_field_type_check CHECK (field_type IN ('decimal','integer','string','coordinate','datetime'))
);
CREATE INDEX IF NOT EXISTS idx_chiron_validation_rules_field_name ON chiron_validation_rules (field_name);
CREATE INDEX IF NOT EXISTS idx_chiron_validation_rules_error_code ON chiron_validation_rules (error_code);

GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_validation_rules TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_validation_rules TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_validation_rules_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_validation_rules_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: chiron_coordinate_formatting_log
CREATE TABLE IF NOT EXISTS chiron_coordinate_formatting_log (
  id                  BIGSERIAL PRIMARY KEY,
  trip_id             BIGINT,
  test_trip_id        BIGINT,
  message_type        VARCHAR(20)   NOT NULL,
  original_lat        NUMERIC(10,8),
  original_lon        NUMERIC(11,8),
  formatted_lat       NUMERIC(10,6),
  formatted_lon       NUMERIC(11,6),
  formatting_method   VARCHAR(50)   DEFAULT 'auto_trigger',
  created_at          TIMESTAMPTZ   DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chiron_coordinate_formatting_log_message_type_check CHECK (message_type IN ('vertrek','aankomst'))
);
CREATE INDEX IF NOT EXISTS idx_coord_formatting_trip_id      ON chiron_coordinate_formatting_log (trip_id);
CREATE INDEX IF NOT EXISTS idx_coord_formatting_test_trip_id ON chiron_coordinate_formatting_log (test_trip_id);
CREATE INDEX IF NOT EXISTS idx_coord_formatting_message_type ON chiron_coordinate_formatting_log (message_type);

GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_coordinate_formatting_log TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON chiron_coordinate_formatting_log TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_coordinate_formatting_log_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE chiron_coordinate_formatting_log_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: coordinate_formatting_errors
CREATE TABLE IF NOT EXISTS coordinate_formatting_errors (
  id             BIGSERIAL PRIMARY KEY,
  table_name     VARCHAR(50) NOT NULL,
  record_id      BIGINT      NOT NULL,
  field_name     VARCHAR(50) NOT NULL,
  original_value NUMERIC,
  error_message  TEXT,
  created_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_coord_errors_table_record ON coordinate_formatting_errors (table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_coord_errors_created_at   ON coordinate_formatting_errors (created_at);

GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON coordinate_formatting_errors TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON coordinate_formatting_errors TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE coordinate_formatting_errors_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE coordinate_formatting_errors_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================
-- TEST TRIPS
-- ============================================================

-- Table: test_trips
CREATE TABLE IF NOT EXISTS test_trips (
  id                    BIGSERIAL PRIMARY KEY,
  company_id            BIGINT        NOT NULL,
  ritnummer             VARCHAR(100)  NOT NULL,
  message_type          VARCHAR(20)   NOT NULL,
  driver_id             BIGINT        NOT NULL,
  vehicle_id            BIGINT        NOT NULL,
  chiron_driver_id      VARCHAR(100)  NOT NULL,
  chiron_vehicle_id     VARCHAR(100)  NOT NULL,
  start_lat             NUMERIC(10,8),
  start_lon             NUMERIC(11,8),
  end_lat               NUMERIC(10,8),
  end_lon               NUMERIC(11,8),
  start_address         TEXT,
  end_address           TEXT,
  distance_km           NUMERIC(10,2),
  price                 NUMERIC(10,2),
  "timestamp"           TIMESTAMPTZ   NOT NULL,
  request_payload       JSONB,
  response_payload      JSONB,
  http_status_code      INTEGER,
  sync_status           VARCHAR(20)   DEFAULT 'pending',
  error_message         TEXT,
  test_sequence_number  INTEGER       NOT NULL,
  created_at            TIMESTAMPTZ   DEFAULT CURRENT_TIMESTAMP,
  updated_at            TIMESTAMPTZ   DEFAULT CURRENT_TIMESTAMP,
  start_time            TIMESTAMPTZ,
  end_time              TIMESTAMPTZ,
  status                VARCHAR(20)   DEFAULT 'BEZET',
  last_error_details    JSONB,
  last_request_headers  JSONB,
  last_response_headers JSONB,
  oauth_token_used      TEXT,
  retry_attempts        INTEGER       DEFAULT 0,
  validation_status     VARCHAR(20)   DEFAULT 'pending',
  validation_errors     JSONB         DEFAULT '[]',
  last_validation_at    TIMESTAMPTZ,
  start_accepted        BOOLEAN       NOT NULL DEFAULT FALSE,
  start_accepted_at     TIMESTAMPTZ,
  start_message_id      VARCHAR(100),
  arrival_allowed       BOOLEAN       NOT NULL DEFAULT FALSE,
  last_chiron_status    VARCHAR(50),
  start_http_status     INTEGER,
  arrival_http_status   INTEGER,
  vertrek_lat           NUMERIC(10,6),
  vertrek_lon           NUMERIC(11,6),
  aankomst_lat          NUMERIC(10,6),
  aankomst_lon          NUMERIC(11,6),
  CONSTRAINT test_trips_ritnummer_key            UNIQUE (ritnummer),
  CONSTRAINT test_trips_test_sequence_number_check CHECK (test_sequence_number >= 1 AND test_sequence_number <= 10),
  CONSTRAINT test_trips_sync_status_check        CHECK (sync_status   IN ('pending','success','failed')),
  CONSTRAINT test_trips_status_check             CHECK (LOWER(status) IN ('bezet','vrij','pauze','storing')),
  CONSTRAINT test_trips_message_type_check       CHECK (LOWER(message_type) IN ('vertrek','aankomst')),
  CONSTRAINT test_trips_start_lat_decimals_check CHECK (start_lat IS NULL OR CAST(start_lat AS TEXT) ~ E'^\\-?[0-9]+\\.[0-9]{5,}$'),
  CONSTRAINT test_trips_start_lon_decimals_check CHECK (start_lon IS NULL OR CAST(start_lon AS TEXT) ~ E'^\\-?[0-9]+\\.[0-9]{5,}$'),
  CONSTRAINT test_trips_end_lat_decimals_check   CHECK (end_lat   IS NULL OR CAST(end_lat   AS TEXT) ~ E'^\\-?[0-9]+\\.[0-9]{5,}$'),
  CONSTRAINT test_trips_end_lon_decimals_check   CHECK (end_lon   IS NULL OR CAST(end_lon   AS TEXT) ~ E'^\\-?[0-9]+\\.[0-9]{5,}$'),
  CONSTRAINT test_trips_start_time_valid_check   CHECK (start_time IS NULL OR validate_chiron_timestamp(start_time)),
  CONSTRAINT test_trips_end_time_valid_check     CHECK (end_time   IS NULL OR validate_chiron_timestamp(end_time))
);
CREATE INDEX IF NOT EXISTS idx_test_trips_company_id         ON test_trips (company_id);
CREATE INDEX IF NOT EXISTS idx_test_trips_ritnummer          ON test_trips (ritnummer);
CREATE INDEX IF NOT EXISTS idx_test_trips_sync_status        ON test_trips (sync_status);
CREATE INDEX IF NOT EXISTS idx_test_trips_test_sequence      ON test_trips (test_sequence_number);
CREATE INDEX IF NOT EXISTS idx_test_trips_start_time         ON test_trips (start_time);
CREATE INDEX IF NOT EXISTS idx_test_trips_end_time           ON test_trips (end_time);
CREATE INDEX IF NOT EXISTS idx_test_trips_status             ON test_trips (status);
CREATE INDEX IF NOT EXISTS idx_test_trips_validation_status  ON test_trips (validation_status);
CREATE INDEX IF NOT EXISTS idx_test_trips_start_accepted     ON test_trips (start_accepted);
CREATE INDEX IF NOT EXISTS idx_test_trips_arrival_allowed    ON test_trips (arrival_allowed);
CREATE INDEX IF NOT EXISTS idx_test_trips_start_accepted_at  ON test_trips (start_accepted_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON test_trips TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON test_trips TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE test_trips_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE test_trips_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: test_message_attempts
CREATE TABLE IF NOT EXISTS test_message_attempts (
  id                    BIGSERIAL PRIMARY KEY,
  test_trip_id          BIGINT      NOT NULL,
  attempt_number        INTEGER     NOT NULL,
  message_type          VARCHAR(20) NOT NULL,
  request_url           TEXT        NOT NULL,
  request_method        VARCHAR(10) DEFAULT 'POST',
  request_headers       JSONB,
  request_body          JSONB,
  response_status_code  INTEGER,
  response_headers      JSONB,
  response_body         JSONB,
  error_message         TEXT,
  error_stack           TEXT,
  oauth_token_used      TEXT,
  attempt_started_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  attempt_completed_at  TIMESTAMPTZ,
  duration_ms           INTEGER,
  created_at            TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT test_message_attempts_message_type_check CHECK (message_type IN ('vertrek','aankomst'))
);
CREATE INDEX IF NOT EXISTS idx_test_message_attempts_test_trip_id      ON test_message_attempts (test_trip_id);
CREATE INDEX IF NOT EXISTS idx_test_message_attempts_message_type      ON test_message_attempts (message_type);
CREATE INDEX IF NOT EXISTS idx_test_message_attempts_response_status   ON test_message_attempts (response_status_code);
CREATE INDEX IF NOT EXISTS idx_test_message_attempts_created_at        ON test_message_attempts (created_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON test_message_attempts TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON test_message_attempts TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE test_message_attempts_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE test_message_attempts_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: acceptance_test_reports
CREATE TABLE IF NOT EXISTS acceptance_test_reports (
  id                        BIGSERIAL PRIMARY KEY,
  company_id                BIGINT      NOT NULL,
  report_date               DATE        NOT NULL,
  total_messages            INTEGER     DEFAULT 10,
  success_count             INTEGER     DEFAULT 0,
  failed_count              INTEGER     DEFAULT 0,
  vertrek_count             INTEGER     DEFAULT 0,
  aankomst_count            INTEGER     DEFAULT 0,
  test_trip_ids             JSONB       DEFAULT '[]',
  report_status             VARCHAR(20) DEFAULT 'in_progress',
  report_pdf_url            TEXT,
  submitted_to_municipality BOOLEAN     DEFAULT FALSE,
  submission_date           TIMESTAMPTZ,
  notes                     TEXT,
  created_at                TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at                TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  driver_id                 BIGINT,
  CONSTRAINT acceptance_test_reports_report_status_check CHECK (report_status IN ('in_progress','completed','failed'))
);
CREATE INDEX IF NOT EXISTS idx_acceptance_reports_company_id ON acceptance_test_reports (company_id);
CREATE INDEX IF NOT EXISTS idx_acceptance_reports_status     ON acceptance_test_reports (report_status);
CREATE INDEX IF NOT EXISTS idx_acceptance_reports_driver_id  ON acceptance_test_reports (driver_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON acceptance_test_reports TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON acceptance_test_reports TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE acceptance_test_reports_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE acceptance_test_reports_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================
-- MISC
-- ============================================================

-- Table: homepage_ad_slots
CREATE TABLE IF NOT EXISTS homepage_ad_slots (
  id                  BIGSERIAL PRIMARY KEY,
  slot_key            VARCHAR(100) NOT NULL,
  title               VARCHAR(200) NOT NULL,
  html_content        TEXT         NOT NULL,
  is_active           BOOLEAN      NOT NULL DEFAULT TRUE,
  start_time          TIMESTAMPTZ,
  end_time            TIMESTAMPTZ,
  display_order       INTEGER      NOT NULL DEFAULT 1,
  created_by_user_id  BIGINT,
  create_time         TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  modify_time         TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT homepage_ad_slots_slot_key_display_order_key UNIQUE (slot_key, display_order)
);
CREATE INDEX IF NOT EXISTS idx_homepage_ad_slots_slot_key      ON homepage_ad_slots (slot_key);
CREATE INDEX IF NOT EXISTS idx_homepage_ad_slots_is_active     ON homepage_ad_slots (is_active);
CREATE INDEX IF NOT EXISTS idx_homepage_ad_slots_start_time    ON homepage_ad_slots (start_time);
CREATE INDEX IF NOT EXISTS idx_homepage_ad_slots_end_time      ON homepage_ad_slots (end_time);
CREATE INDEX IF NOT EXISTS idx_homepage_ad_slots_display_order ON homepage_ad_slots (display_order);

GRANT SELECT, INSERT, UPDATE, DELETE ON homepage_ad_slots TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON homepage_ad_slots TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE homepage_ad_slots_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE homepage_ad_slots_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: subscription_suspension_log
CREATE TABLE IF NOT EXISTS subscription_suspension_log (
  id                       BIGSERIAL PRIMARY KEY,
  company_id               BIGINT      NOT NULL,
  contract_id              BIGINT,
  suspension_type          VARCHAR(50) NOT NULL,
  suspension_reason        TEXT        NOT NULL,
  suspended_by_user_id     BIGINT      NOT NULL,
  suspended_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  reactivated_at           TIMESTAMPTZ,
  reactivated_by_user_id   BIGINT,
  reactivation_notes       TEXT,
  created_at               TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT subscription_suspension_log_suspension_type_check CHECK (suspension_type IN ('payment_overdue','contract_violation','manual','other'))
);
CREATE INDEX IF NOT EXISTS idx_suspension_log_company_id   ON subscription_suspension_log (company_id);
CREATE INDEX IF NOT EXISTS idx_suspension_log_contract_id  ON subscription_suspension_log (contract_id);
CREATE INDEX IF NOT EXISTS idx_suspension_log_suspended_at ON subscription_suspension_log (suspended_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON subscription_suspension_log TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON subscription_suspension_log TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE subscription_suspension_log_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE subscription_suspension_log_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: scheduled_tasks
CREATE TABLE IF NOT EXISTS scheduled_tasks (
  id                     BIGSERIAL PRIMARY KEY,
  task_type              VARCHAR(50) NOT NULL,
  entity_type            VARCHAR(50) NOT NULL,
  entity_id              BIGINT      NOT NULL,
  scheduled_for          TIMESTAMPTZ NOT NULL,
  status                 VARCHAR(20) DEFAULT 'pending',
  execution_started_at   TIMESTAMPTZ,
  execution_completed_at TIMESTAMPTZ,
  result_data            JSONB,
  error_message          TEXT,
  retry_count            INTEGER     DEFAULT 0,
  max_retries            INTEGER     DEFAULT 3,
  created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT scheduled_tasks_task_type_check   CHECK (task_type   IN ('generate_monthly_invoice','send_payment_reminder','check_overdue_invoices','renew_contract')),
  CONSTRAINT scheduled_tasks_entity_type_check CHECK (entity_type IN ('contract','invoice','company')),
  CONSTRAINT scheduled_tasks_status_check      CHECK (status      IN ('pending','processing','completed','failed','cancelled'))
);
CREATE INDEX IF NOT EXISTS idx_scheduled_tasks_task_type      ON scheduled_tasks (task_type);
CREATE INDEX IF NOT EXISTS idx_scheduled_tasks_entity         ON scheduled_tasks (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_tasks_scheduled_for  ON scheduled_tasks (scheduled_for);
CREATE INDEX IF NOT EXISTS idx_scheduled_tasks_status         ON scheduled_tasks (status);

GRANT SELECT, INSERT, UPDATE, DELETE ON scheduled_tasks TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON scheduled_tasks TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE scheduled_tasks_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE scheduled_tasks_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================
-- AI ASSISTANT
-- ============================================================

-- Table: ai_assistant_conversations
CREATE TABLE IF NOT EXISTS ai_assistant_conversations (
  id                      BIGSERIAL PRIMARY KEY,
  user_id                 BIGINT       NOT NULL,
  session_token           VARCHAR(100) NOT NULL,
  status                  VARCHAR(20)  DEFAULT 'active',
  identified_company_id   BIGINT,
  identified_driver_id    BIGINT,
  identified_vehicle_id   BIGINT,
  identified_trip_id      BIGINT,
  problem_summary         TEXT,
  resolution_summary      TEXT,
  message_count           INTEGER      DEFAULT 0,
  created_at              TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at              TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT ai_assistant_conversations_session_token_key UNIQUE (session_token),
  CONSTRAINT ai_assistant_conversations_status_check      CHECK (status IN ('active','closed','resolved'))
);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_user_id        ON ai_assistant_conversations (user_id);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_status         ON ai_assistant_conversations (status);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_session_token  ON ai_assistant_conversations (session_token);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_company_id     ON ai_assistant_conversations (identified_company_id);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_driver_id      ON ai_assistant_conversations (identified_driver_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON ai_assistant_conversations TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ai_assistant_conversations TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE ai_assistant_conversations_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE ai_assistant_conversations_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: ai_assistant_messages
CREATE TABLE IF NOT EXISTS ai_assistant_messages (
  id               BIGSERIAL PRIMARY KEY,
  conversation_id  BIGINT      NOT NULL,
  user_id          BIGINT      NOT NULL,
  role             VARCHAR(20) NOT NULL,
  content          TEXT        NOT NULL,
  metadata         JSONB       DEFAULT '{}',
  created_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT ai_assistant_messages_role_check CHECK (role IN ('user','assistant'))
);
CREATE INDEX IF NOT EXISTS idx_ai_messages_conversation_id ON ai_assistant_messages (conversation_id);
CREATE INDEX IF NOT EXISTS idx_ai_messages_user_id         ON ai_assistant_messages (user_id);
CREATE INDEX IF NOT EXISTS idx_ai_messages_role            ON ai_assistant_messages (role);
CREATE INDEX IF NOT EXISTS idx_ai_messages_created_at      ON ai_assistant_messages (created_at);

GRANT SELECT, INSERT, UPDATE, DELETE ON ai_assistant_messages TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ai_assistant_messages TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE ai_assistant_messages_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE ai_assistant_messages_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- Table: ai_assistant_actions
CREATE TABLE IF NOT EXISTS ai_assistant_actions (
  id                    BIGSERIAL PRIMARY KEY,
  conversation_id       BIGINT       NOT NULL,
  user_id               BIGINT       NOT NULL,
  action_type           VARCHAR(50)  NOT NULL,
  action_description    TEXT         NOT NULL,
  target_table          VARCHAR(100),
  target_record_id      BIGINT,
  before_data           JSONB,
  proposed_changes      JSONB        NOT NULL,
  status                VARCHAR(20)  DEFAULT 'pending',
  confirmed_at          TIMESTAMPTZ,
  executed_at           TIMESTAMPTZ,
  rejected_at           TIMESTAMPTZ,
  rejection_reason      TEXT,
  execution_error       TEXT,
  notification_email    VARCHAR(255) DEFAULT 'ezetdin@gmail.com',
  email_sent            BOOLEAN      DEFAULT FALSE,
  email_sent_at         TIMESTAMPTZ,
  created_at            TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  updated_at            TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
  execution_details     JSONB        DEFAULT '{}',
  confirmed_by_user_id  BIGINT,
  CONSTRAINT ai_assistant_actions_action_type_check CHECK (action_type IN ('update_trip','update_driver','update_vehicle','update_company','cancel_trip','change_trip_status','update_payment','other')),
  CONSTRAINT ai_assistant_actions_status_check      CHECK (status      IN ('pending','confirmed','rejected','executed','failed'))
);
CREATE INDEX IF NOT EXISTS idx_ai_actions_conversation_id ON ai_assistant_actions (conversation_id);
CREATE INDEX IF NOT EXISTS idx_ai_actions_user_id         ON ai_assistant_actions (user_id);
CREATE INDEX IF NOT EXISTS idx_ai_actions_status          ON ai_assistant_actions (status);
CREATE INDEX IF NOT EXISTS idx_ai_actions_action_type     ON ai_assistant_actions (action_type);
CREATE INDEX IF NOT EXISTS idx_ai_actions_target_table    ON ai_assistant_actions (target_table);
CREATE INDEX IF NOT EXISTS idx_ai_actions_target_record   ON ai_assistant_actions (target_record_id);
CREATE INDEX IF NOT EXISTS idx_ai_actions_pending         ON ai_assistant_actions (status, created_at) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_ai_actions_email_sent      ON ai_assistant_actions (email_sent) WHERE email_sent = FALSE;
CREATE INDEX IF NOT EXISTS idx_ai_actions_failed          ON ai_assistant_actions (status, created_at) WHERE status = 'failed';

GRANT SELECT, INSERT, UPDATE, DELETE ON ai_assistant_actions TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ai_assistant_actions TO app20251225073911jaqqaxdfir_v1_user;
GRANT USAGE, SELECT ON SEQUENCE ai_assistant_actions_id_seq TO app20251225073911jaqqaxdfir_v1_admin_user;
GRANT USAGE, SELECT ON SEQUENCE ai_assistant_actions_id_seq TO app20251225073911jaqqaxdfir_v1_user;

-- ============================================================
-- END OF MIGRATION SCRIPT
-- Total Tables: 64 (excludes spatial_ref_sys - managed by PostGIS)
-- Run this script on a fresh PostgreSQL database with PostGIS installed
-- ============================================================
