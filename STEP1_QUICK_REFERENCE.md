# Step 1: Quick Reference Guide

## 🎯 Quick Start (5 minutes)

### 1. Update Backend URL
```dart
// File: lib/config/api_config.dart
static const String apiBaseUrl = 'http://localhost:5000';
```

### 2. Start Backend
```bash
cd smartboard-backend
python app.py
```

### 3. Run Flutter App
```bash
flutter run
```

### 4. Test Login
- Email: `test@example.com`
- Password: `password123`
- Expected: Navigate to Dashboard ✅

---

## 📂 File Structure

```
handwriting_frontend/
├── lib/
│   ├── config/
│   │   └── api_config.dart           ⭐ NEW - API configuration
│   ├── services/
│   │   └── auth_service.dart         ⭐ NEW - Auth logic
│   ├── widgets/
│   │   ├── login_form.dart           ✏️ UPDATED - Backend integration
│   │   ├── register_form.dart        ✏️ UPDATED - Backend integration
│   │   └── backend_connection_indicator.dart  ⭐ NEW - Connection status
│   ├── screens/
│   │   └── landing_page.dart         ✏️ UPDATED - Added indicator
│   └── main.dart                      (unchanged)
├── STEP1_SETUP_GUIDE.md              ⭐ NEW - Setup instructions
└── STEP1_TESTING_CHECKLIST.md        ⭐ NEW - Testing guide
```

---

## 🔧 Configuration

### Backend URL (IMPORTANT!)
```dart
// lib/config/api_config.dart - Line 7
static const String apiBaseUrl = 'http://YOUR_URL:5000';
```

### Common URLs
| Environment | URL |
|---|---|
| Local | `http://localhost:5000` |
| Local Network | `http://192.168.x.x:5000` |
| Android Emulator | `http://10.0.2.2:5000` |
| iOS Simulator | `http://localhost:5000` |
| Production | `https://your-domain.com` |

---

## 📊 Data Flow (Simple)

```
User Input → Form Validation → AuthService → Backend API → Token Storage → Dashboard
```

### Detailed Flow

**Login**:
```
Email + Password
    ↓ (form validation)
AuthService.login()
    ↓
POST /auth/login
    ↓ (backend checks credentials)
Token + User ID
    ↓
SharedPreferences
    ↓
Navigate to Dashboard
```

**Register**:
```
Name + Email + Password
    ↓ (form validation)
AuthService.register()
    ↓
POST /auth/register
    ↓ (backend creates user)
Token + User ID
    ↓
SharedPreferences
    ↓
Navigate to Dashboard
```

---

## 🛠️ Key Classes & Methods

### Config Class
```dart
import 'lib/config/api_config.dart';

// Get auth headers (includes token if available)
Map<String, String> headers = await Config.getAuthHeaders();

// Save login
await Config.saveAuthToken(token, userId);

// Get token
String? token = await Config.getAuthToken();

// Check if logged in
bool isLoggedIn = await Config.isLoggedIn();

// Logout
await Config.clearAuth();
```

### AuthService Class
```dart
import 'lib/services/auth_service.dart';

// Login
await AuthService.login(email: 'user@example.com', password: 'pass123');

// Register
await AuthService.register(name: 'John', email: 'john@example.com', password: 'pass123');

// Forgot password
await AuthService.forgotPassword(email: 'user@example.com');

// Logout
await AuthService.logout();

// Check login status
bool isLoggedIn = await AuthService.isLoggedIn();
```

### Generic API Call (for other steps)
```dart
import 'lib/config/api_config.dart';

// GET request
var response = await apiCall('GET', '/child/all');

// POST request
var response = await apiCall('POST', '/child/add', body: {'name': 'Emma', 'age': 8});

// PUT request
var response = await apiCall('PUT', '/child/update/123', body: {'name': 'Emma Updated'});

// DELETE request
var response = await apiCall('DELETE', '/child/delete/123');
```

---

## ✅ Validation Rules Implemented

### Email Validation
```regex
^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$
```
Examples:
- ✅ `test@example.com`
- ✅ `john.doe@company.co.uk`
- ❌ `notanemail`
- ❌ `test@`

### Password Validation
- Minimum 6 characters
- Must match confirmation password (on register)

### Name Validation
- Minimum 2 characters
- Required field

---

## 🚨 Error Messages & Handling

### Login Errors
| Error | Cause | Solution |
|---|---|---|
| Invalid email or password | Wrong credentials | Check email/password |
| No internet connection | Device offline | Connect to network |
| Request timeout | Backend slow/down | Check backend |
| Backend unavailable | Connection error | Check URL in config |

