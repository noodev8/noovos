-- Drop app version requirement table and related objects
-- This script removes the app version checking functionality from the database

-- Drop the table
DROP TABLE IF EXISTS app_version_requirement CASCADE;

-- Drop the sequence
DROP SEQUENCE IF EXISTS app_version_requirement_id_seq CASCADE;

-- Note: This script removes all app version checking functionality from the database
-- The app will no longer check for minimum required versions
-- Version updates will be handled by the iOS App Store and Google Play Store
