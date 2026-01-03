# Step 1: Authentication Integration - Testing Checklist

## Pre-Testing Requirements

- [ ] Flask backend is running (`python app.py`)
- [ ] Backend accessible at configured URL (check `lib/config/api_config.dart`)
- [ ] Test accounts created in backend database
- [ ] Device/emulator has internet connection
- [ ] Flutter app is running (`flutter run`)

---

## Backend URL Configuration

**Current Configuration**: 
- File: `lib/config/api_config.dart`
- Key: `static const String apiBaseUrl`
- **UPDATE THIS TO YOUR BACKEND URL BEFORE TESTING**

Examples:
```
http://localhost:5000              # Local backend
http://192.168.1.100:5000          # Remote machine
http://10.0.2.2:5000               # Android emulator
http://127.0.0.1:5000              # iOS simulator
```

---

## Test Case 1: Backend Connection Indicator

### Expected Behavior
- [  ] Green indicator appears on landing page if backend is reachable
- [  ] Red indicator appears if backend is unavailable
- [  ] Message shows "Backend connected" or "Backend unavailable"
- [  ] Backend URL is displayed for reference

### Steps
1. Start Flutter app
2. Wait 2-3 seconds for connection check
3. Observe indicator at top of page

---

## Test Case 2: Login - Valid Credentials

### Setup
- Ensure test user exists in backend database
- Example: email: `test@example.com`, password: `password123`

### Expected Behavior
- [  ] Form validation passes
- [  ] Loading spinner shows for 1-2 seconds
- [  ] Navigates to DashboardPage
- [  ] Token saved to SharedPreferences
- [  ] User ID saved to SharedPreferences

### Steps
1. Click on "Login" tab (if on register)
2. Enter valid email: `test@example.com`
3. Enter valid password: `password123`
4. Click "LOGIN" button
5. Wait for navigation
6. Verify you're on Dashboard

### Troubleshooting
- If error shows: Check backend database for user
- If navigation fails: Check DashboardPage import
- If spinner doesn't show: Check `_isLoading` state

---

## Test Case 3: Login - Invalid Credentials

### Expected Behavior
- [  ] Form validation passes
- [  ] Loading spinner shows
- [  ] Error message appears: "Invalid email or password"
- [  ] Error box is red/orange colored
- [  ] User stays on login form

### Steps
1. Enter email: `test@example.com`
2. Enter password: `wrongpassword`
3. Click "LOGIN" button
4. Observe error message

---

## Test Case 4: Login - Invalid Email Format

### Expected Behavior
- [  ] Form validation fails before sending request
- [  ] Error message: "Please enter a valid email"
- [  ] No HTTP request is made
- [  ] LOGIN button is disabled until valid email

### Steps
1. Enter email: `notanemail`
2. Click "LOGIN" button
3. See validation error below email field

---

## Test Case 5: Login - Empty Fields

### Expected Behavior
- [  ] Form validation fails
- [  ] Error messages: "Please enter your email" and "Please enter your password"
- [  ] No HTTP request is made

### Steps
1. Leave both fields empty
2. Click "LOGIN" button
3. See validation errors

---

## Test Case 6: Login - Network Error

### Expected Behavior
- [  ] Error message: "No internet connection. Please check your network."
- [  ] Error persists until network is restored
- [  ] User can retry

### Steps
1. Disconnect device from internet
2. Try to login
3. See network error message
4. Reconnect internet
5. Try again - should work

---

## Test Case 7: Login - Backend Timeout

### Expected Behavior
- [  ] After 30 seconds, error message: "Request timeout. Please try again."
- [  ] User can retry

