# PayslipMax Website Configuration

This document outlines the required configuration for the PayslipMax website to enable deep linking to the iOS app.

## Apple App Site Association (AASA) File

Create a file named `apple-app-site-association` (no file extension) in the `.well-known` directory at the root of the website. This file must be served with the `Content-Type: application/json` header.

```json
{
    "applinks": {
        "apps": [],
        "details": [{
            "appID": "TEAM_ID.com.yourcompany.payslipmax",
            "paths": [
                "/upload/*",
                "/process/*",
                "/link-device/*"
            ]
        }]
    }
}
```

Replace `TEAM_ID` with your actual Apple Developer Team ID.

## Web Upload Implementation

### 1. Upload Form

Create a form on the website that allows users to upload PDF files. The form should include:

- File selection with drag-and-drop support
- Optional password field for encrypted PDFs
- Submit button

### 2. Processing Workflow

When a user uploads a file, the website should:

1. Generate a unique ID for the upload (UUID)
2. Store the file temporarily on the server
3. Generate a secure token for accessing the file
4. Redirect the user to a URL that will open the app:

```
https://payslipmax.com/upload?id=UUID&filename=FILENAME&size=FILESIZE&source=SOURCE&token=TOKEN&protected=ISPROTECTED
```

Parameters:
- `id`: The UUID for the upload
- `filename`: The name of the uploaded file
- `size`: The file size in bytes
- `source`: The source of the upload (e.g., "payslipmax.com")
- `token`: A secure token for accessing the file
- `protected`: "true" if the file is password protected, "false" otherwise

### 3. Device Linking

For users without the app, provide a QR code or code entry system to link their device:

1. Create a page at `/link-device` that accepts a token parameter
2. When scanned/entered on a device with the app, register the device for future uploads
3. Show confirmation to the user when linked successfully

### 4. API Endpoints

The following API endpoints need to be implemented:

#### 1. Device Registration
```
POST /api/devices/register
```
Request body: Device information (name, type, OS version, app version)
Response: A device token

#### 2. Pending Uploads
```
GET /api/uploads/pending
```
Authorization: Bearer token (device token)
Response: List of pending uploads in JSON format

#### 3. Upload Download
```
GET /api/uploads/{id}
```
Authorization: Bearer token (secure token)
Response: The PDF file

## HTTPS Configuration

All endpoints must be served over HTTPS with proper TLS certificates. 