# 📊 Backend Connectivity Matrix - Detailed Line Reference

**Generated:** December 20, 2025

---

## 📋 File-by-File Connectivity Map

### 1. `lib/utils/child_service.dart`

| Line Range | Current State | API Ready | Action Required |
|------------|--------------|-----------|-----------------|
| 1-3 | Imports (http commented out) | ❌ No | Uncomment line 2 |
| 4-8 | Constants & API config | ❌ No | Update lines 7-8 |
| 11-32 | `fetchChildren()` method | ⚠️ Partial | Uncomment lines 14-25, delete lines 29-69 |
| 71-103 | `addChild()` method | ⚠️ Partial | Uncomment lines 82-98, delete lines 104-112 |
| 113-150 | `updateChild()` method | ⚠️ Partial | Uncomment API call, delete mock block |
| 151-194 | `deleteChild()` method | ⚠️ Partial | Uncomment API call, delete mock block |

#### Code Changes Needed:
```dart
❌ Line 2: // import 'package:http/http.dart' as http;
✅ Line 2: import 'package:http/http.dart' as http;

❌ Lines 7-8: // static const String baseUrl = '...';
✅ Lines 7-8: static const String baseUrl = 'https://your-api.com/api';
             static const String apiKey = 'YOUR_API_KEY';

Lines 14-25: UNCOMMENT THIS HTTP REQUEST BLOCK
Lines 29-69: DELETE THIS MOCK DATA BLOCK (return [...])

Lines 82-98: UNCOMMENT THIS HTTP REQUEST BLOCK
Lines 104-112: DELETE THIS MOCK RETURN BLOCK

Lines 130-135: UNCOMMENT THIS HTTP REQUEST BLOCK
Lines 138-145: DELETE THIS MOCK RETURN BLOCK

Lines 155-160: UNCOMMENT THIS HTTP REQUEST BLOCK
Lines 163-165: DELETE THIS MOCK WAIT BLOCK
```

---

### 2. `lib/utils/assessment_service.dart`

| Line Range | Current State | API Ready | Action Required |
|------------|--------------|-----------|-----------------|
| 1-3 | Imports (http commented out) | ❌ No | Uncomment line 2 |
| 4-8 | Constants & API config | ❌ No | Update lines 7-8 |
| 11-34 | `fetchAssessmentReport()` | ⚠️ Partial | Uncomment lines 14-30, delete line 31 |
| 36-57 | `fetchAssessmentHistory()` | ⚠️ Partial | Uncomment lines 39-52, delete line 53 |
| 68-151 | `_getMockAssessmentReport()` | ❌ Delete | REMOVE ENTIRE METHOD |

#### Code Changes Needed:
```dart
❌ Line 2: // import 'package:http/http.dart' as http;
✅ Line 2: import 'package:http/http.dart' as http;

❌ Lines 7-8: // static const String baseUrl = '...';
✅ Lines 7-8: static const String baseUrl = 'https://your-api.com/api';
             static const String apiKey = 'YOUR_API_KEY';

Lines 14-30: UNCOMMENT THIS HTTP REQUEST BLOCK (multi-line comment)
Line 31: DELETE "// REMOVE THIS BLOCK AFTER API INTEGRATION - Mock data for testing"
Line 32: DELETE "await Future.delayed(const Duration(milliseconds: 800));"
Line 33: DELETE "return _getMockAssessmentReport(childId);"

Lines 39-52: UNCOMMENT THIS HTTP REQUEST BLOCK (multi-line comment)
Line 53: DELETE "// REMOVE THIS BLOCK AFTER API INTEGRATION"
Line 54: DELETE "await Future.delayed(const Duration(milliseconds: 500));"
Line 55: DELETE "return [_getMockAssessmentReport(childId)];"

Lines 68-151: DELETE ENTIRE METHOD _getMockAssessmentReport()
```

---

### 3. `lib/sections/writing_interface_section.dart`

| Line Range | Current State | API Ready | Status |
|------------|--------------|-----------|--------|
| 1-20 | Imports | ✅ Complete | All needed imports present |
| 40-55 | State variables | ✅ Complete | `isBackendConnected`, `mlConfidenceScore` |
| 115-120 | initState() | ✅ Complete | Calls `_checkBackendStatus()` |
| 137-154 | `_checkBackendStatus()` | ✅ Active | Health check implemented |
| 197-250 | `_checkWriting()` → `_sendToMLModel()` | ✅ Active | Handwriting recognition |
| 281-290 | `_showBackendNotConnectedMessage()` | ✅ Active | Error handling |
| 202-205 | Backend check condition | ✅ Active | Conditional execution |