### Register Errors
| Error | Cause | Solution |
|---|---|---|
| Email already registered | User exists | Use login instead |
| Invalid request | Bad data | Check form inputs |
| Invalid email format | Wrong format | Fix email format |
| Passwords do not match | Mismatch | Re-enter carefully |

### Password Reset Errors
| Error | Cause | Solution |
|---|---|---|
| Email not found | User doesn't exist | Check email address |
| Request timeout | Slow backend | Try again |

---

## 🔐 Security Checklist

- [x] Passwords validated (min 6 chars)
- [x] Email format validated
- [x] Tokens stored in SharedPreferences
- [x] Authorization header included in requests
- [x] Error messages don't expose sensitive info
- [x] Network timeouts handled (30 seconds)
- [ ] Migrate to secure storage (for production)
- [ ] Enable HTTPS (for production)
- [ ] Add SSL certificate verification (for production)

---

## 🧪 Quick Test Commands

### Test Login
```dart
import 'lib/services/auth_service.dart';

await AuthService.login(
  email: 'test@example.com',
  password: 'password123',
);
// Check SharedPreferences:
// - auth_token: saved
// - user_id: saved
```

### Test Register
```dart
import 'lib/services/auth_service.dart';

await AuthService.register(
  name: 'Test User',
  email: 'newuser@example.com',
  password: 'password123',
);
```

### Test Logout
```dart
import 'lib/services/auth_service.dart';

await AuthService.logout();
// Verify:
// - auth_token: removed
// - user_id: removed
```

---

## 🐛 Common Issues & Fixes

### Issue: "Backend unavailable" indicator
**Fix**: Check backend URL in `api_config.dart`
```dart
static const String apiBaseUrl = 'http://localhost:5000';
// ↑ Update this URL
```

### Issue: Login doesn't navigate to Dashboard
**Fix**: Ensure DashboardPage is imported
```dart
import '../screens/dashboard_page.dart';
```

### Issue: "Invalid email" message on valid email
**Fix**: Backend email regex is different
- Adjust validation in login_form.dart

### Issue: Token not saving
**Fix**: SharedPreferences needs permission
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: Form doesn't show errors
**Fix**: Ensure _formKey.currentState!.validate() is called
```dart
if (_formKey.currentState!.validate()) {
  // Form is valid
}
```

---

## 📱 Device-Specific URLs

### Android Emulator
```dart
static const String apiBaseUrl = 'http://10.0.2.2:5000';
```
(10.0.2.2 is the host machine IP from Android emulator)

### iOS Simulator
```dart
static const String apiBaseUrl = 'http://localhost:5000';
```
(Same as localhost)

### Physical Device
```dart
static const String apiBaseUrl = 'http://192.168.1.100:5000';
```
(Replace with your machine's IP on network)

---

## 🚀 What's Next After Step 1?

Once Step 1 is complete and tested:

1. ✅ Authentication working
2. ✅ Tokens saved
3. ✅ Login/Register functional
4. ↓
5. 📋 Proceed to Step 2: Dashboard Integration

---

## 📞 Support Resources

1. **Setup Guide**: `STEP1_SETUP_GUIDE.md`
2. **Testing Checklist**: `STEP1_TESTING_CHECKLIST.md`
3. **Backend API Docs**: Check `/smartboard-backend/routes/auth_routes.py`
4. **Flutter Docs**: https://flutter.dev/docs
5. **Dart Docs**: https://dart.dev/guides

---

## Key Files at a Glance

| File | Purpose | Status |
|---|---|---|
| `api_config.dart` | API config & helpers | ⭐ NEW |
| `auth_service.dart` | Auth business logic | ⭐ NEW |
| `backend_connection_indicator.dart` | Connection status UI | ⭐ NEW |
| `login_form.dart` | Login UI & logic | ✏️ Updated |
| `register_form.dart` | Register UI & logic | ✏️ Updated |
| `landing_page.dart` | Landing page wrapper | ✏️ Updated |

---

## One-Line Summaries

- **api_config.dart**: Centralized URL & auth headers
- **auth_service.dart**: Login, register, forgot password logic
- **backend_connection_indicator.dart**: Shows if backend is reachable
- **login_form.dart**: Actual login form that calls AuthService
- **register_form.dart**: Actual register form that calls AuthService

---

**🎉 Step 1 Complete!**

Ready to integrate more features? Check the main integration plan for Step 2.

Last Updated: January 2, 2026
