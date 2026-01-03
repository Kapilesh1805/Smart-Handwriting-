# Step 1: Login/Register Backend Integration - Setup Guide

## Summary of Changes Made

This document describes all the changes made to implement Step 1 (Authentication) with full backend integration.

---

## 📁 New Files Created

### 1. **lib/config/api_config.dart**
- **Purpose**: Centralized API configuration and helper functions
- **Contains**:
  - `Config` class with API base URL and authentication helpers
  - `apiCall()` function for making HTTP requests (GET, POST, PUT, DELETE)
  - Helper methods for token management using SharedPreferences
  - Request timeout handling (30 seconds)

### 2. **lib/services/auth_service.dart**
- **Purpose**: Authentication service with backend integration
- **Contains**:
  - `login()` - Authenticate with email/password
  - `register()` - Create new account
  - `forgotPassword()` - Request password reset
  - `logout()` - Clear stored credentials
  - `isLoggedIn()` - Check if user has valid token
  - `getToken()` - Retrieve stored JWT token
  - `getUserId()` - Retrieve stored user ID
- **Error Handling**:
  - Network errors (SocketException)
  - Timeout errors
  - Invalid credentials (401)
  - Email already exists (409)
  - Invalid data (400)

### 3. **lib/widgets/backend_connection_indicator.dart**
- **Purpose**: Visual indicator of backend connection status
- **Features**:
  - Shows green checkmark if backend is reachable
  - Shows orange warning if backend is unavailable
  - Automatically checks connection on load
  - Displays backend URL for debugging

---

## 📝 Files Modified

### 1. **lib/screens/landing_page.dart**
**Changes**:
- Added import for `BackendConnectionIndicator`
- Added connection indicator widget to both mobile and desktop layouts
- Indicator appears at the top of the page showing backend status

### 2. **lib/widgets/login_form.dart**
**Changes**:
- Added import for `AuthService`
- Added `_errorMessage` state variable to display error messages
- Updated `_handleLogin()` to call backend API instead of mock navigation
  - Validates form
  - Calls `AuthService.login()`
  - Saves token and user_id on success
  - Displays error message on failure
  - Navigates to DashboardPage on success
- Updated `_showForgotPasswordDialog()` to call backend API
  - Changed from password reset to email-based reset
  - Calls `AuthService.forgotPassword()`
  - Shows success/error messages
  - Simplified UI (removed password fields)
- Added error display container in build method
- Updated button to show loading spinner when processing

### 3. **lib/widgets/register_form.dart**
**Changes**:
- Added import for `AuthService` and `DashboardPage`
- Added `_isLoading` and `_errorMessage` state variables
- Updated `_handleRegister()` to call backend API
  - Calls `AuthService.register()`
  - Shows success message
  - Navigates to DashboardPage automatically
  - Shows error message on failure
- Added error display container in build method
- Updated button to show loading spinner when processing

---

## 🔧 Configuration Required

### Step 1: Update Backend URL
Edit `lib/config/api_config.dart`:

```dart
static const String apiBaseUrl = 'http://YOUR_BACKEND_IP:5000';
```

**Examples**:
- Local development: `http://localhost:5000`
- Remote machine: `http://192.168.1.100:5000`
- Production: `https://your-domain.com`

### Step 2: Ensure Dependencies
Check that pubspec.yaml has these packages (already present):
```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.2
```

If not, run:
```bash
flutter pub add http shared_preferences
```

---

## ✅ Testing the Implementation

### 1. Start Backend Server
Ensure your Flask backend is running:
```bash
cd smartboard-backend
python app.py
```

Backend should be accessible at: `http://localhost:5000`

### 2. Update Frontend URL
In `lib/config/api_config.dart`, set the correct backend URL:
```dart
static const String apiBaseUrl = 'http://localhost:5000';
```

### 3. Run the Flutter App
```bash
flutter run
```

### 4. Test Login
Click on the login tab and try:
- **Valid credentials**: Email and password registered in backend
- **Invalid credentials**: Should show "Invalid email or password"
- **Network error**: Disconnect internet, should show "No internet connection"
- **Backend down**: Stop Flask server, should show connection indicator in red

### 5. Test Registration
Click on the register tab and try:
- **New email**: Should create account and navigate to dashboard
- **Existing email**: Should show "Email already registered"
- **Invalid email**: Should show validation error

