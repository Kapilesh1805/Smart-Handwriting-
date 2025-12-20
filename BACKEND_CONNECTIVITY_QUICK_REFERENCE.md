# 🎯 Backend Connectivity Quick Reference Guide

**Generated:** December 20, 2025

---

## 📌 At a Glance

| Status | Files | Count |
|--------|-------|-------|
| ✅ **Production Ready** | writing_interface_section, pre_writing_section, sentence_section, assessment_report_section, childrens_main | 5 |
| ⚠️ **Needs Setup** | child_service, assessment_service, appointment_section, settings_section, dashboard_page | 5 |
| 🔲 **No Backend** | All other files | 26+ |

---

## 🔑 Key Files & What They Do

### 1️⃣ **child_service.dart** → `lib/utils/`
```
Purpose: Manage child profiles
Current: Uses 4 sample children
Status: Ready for API, just uncomment!

API Endpoint: GET /api/children (with POST, PUT, DELETE)
Mock Data: Emma, Giri, Rohan, Priya (Lines 29-69)
TODO: Replace mock with real API calls
```

### 2️⃣ **assessment_service.dart** → `lib/utils/`
```
Purpose: Load assessment reports
Current: Uses mock assessment data
Status: Ready for API, just uncomment!

API Endpoint: GET /api/assessments/{childId}/latest
Mock Method: _getMockAssessmentReport() (Line 68)
TODO: Remove mock data method, uncomment API calls
```

### 3️⃣ **writing_interface_section.dart** → `lib/sections/`
```
Purpose: Letter/Number writing practice
Current: ✅ FULLY WORKING
Status: Active API integration

APIs Used:
  - GET /api/health (Line 140)
  - POST /api/recognize-handwriting (Line 222)
Backend Check: Yes (Line 137)
```

### 4️⃣ **pre_writing_section.dart** → `lib/sections/`
```
Purpose: Shape-based pre-writing practice
Current: ✅ FULLY WORKING
Status: Active API integration

APIs Used:
  - GET /api/health (Line 187)
  - POST /api/analyze-pre-writing (Line 283)
Backend Check: Yes (Line 185)
```

### 5️⃣ **sentence_section.dart** → `lib/sections/`
```
Purpose: Sentence writing practice
Current: ✅ FULLY WORKING
Status: Active API integration

APIs Used:
  - GET /api/health (Line 76)
  - GET /api/sentences (Line 145)
  - POST /api/sentence-analysis (Line 250)
Backend Check: Yes (Line 74)
```

### 6️⃣ **assessment_report_section.dart** → `lib/sections/`
```
Purpose: Display assessment reports
Current: ✅ FULLY WORKING
Status: Active integration with services

Services Used:
  - ChildService.fetchChildren()
  - AssessmentService.fetchAssessmentReport()
Backend Check: Via services
```

### 7️⃣ **appointment_section.dart** → `lib/sections/`
```
Purpose: Manage appointments
Current: ⚠️ TODO comments only
Status: Not implemented yet

API Needed: GET /api/appointments?date=...
Action: Uncomment lines 20-45 and implement
```

### 8️⃣ **settings_section.dart** → `lib/sections/`
```
Purpose: User settings & profile
Current: ⚠️ Mock data + TODO
Status: Partially ready

Mock Data (Lines 15-17):
  - userName = 'Allen Vijay'
  - userEmail = 'Allenvijay@gmail.com'
  - userAvatar = '...'

Action: Uncomment _loadUserProfile() method (Lines 23-44)
API Needed: GET /api/user/profile
```

### 9️⃣ **dashboard_page.dart** → `lib/screens/`
```
Purpose: Main dashboard container
Current: ⚠️ TODO comments only
Status: Not implemented yet

Action: Uncomment _fetchUserProfile() (Lines 35-59)
API Needed: GET /api/user/profile
```

---

## 🚀 Quick Start: Production Setup

### Step 1: Update Service Files (15 minutes)

**File: `lib/utils/child_service.dart`**
```dart
// 1. Uncomment line 2:
import 'package:http/http.dart' as http;

// 2. Update lines 7-8 with your backend:
static const String baseUrl = 'https://your-backend.com/api';
static const String apiKey = 'YOUR_API_KEY';

// 3. In fetchChildren() method:
// - Uncomment the http.get() call (lines 14-25)
// - Delete the mock data block (lines 29-69)
// - Keep the closing brace and error handling

// 4. Repeat for addChild(), updateChild(), deleteChild()
```

**File: `lib/utils/assessment_service.dart`**
```dart
// 1. Uncomment line 2:
import 'package:http/http.dart' as http;

// 2. Update lines 7-8 with your backend:
static const String baseUrl = 'https://your-backend.com/api';
static const String apiKey = 'YOUR_API_KEY';

// 3. Uncomment all http requests in methods
// 4. Delete mock data blocks and _getMockAssessmentReport() method
```

### Step 2: Create API Config File (5 minutes)

**Create: `lib/config/api_config.dart`**
```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';
  static const String healthEndpoint = '$baseUrl/api/health';
  static const String childrenEndpoint = '$baseUrl/api/children';
  // ... more endpoints
}
```

### Step 3: Test Each Section (30 minutes)