#### Status: ✅ FULLY WORKING - NO CHANGES NEEDED
```
All APIs implemented and working:
✅ Line 140: Uri.parse('http://localhost:8000/api/health')
✅ Line 222: Uri.parse('http://localhost:8000/api/recognize-handwriting')
✅ Backend status checking active
✅ Error handling implemented
```

#### Only Change Needed (when migrating to production):
```dart
Line 140: Replace 'http://localhost:8000/api/health'
          with ApiConfig.healthEndpoint

Line 222: Replace 'http://localhost:8000/api/recognize-handwriting'
          with ApiConfig.recognizeHandwritingEndpoint
```

---

### 4. `lib/sections/pre_writing_section.dart`

| Line Range | Current State | API Ready | Status |
|------------|--------------|-----------|--------|
| 1-10 | Imports | ✅ Complete | All needed imports present |
| 28-35 | State variables | ✅ Complete | Backend integration vars present |
| 40-45 | initState() | ✅ Complete | Calls `_checkBackendStatus()` |
| 185-200 | `_checkBackendStatus()` | ✅ Active | Health check implemented |
| 229-275 | `_sendToBackend()` | ✅ Active | Shape analysis request |
| 317-325 | `_showBackendNotConnectedMessage()` | ✅ Active | Error handling |

#### Status: ✅ FULLY WORKING - NO CHANGES NEEDED
```
All APIs implemented:
✅ Line 187: Uri.parse('http://localhost:8000/api/health')
✅ Line 283: Uri.parse('http://localhost:8000/api/analyze-pre-writing')
✅ Backend status checking active
✅ Error handling implemented
✅ Feedback messages display correctly
```

#### Only Change Needed (when migrating to production):
```dart
Line 187: Replace 'http://localhost:8000/api/health'
          with ApiConfig.healthEndpoint

Line 283: Replace 'http://localhost:8000/api/analyze-pre-writing'
          with ApiConfig.preWritingAnalysisEndpoint
```

---

### 5. `lib/sections/sentence_section.dart`

| Line Range | Current State | API Ready | Status |
|------------|--------------|-----------|--------|
| 1-10 | Imports | ✅ Complete | All needed imports present |
| 28-45 | State variables | ✅ Complete | Backend integration vars present |
| 48-52 | initState() | ✅ Complete | Calls `_checkBackendStatus()` |
| 74-92 | `_checkBackendStatus()` | ✅ Active | Health check implemented |
| 140-161 | `_loadSentences()` | ✅ Active | Load sentences request |
| 229-278 | `_analyzeSentence()` | ✅ Active | Sentence analysis request |
| 283-293 | `_showBackendNotConnectedMessage()` | ✅ Active | Error handling |

#### Status: ✅ FULLY WORKING - NO CHANGES NEEDED
```
All APIs implemented:
✅ Line 76: Uri.parse('http://localhost:8000/api/health')
✅ Line 145: Uri.parse('http://localhost:8000/api/sentences?difficulty=$selectedDifficulty')
✅ Line 250: Uri.parse('http://localhost:8000/api/sentence-analysis')
✅ All error handling and feedback messages
```

#### Only Change Needed (when migrating to production):
```dart
Line 76: Replace hardcoded URL with ApiConfig.healthEndpoint
Line 145: Replace hardcoded URL with ApiConfig.sentencesEndpoint
Line 250: Replace hardcoded URL with ApiConfig.sentenceAnalysisEndpoint
```

---

### 6. `lib/sections/assessment_report_section.dart`

| Line Range | Current State | API Ready | Status |
|------------|--------------|-----------|--------|
| 1-5 | Imports | ✅ Complete | Services imported |
| 8-12 | Constructor | ✅ Complete | childId optional |
| 28-50 | _loadChildren() | ✅ Active | Uses ChildService |
| 54-72 | _loadAssessmentReport() | ✅ Active | Uses AssessmentService |
| 76-150 | Report display | ✅ Complete | UI building |

