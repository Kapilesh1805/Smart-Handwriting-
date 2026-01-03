# 🚀 STEP 1: Quick Start in 5 Minutes

## ⚡ TL;DR - Just Want to Get Running?

### 1️⃣ Update Backend URL (30 seconds)
Edit: `lib/config/api_config.dart`

Change line 7 from:
```dart
static const String apiBaseUrl = 'http://localhost:5000';
```

To your backend URL:
```dart
static const String apiBaseUrl = 'http://192.168.1.100:5000';  // Your IP
```

### 2️⃣ Start Backend (30 seconds)
```bash
cd smartboard-backend
python app.py
```
Look for: `Running on http://localhost:5000`

### 3️⃣ Run App (1 minute)
```bash
flutter run
```
Wait for app to load...

### 4️⃣ Test Login (3 minutes)
- See green ✅ indicator at top? Backend is connected!
- Email: `test@example.com`
- Password: `password123`
- Click LOGIN

**Expected**: Navigate to Dashboard ✅

---

## ❓ If It Doesn't Work

### Green indicator is RED 🔴
```
→ Check backend URL in api_config.dart
→ Check if Flask is running
→ Check your IP address
```

### "Invalid credentials" error
```
→ Check if user exists in database
→ Try registering new account instead
```

### "No internet connection"
```
→ Device can't reach backend
→ Check firewall
→ Check network connectivity
```

### Can't navigate to Dashboard
```
→ Check DashboardPage exists
→ Check navigation routing is correct
```

---

## 📚 Need More Help?

| Issue | Read This |
|-------|-----------|
| Need detailed setup | **STEP1_SETUP_GUIDE.md** |
| Want to run tests | **STEP1_TESTING_CHECKLIST.md** |
| Need code examples | **STEP1_QUICK_REFERENCE.md** |
| Full overview | **STEP1_COMPLETE_SUMMARY.md** |

---

## ✅ Success Checklist

- [x] Backend URL updated
- [x] Backend running
- [x] App running
- [x] Green indicator showing
- [x] Can login with test credentials
- [x] Navigate to Dashboard
- [x] Token is saved

**All checked? You're done with Step 1!** 🎉

---

## 🎯 What's Next?

After Step 1 works:
1. ✅ Run through all tests in STEP1_TESTING_CHECKLIST.md (optional but recommended)
2. ✅ Verify token is saved (optional)
3. → Continue to **Step 2: Dashboard Integration**

---

## 💡 Pro Tips

- Save your backend URL somewhere: `http://[your-ip]:5000`
- Keep backend running while developing
- Restart app if backend restarts
- Use green indicator to verify connection

---

**That's it!** Your authentication system is connected. 🚀

For everything else, check the other documentation files.