1. ✅ writing_interface_section - Should already work
2. ✅ pre_writing_section - Should already work
3. ✅ sentence_section - Should already work
4. ⚠️ appointment_section - Uncomment and test
5. ⚠️ settings_section - Uncomment and test

---

## 🔍 What Needs Removal

### In `child_service.dart`:
```dart
// Lines 29-69: REMOVE THIS ENTIRE BLOCK
return [
  ChildProfile(id: 'child_001', name: 'Emma', ...),
  ChildProfile(id: 'child_002', name: 'Giri', ...),
  ChildProfile(id: 'child_003', name: 'Rohan', ...),
  ChildProfile(id: 'child_004', name: 'Priya', ...),
];
// Replace with your uncommented API call
```

### In `assessment_service.dart`:
```dart
// Line 68: REMOVE THIS METHOD
static AssessmentReport _getMockAssessmentReport(String childId) { ... }

// Line 31: Delete "// REMOVE THIS BLOCK AFTER API INTEGRATION" comment
// Line 52: Delete "// REMOVE THIS BLOCK AFTER API INTEGRATION" comment
```

---

## 📍 API Endpoints Summary

| Endpoint | Method | File | Line | Purpose |
|----------|--------|------|------|---------|
| `/api/health` | GET | writing_interface_section | 140 | Check backend online |
| `/api/children` | GET | child_service | 14 | Fetch all children |
| `/api/children` | POST | child_service | 88 | Add new child |
| `/api/children/{id}` | PUT | child_service | 120 | Update child |
| `/api/children/{id}` | DELETE | child_service | 135 | Delete child |
| `/api/recognize-handwriting` | POST | writing_interface_section | 222 | Analyze handwriting |
| `/api/sentences` | GET | sentence_section | 145 | Load sentences |
| `/api/sentence-analysis` | POST | sentence_section | 250 | Analyze sentence |
| `/api/analyze-pre-writing` | POST | pre_writing_section | 283 | Analyze shape |
| `/api/assessments/{childId}/latest` | GET | assessment_service | 18 | Get latest assessment |
| `/api/assessments/{childId}/history` | GET | assessment_service | 44 | Get all assessments |
| `/api/appointments` | GET | appointment_section | 26 | Fetch appointments |
| `/api/user/profile` | GET | settings_section | 35 | Load user profile |
| `/api/user/profile` | GET | dashboard_page | 39 | Load user profile |

---

## 🎯 Action Items by Priority

### 🔴 HIGH (Before First Release)
- [ ] Set up `ApiConfig.dart`
- [ ] Update `child_service.dart` with real API
- [ ] Update `assessment_service.dart` with real API
- [ ] Test all 5 active sections
- [ ] Implement authentication tokens

### 🟠 MEDIUM (First Release)
- [ ] Implement `appointment_section.dart`
- [ ] Implement `settings_section.dart`
- [ ] Implement `dashboard_page.dart`
- [ ] Add error logging
- [ ] Add retry logic

### 🟡 LOW (Future Releases)
- [ ] Implement canvas auto-save
- [ ] Add offline caching
- [ ] Implement real-time updates
- [ ] Add analytics

---

## 💾 Backend Integration Checklist

### Services
- [ ] `child_service.dart` - API ready
- [ ] `assessment_service.dart` - API ready
- [ ] Drawing service - Not needed (local only)
- [ ] Theme service - Not needed (local only)

### Sections
- [ ] `writing_interface_section.dart` - ✅ Ready
- [ ] `pre_writing_section.dart` - ✅ Ready
- [ ] `sentence_section.dart` - ✅ Ready
- [ ] `assessment_report_section.dart` - ✅ Ready
- [ ] `childrens_main.dart` - ✅ Ready
- [ ] `appointment_section.dart` - 🚧 Needs uncomment
- [ ] `settings_section.dart` - 🚧 Needs uncomment
- [ ] `dashboard_section.dart` - ❌ Not needed

### Screens
- [ ] `dashboard_page.dart` - 🚧 Needs uncomment

---

## 🔐 Authentication Notes

All endpoints need authorization headers:
```dart
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $accessToken',
}
```

**Not yet implemented!** You need to:
1. Create authentication service
2. Store tokens securely
3. Add token to all requests
4. Handle token refresh
5. Handle 401 responses

---

## 📞 Contact Backend Team

Share these specs:
- All requests use JSON
- Health check: returns 200 if healthy
- Timestamps: ISO 8601 format
- Child data: See `ChildProfile` model
- Assessment data: See `AssessmentReport` model
- Pressure values: 0-100 normalized scale
- Timeouts: See `ApiConfig` (3-15 seconds per endpoint)

---

## 🆘 Troubleshooting

### Backend Not Connecting?
- Check if server running at `http://localhost:8000`
- Check if `/api/health` responds with 200
- Check network connectivity
- Check CORS settings on backend

### Mock Data Still Showing?
- Make sure you removed the REMOVE blocks
- Check no API request errors in logs
- Verify backend response structure matches model

### Timeouts?
- Increase timeout values in `ApiConfig`
- Check backend performance
- Check network latency

---

**Last Updated:** December 20, 2025  
**Document Purpose:** Quick reference for backend integration  
**Next Step:** Read BACKEND_CONNECTIVITY_AUDIT.md for full details

