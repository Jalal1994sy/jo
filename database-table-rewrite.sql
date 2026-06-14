
BEGIN;

SET search_path TO app20251225073911jaqqaxdfir_v1, public;

CREATE OR REPLACE FUNCTION try_parse_jsonb_text(input_text text)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  parsed_value jsonb;
BEGIN
  IF input_text IS NULL OR btrim(input_text) = '' THEN
    RETURN NULL;
  END IF;

  BEGIN
    parsed_value := input_text::jsonb;
    RETURN parsed_value;
  EXCEPTION
    WHEN others THEN
      RETURN to_jsonb(input_text);
  END;
END;
$$;

CREATE OR REPLACE FUNCTION normalize_jsonb_value(input_value jsonb)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  raw_text text;
BEGIN
  IF input_value IS NULL THEN
    RETURN NULL;
  END IF;

  IF jsonb_typeof(input_value) <> 'string' THEN
    RETURN input_value;
  END IF;

  raw_text := trim(both '"' FROM input_value::text);
  raw_text := replace(raw_text, E'\\\"', '"');
  raw_text := replace(raw_text, E'\\\\', E'\\');

  IF left(ltrim(raw_text), 1) IN ('{', '[') THEN
    RETURN try_parse_jsonb_text(raw_text);
  END IF;

  RETURN input_value;
END;
$$;

UPDATE approval_requests
SET
  request_data = normalize_jsonb_value(request_data),
  current_data = normalize_jsonb_value(current_data);

UPDATE approval_history
SET
  action_data = normalize_jsonb_value(action_data);

UPDATE approval_execution_log
SET
  previous_data = normalize_jsonb_value(previous_data),
  new_data = normalize_jsonb_value(new_data);

UPDATE driver_registration_steps
SET
  step_data = normalize_jsonb_value(step_data);

UPDATE driver_registration_requests
SET
  additional_docs = normalize_jsonb_value(additional_docs);

UPDATE vehicles
SET
  documents = normalize_jsonb_value(documents);

UPDATE companies
SET
  peak_hours = normalize_jsonb_value(peak_hours);

UPDATE acceptance_test_reports
SET
  test_trip_ids = normalize_jsonb_value(test_trip_ids);

UPDATE test_trips
SET
  request_payload = normalize_jsonb_value(request_payload),
  response_payload = normalize_jsonb_value(response_payload),
  last_error_details = normalize_jsonb_value(last_error_details),
  last_request_headers = normalize_jsonb_value(last_request_headers),
  last_response_headers = normalize_jsonb_value(last_response_headers),
  validation_errors = normalize_jsonb_value(validation_errors);

UPDATE companies
SET chiron_mode = lower(chiron_mode)
WHERE chiron_mode IS NOT NULL;

ALTER TABLE companies
  ALTER COLUMN chiron_mode SET DEFAULT 'test';

ALTER TABLE companies
  DROP CONSTRAINT IF EXISTS companies_chiron_mode_check;

ALTER TABLE companies
  ADD CONSTRAINT companies_chiron_mode_check
  CHECK (lower(chiron_mode) IN ('test', 'production'));

UPDATE platform_contracts
SET platform_name = lower(platform_name)
WHERE platform_name IS NOT NULL;

ALTER TABLE platform_contracts
  DROP CONSTRAINT IF EXISTS platform_contracts_platform_name_check;

ALTER TABLE platform_contracts
  ADD CONSTRAINT platform_contracts_platform_name_check
  CHECK (lower(platform_name) IN ('uber', 'bolt', 'heetch'));

UPDATE test_trips
SET
  status = lower(status),
  message_type = lower(message_type)
WHERE status IS NOT NULL OR message_type IS NOT NULL;

ALTER TABLE test_trips
  ALTER COLUMN status SET DEFAULT 'bezet';

ALTER TABLE test_trips
  DROP CONSTRAINT IF EXISTS test_trips_status_check;

ALTER TABLE test_trips
  ADD CONSTRAINT test_trips_status_check
  CHECK (lower(status) IN ('bezet', 'vrij', 'pauze', 'storing'));

ALTER TABLE test_trips
  DROP CONSTRAINT IF EXISTS test_trips_message_type_check;

ALTER TABLE test_trips
  ADD CONSTRAINT test_trips_message_type_check
  CHECK (lower(message_type) IN ('vertrek', 'aankomst'));

ALTER TABLE approval_requests
  ADD COLUMN IF NOT EXISTS request_data_text text GENERATED ALWAYS AS (request_data::text) STORED,
  ADD COLUMN IF NOT EXISTS current_data_text text GENERATED ALWAYS AS (current_data::text) STORED;

ALTER TABLE approval_history
  ADD COLUMN IF NOT EXISTS action_data_text text GENERATED ALWAYS AS (action_data::text) STORED;

ALTER TABLE approval_execution_log
  ADD COLUMN IF NOT EXISTS previous_data_text text GENERATED ALWAYS AS (previous_data::text) STORED,
  ADD COLUMN IF NOT EXISTS new_data_text text GENERATED ALWAYS AS (new_data::text) STORED;

ALTER TABLE driver_registration_steps
  ADD COLUMN IF NOT EXISTS step_data_text text GENERATED ALWAYS AS (step_data::text) STORED;

ALTER TABLE driver_registration_requests
  ADD COLUMN IF NOT EXISTS additional_docs_text text GENERATED ALWAYS AS (additional_docs::text) STORED;

ALTER TABLE vehicles
  ADD COLUMN IF NOT EXISTS documents_text text GENERATED ALWAYS AS (documents::text) STORED;

ALTER TABLE companies
  ADD COLUMN IF NOT EXISTS peak_hours_text text GENERATED ALWAYS AS (peak_hours::text) STORED;

ALTER TABLE acceptance_test_reports
  ADD COLUMN IF NOT EXISTS test_trip_ids_text text GENERATED ALWAYS AS (test_trip_ids::text) STORED;

ALTER TABLE test_trips
  ADD COLUMN IF NOT EXISTS request_payload_text text GENERATED ALWAYS AS (request_payload::text) STORED,
  ADD COLUMN IF NOT EXISTS response_payload_text text GENERATED ALWAYS AS (response_payload::text) STORED,
  ADD COLUMN IF NOT EXISTS last_error_details_text text GENERATED ALWAYS AS (last_error_details::text) STORED,
  ADD COLUMN IF NOT EXISTS last_request_headers_text text GENERATED ALWAYS AS (last_request_headers::text) STORED,
  ADD COLUMN IF NOT EXISTS last_response_headers_text text GENERATED ALWAYS AS (last_response_headers::text) STORED,
  ADD COLUMN IF NOT EXISTS validation_errors_text text GENERATED ALWAYS AS (validation_errors::text) STORED;

COMMIT;
