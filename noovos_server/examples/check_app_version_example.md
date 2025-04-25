# Check App Version API Example

## API Endpoint
```
POST http://localhost:3000/check_app_version
```

## Headers
```
Content-Type: application/json
```

## Request Body (Current Version)
```json
{
  "platform": "android",
  "version": "1.0.0"
}
```

## Response (No Update Required)
```json
{
  "return_code": "SUCCESS",
  "is_update_required": false,
  "minimum_version": "1.0.0",
  "current_version": "1.0.0"
}
```

## Request Body (Outdated Version)
```json
{
  "platform": "android",
  "version": "0.9.0"
}
```

## Response (Update Required)
```json
{
  "return_code": "UPDATE_REQUIRED",
  "is_update_required": true,
  "minimum_version": "1.0.0",
  "current_version": "0.9.0"
}
```

## Postman Setup Instructions

1. Open Postman
2. Create a new request
3. Set the request type to POST
4. Enter the URL: `http://localhost:3000/check_app_version` (or your server URL)
5. Go to the "Headers" tab and add:
   - Key: `Content-Type`
   - Value: `application/json`
6. Go to the "Body" tab
7. Select "raw" and "JSON" format
8. Enter one of the example request bodies above
9. Click "Send" to test the API

## Notes

- Make sure your server is running before testing
- You may need to run the `insert_app_version_requirements.sql` script to populate the database with version requirements
- The API compares version numbers semantically (e.g., "1.2.0" is greater than "1.1.9")
- If the platform is not found in the database, the API will return a "PLATFORM_NOT_FOUND" response