### 6. Test Forgot Password
Click "Forgot Password" button:
- **Valid email**: Should show "Password reset link sent to your email"
- **Invalid email**: Should show "Email not found"

---

## 🔐 Security Notes

### Token Storage
- Tokens are stored in `SharedPreferences` for now (development)
- **For production**: Migrate to secure storage:
  ```bash
  flutter pub add flutter_secure_storage
  ```
  Then update `Config` class to use secure storage

### Sensitive Data
- Passwords are sent over HTTP in development
- **For production**: Use HTTPS and verify SSL certificates
  ```dart
  // In api_config.dart - verify SSL
  HttpClient httpClient = HttpClient();
  httpClient.badCertificateCallback = ((x509.X509Certificate cert, String host, int port) => false);
  ```

### Backend CORS
Ensure your Flask backend has CORS enabled:
```python
# In app.py
from flask_cors import CORS
CORS(app)
```

---

## 📊 Data Flow

### Login Flow
```
User enters email/password
         ↓
Click LOGIN button
         ↓
Form validation
         ↓
Call AuthService.login()
         ↓
POST /auth/login {email, password}
         ↓
Backend validates credentials
         ↓
Returns: {token, user_id}
         ↓
Save to SharedPreferences
         ↓
Navigate to DashboardPage
```

### Registration Flow
```
User fills form (name, email, password)
         ↓
Click CREATE ACCOUNT button
         ↓
Form validation
         ↓
Call AuthService.register()
         ↓
POST /auth/register {name, email, password}
         ↓
Backend creates user & hashes password
         ↓
Returns: {token, user_id}
         ↓
Save to SharedPreferences
         ↓
Show success message
         ↓
Navigate to DashboardPage
```

---

## 🐛 Troubleshooting

### Issue: "No internet connection" error
**Solution**: 
- Check if backend is running
- Check if URL in `api_config.dart` is correct
- Check if firewall is blocking requests

### Issue: "Request timeout"
**Solution**:
- Backend server is slow/unresponsive
- Increase timeout in `api_config.dart` (currently 30 seconds)
- Check backend logs

### Issue: "Invalid email or password"
**Solution**:
- Check if user exists in database
- Check if password is correct
- Check backend database directly

### Issue: Backend connection indicator shows red
**Solution**:
- Check if Flask app is running
- Check if port 5000 is correct
- Check if frontend URL points to correct backend

### Issue: Page navigation not working after login
**Solution**:
- Check if `DashboardPage` exists and is properly imported
- Check console for navigation errors
- Ensure token was saved to SharedPreferences

---

## 🚀 Next Steps

After Step 1 is complete and working:

1. **Test with actual backend server** running locally
2. **Create test accounts** in backend database
3. **Verify tokens are saved** to SharedPreferences:
   - Use `flutter pub add shared_preferences`
   - Check device storage in debug console
4. **Set up HTTPS** for production
5. **Migrate to secure storage** for tokens
6. **Proceed to Step 2**: Dashboard integration

---

## 📚 API Endpoint Reference

### POST /auth/login
**Request**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```
**Response (200)**:
```json
{
  "msg": "ok",
  "token": "eyJhbGc...",
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### POST /auth/register
**Request**:
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}
```
**Response (201)**:
```json
{
  "msg": "registered",
  "token": "eyJhbGc...",
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### POST /auth/forgot_password
**Request**:
```json
{
  "email": "user@example.com"
}
```
**Response (200)**:
```json
{
  "msg": "reset token sent",
  "reset_token": "temp_token_123"
}
```

---

## ✨ Key Features Implemented

✅ Email/password login with validation  
✅ User registration with validation  
✅ Forgot password functionality  
✅ JWT token storage and retrieval  
✅ Error handling with user-friendly messages  
✅ Network error detection  
✅ Timeout handling  
✅ Backend connection indicator  
✅ Loading states and spinners  
✅ Secure credential handling  
✅ Auto-login after registration  

---

## 📞 Support

If you encounter issues:
1. Check Flask backend is running: `python app.py`
2. Verify API URL in `api_config.dart`
3. Check backend logs for error details
4. Verify request/response format matches endpoint spec
5. Check internet connection
6. Try clearing app cache and rebuilding

---

**Step 1 Complete!** ✅  
Ready to proceed to Step 2: Dashboard Integration