#### Status: ✅ FULLY WORKING - NO CHANGES NEEDED
```
Dependencies via services:
✅ Uses ChildService.fetchChildren() (ChildService handles API)
✅ Uses AssessmentService.fetchAssessmentReport() (Service handles API)
✅ Reports display correctly
```

#### No changes needed - works through service layer

---

### 7. `lib/sections/childrens_main.dart`

| Line Range | Current State | API Ready | Status |
|------------|--------------|-----------|--------|
| 1-6 | Imports | ✅ Complete | Services imported |
| 11-17 | State variables | ✅ Complete | Data structures |
| 22-29 | initState() | ✅ Complete | Calls `_fetchChildren()` |
| 31-45 | `_fetchChildren()` | ✅ Active | Uses ChildService |
| 47-120 | Dialog methods | ✅ Complete | Uses ChildService |
| 340-350 | GridView config | ✅ Complete | childAspectRatio = 2.0 |

#### Status: ✅ FULLY WORKING - NO CHANGES NEEDED
```
Dependencies via services:
✅ Uses ChildService.fetchChildren() (Service handles API)
✅ All CRUD operations through ChildService
✅ UI properly displays child data
```

#### No changes needed - works through service layer

---

### 8. `lib/sections/appointment_section.dart`

| Line Range | Current State | API Ready | Action Required |
|------------|--------------|-----------|-----------------|
| 1-12 | Imports | ❌ No | Add lines 16-18 |
| 14-17 | Comments | ⚠️ Partial | Uncomment lines 16-18 |
| 20-22 | initState() | ❌ No | Uncomment `_fetchAppointmentsFromBackend()` |
| 26-45 | Method (commented) | ⚠️ Partial | Uncomment entire method |

#### Code Changes Needed:
```dart
❌ Lines 16-18 are commented:
// import 'dart:convert';
// import 'package:http/http.dart' as http;

✅ Should be:
import 'dart:convert';
import 'package:http/http.dart' as http;

❌ Line 22: // _fetchAppointmentsFromBackend();
✅ Line 22: _fetchAppointmentsFromBackend();

Lines 26-45: UNCOMMENT ENTIRE METHOD
Replace 'YOUR_BACKEND_URL' with actual URL
```

---

### 9. `lib/sections/settings_section.dart`

| Line Range | Current State | API Ready | Action Required |
|------------|--------------|-----------|-----------------|
| 1-6 | Imports | ✅ Complete | All imports present |
| 15-17 | Mock data | ⚠️ Needs replace | Delete and load from API |
| 20-21 | initState() | ❌ No | Uncomment `_loadUserProfile()` call |
| 23-45 | Method (commented) | ⚠️ Partial | Uncomment entire method |

#### Code Changes Needed:
```dart
Lines 15-17: REPLACE with variable declarations:
String userName = '';
String userEmail = '';
String userAvatar = '';

❌ Line 20: // TODO: ADD BACKEND API - Load user profile
✅ Line 20: _loadUserProfile();

Lines 23-45: UNCOMMENT ENTIRE METHOD _loadUserProfile()
Replace 'YOUR_API_URL' with actual URL
Replace 'YOUR_TOKEN' with token retrieval
```

---

### 10. `lib/screens/dashboard_page.dart`

| Line Range | Current State | API Ready | Action Required |
|------------|--------------|-----------|-----------------|
| 1-14 | Imports | ✅ Complete | All imports present |
| 27 | TODO comment | ⚠️ Partial | Add state variable |
| 31 | TODO comment | ⚠️ Partial | Uncomment method call |
| 35-59 | Method (commented) | ⚠️ Partial | Uncomment entire method |
| 130 | TODO comment | ⚠️ Partial | Update to use _currentUser |

#### Code Changes Needed:
```dart
❌ Line 27: // TODO: API INTEGRATION - Add user profile state variable
✅ Line 27: UserProfile? _currentUser;

❌ Line 31: // TODO: API INTEGRATION - Fetch user profile when dashboard loads
✅ Line 31: _fetchUserProfile();

Lines 35-59: UNCOMMENT ENTIRE METHOD _fetchUserProfile()
Replace 'YOUR_BACKEND_URL' and 'YOUR_API_KEY' with actual values

❌ Line 130: // TODO: API INTEGRATION - Replace widget.user with _currentUser
✅ Line 130: Use _currentUser instead of widget.user
```