### Steps
1. Stop Flask backend server (don't restart)
2. Try to login
3. Wait 30 seconds
4. See timeout error

---

## Test Case 8: Register - Valid Input

### Setup
- Choose a new email not in database
- Example: `newuser@example.com`

### Expected Behavior
- [  ] Form validation passes
- [  ] Loading spinner shows
- [  ] Success message: "Account created successfully! Welcome!"
- [  ] Auto-navigates to DashboardPage after 2 seconds
- [  ] Token saved to SharedPreferences
- [  ] User ID saved to SharedPreferences

### Steps
1. Click "SIGN UP" button or switch to register tab
2. Enter Name: `Test User`
3. Enter Email: `newuser@example.com`
4. Enter Password: `password123`
5. Enter Confirm Password: `password123`
6. Click "CREATE ACCOUNT" button
7. Wait for success message
8. Observe auto-navigation to Dashboard

### Verification
- [  ] New user exists in backend database
- [  ] User can login with these credentials

---

## Test Case 9: Register - Duplicate Email

### Expected Behavior
- [  ] Error message: "Email already registered. Please login instead."
- [  ] User stays on register form

### Steps
1. Go to register tab
2. Enter email: `test@example.com` (existing user)
3. Fill other fields
4. Click "CREATE ACCOUNT"
5. See error message

---

## Test Case 10: Register - Weak Password

### Expected Behavior
- [  ] Form validation fails: "Password must be at least 6 characters"
- [  ] No HTTP request is made
- [  ] User cannot click CREATE ACCOUNT

### Steps
1. Enter password: `123`
2. Click CREATE ACCOUNT
3. See validation error

---

## Test Case 11: Register - Password Mismatch

### Expected Behavior
- [  ] Form validation fails: "Passwords do not match"
- [  ] No HTTP request is made

### Steps
1. Enter Password: `password123`
2. Enter Confirm Password: `password456`
3. Click CREATE ACCOUNT
4. See validation error

---

## Test Case 12: Forgot Password - Valid Email

### Expected Behavior
- [  ] Password reset dialog shows
- [  ] Enter valid email
- [  ] Click "Send Link" button
- [  ] Success message: "Password reset link sent to your email"
- [  ] Dialog closes

### Steps
1. Click "Forgot Password" link (on login form)
2. Enter email: `test@example.com`
3. Click "Send Link"
4. See success message
5. Dialog closes automatically

---

## Test Case 13: Forgot Password - Invalid Email

### Expected Behavior
- [  ] Error message: "Email not found"
- [  ] User can retry

### Steps
1. Click "Forgot Password"
2. Enter email: `nonexistent@example.com`
3. Click "Send Link"
4. See error message

---

## Test Case 14: Forgot Password - Empty Email

### Expected Behavior
- [  ] Form validation fails: "Please enter your email"
- [  ] No HTTP request is made

### Steps
1. Click "Forgot Password"
2. Leave email empty
3. Click "Send Link"
4. See validation error

---

## Test Case 15: Remember Me Checkbox (UI Only)

### Expected Behavior
- [  ] Checkbox toggles on/off
- [  ] State persists during session
- [  ] Visual feedback shows when checked

### Steps
1. Click checkbox next to "Remember me"
2. Checkbox fills with checkmark
3. Click again to uncheck
4. Checkbox empties

**Note**: Backend functionality for "Remember me" not implemented in this step

---

## Test Case 16: Password Visibility Toggle

### Expected Behavior
- [  ] Eye icon toggles password visibility
- [  ] Password shows as dots when hidden
- [  ] Password shows as text when visible

### Steps
1. Enter password: `password123`
2. Click eye icon
3. See password as plain text
4. Click eye icon again
5. See password as dots

---

## Test Case 17: Error Message Clearing

### Expected Behavior
- [  ] Error message disappears when user modifies form
- [  ] New error appears if validation fails again

### Steps
1. Trigger an error (invalid email, etc.)
2. See error message
3. Fix the field
4. Error clears
5. Try again with different error

---

## Test Case 18: Loading State

### Expected Behavior
- [  ] LOGIN/CREATE ACCOUNT button shows spinner while loading
- [  ] Button is disabled during loading
- [  ] Cannot click button multiple times
- [  ] Spinner disappears when done

### Steps
1. Start login/register
2. See circular spinner in button
3. Try clicking button again - should be disabled
4. Wait for response
5. Spinner disappears

---

## Test Case 19: Responsive Design - Mobile

### Expected Behavior
- [  ] Page is vertically stacked on mobile (width < 800)
- [  ] Auth card is centered
- [  ] Left panel (branding) appears below
- [  ] All elements are readable
- [  ] Connection indicator fits on screen

### Steps
1. Run on mobile device or phone-sized emulator
2. Verify layout is stacked vertically
3. Test login/register on mobile
4. Verify all text is readable

---

## Test Case 20: Responsive Design - Desktop

### Expected Behavior
- [  ] Page is side-by-side on desktop (width >= 800)
- [  ] Auth card on left, branding on right
- [  ] Connection indicator at top
- [  ] Both panels are equally sized

### Steps
1. Run on desktop or large tablet
2. Verify layout is side-by-side
3. Test login/register on desktop
4. Resize window - layout should adapt

---

## Post-Testing Checklist

After all tests pass:

- [ ] Backend token is stored properly
- [ ] User ID is stored properly
- [ ] No sensitive data logged to console
- [ ] No SSL certificate warnings (if HTTPS)
- [ ] App doesn't crash on any error
- [ ] All error messages are user-friendly
- [ ] Loading states work correctly
- [ ] Navigation works smoothly
- [ ] Back button behavior is correct
- [ ] No memory leaks (check flutter devtools)

---

## Known Issues & Limitations

### Current Step 1 Scope
- ✅ Login with email/password
- ✅ Register new account
- ✅ Forgot password (email-based)
- ✅ Token storage
- ✅ Error handling
- ❌ Two-factor authentication (not implemented)
- ❌ Social login (not implemented)
- ❌ Remember me functionality (UI only, backend not implemented)
- ❌ Password reset link validation (backend skeleton)

### Security Notes
- Tokens stored in SharedPreferences (use secure storage for production)
- HTTP allowed in development (use HTTPS for production)
- No SSL certificate verification (add in production)

---

## Debug Tips

### Enable Flutter Debug Mode
```bash
flutter run -v
```

### Check Backend Response
Add this to any error handler:
```dart
print('Status: ${response.statusCode}');
print('Body: ${response.body}');
```

### Verify Token Storage
In debug console:
```dart
import 'package:shared_preferences/shared_preferences.dart';
final prefs = await SharedPreferences.getInstance();
print(prefs.getString('auth_token'));
```

### Check Backend Logs
```bash
# In terminal where Flask is running
# Look for POST /auth/login and /auth/register requests
```

---

## Summary

**Total Test Cases**: 20  
**Estimated Time**: 30-45 minutes  
**Pass Criteria**: All tests pass without errors  

Once all tests pass, Step 1 is complete and you can proceed to Step 2 (Dashboard Integration).

---

**Last Updated**: January 2, 2026
