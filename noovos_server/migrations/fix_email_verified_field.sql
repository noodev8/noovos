-- Migration to fix email_verified field
-- This script sets a default value for email_verified and updates existing NULL values

-- Set default value for email_verified field
ALTER TABLE app_user ALTER COLUMN email_verified SET DEFAULT false;

-- Update existing NULL values to false
UPDATE app_user SET email_verified = false WHERE email_verified IS NULL;

-- Make the field NOT NULL now that all values are set
ALTER TABLE app_user ALTER COLUMN email_verified SET NOT NULL;