---

### 11. `lib/widgets/drawing_canvas.dart`

| Line Range | Current State | API Ready | Action Required |
|------------|--------------|-----------|-----------------|
| 33 | TODO comment | ❌ No | Implement drawing-start API |
| 37 | TODO comment | ❌ No | Implement drawing-start logging |
| 41-60 | Method (commented) | ❌ No | Uncomment when ready |
| 74 | TODO comment | ❌ No | Implement auto-save |
| 78 | TODO comment | ❌ No | Implement progress tracking |
| 82-100 | Method (commented) | ❌ No | Uncomment when ready |
| 111 | TODO comment | ❌ No | Implement getDrawingData() |

#### Code Changes Needed:
```dart
Lines 33-65: Uncomment drawing-start implementation when needed
Lines 74-105: Uncomment auto-save implementation when needed
Lines 111+: Implement getDrawingData() method for serialization

Priority: LOW (Nice-to-have feature)
```

---

### 12. Widget Files (No Changes Needed)

Files without backend integration:
```
✅ appointment_widgets.dart - UI only
✅ auth_card.dart - UI only
✅ child_card.dart - UI only
✅ common_widgets.dart - UI utilities
✅ drawing_canvas_widget.dart - Drawing UI
✅ drawing_tools_widget.dart - Tools UI
✅ left_panel.dart - Navigation UI
✅ login_form.dart - Form UI
✅ register_form.dart - Form UI
✅ placeholder_pages.dart - Placeholder screens
✅ right_panel.dart - Schedule UI
✅ settings_list_tile.dart - Settings UI
✅ shape_pattern_display.dart - Pattern UI
✅ shape_selector.dart - Shape UI
✅ sidebar.dart - Navigation UI
✅ theme_toggle.dart - Theme UI
✅ topbar.dart - Top bar UI
✅ unified_writing_canvas.dart - Canvas UI
```

---

## 🎯 Priority Order for Implementation

### Phase 1: CRITICAL (Day 1)
1. **child_service.dart**
   - Lines 2, 7-8: Update imports and constants
   - Lines 14-25: Uncomment fetchChildren() API call
   - Lines 29-69: Delete mock data block
   - Repeat for add/update/delete methods

2. **assessment_service.dart**
   - Lines 2, 7-8: Update imports and constants
   - Lines 14-30: Uncomment API call
   - Lines 31-34: Delete mock code
   - Repeat for other methods
   - Lines 68-151: Delete entire `_getMockAssessmentReport()` method

### Phase 2: READY (Day 1-2)
3. **Verify 5 sections are working**
   - ✅ writing_interface_section.dart
   - ✅ pre_writing_section.dart
   - ✅ sentence_section.dart
   - ✅ assessment_report_section.dart
   - ✅ childrens_main.dart

### Phase 3: IMPLEMENT (Day 2-3)
4. **appointment_section.dart**
   - Lines 16-18: Uncomment imports
   - Line 22: Uncomment method call
   - Lines 26-45: Uncomment method

5. **settings_section.dart**
   - Lines 15-17: Replace mock data
   - Line 20: Uncomment method call
   - Lines 23-45: Uncomment method

6. **dashboard_page.dart**
   - Line 27: Add state variable
   - Line 31: Uncomment method call
   - Lines 35-59: Uncomment method
   - Line 130: Update UI reference

### Phase 4: ENHANCE (Future)
7. **drawing_canvas.dart**
   - Lines 33-65: Implement drawing-start
   - Lines 74-105: Implement auto-save
   - Lines 111+: Implement data extraction

---

## ✅ Verification Checklist

After each phase, verify:

- [ ] Code compiles without errors
- [ ] No import errors
- [ ] Backend endpoints match your API
- [ ] Authentication headers added
- [ ] Error handling in place
- [ ] Mock data removed
- [ ] Timeouts appropriate for endpoints
- [ ] Logging shows API calls
- [ ] UI displays data correctly
- [ ] No breaking changes to existing features

---

**Last Updated:** December 20, 2025  
**Purpose:** Detailed line-by-line reference for backend integration  
**Companion:** BACKEND_CONNECTIVITY_AUDIT.md (full details)

