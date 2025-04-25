-- Insert sample app version requirements
INSERT INTO app_version_requirement (platform, minimum_version)
VALUES 
    ('android', 1.00),
    ('ios', 1.00),
    ('web', 1.00)
ON CONFLICT (platform) 
DO UPDATE SET minimum_version = EXCLUDED.minimum_version;
