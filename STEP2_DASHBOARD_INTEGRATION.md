# STEP 2: Dashboard Integration - Child Management & API Connectivity
**Status:** PLANNING & IMPLEMENTATION  
**Duration:** 4-6 hours  
**Difficulty:** Medium  
**Date:** January 2, 2026

---

## Overview
Step 2 focuses on integrating the Dashboard page with the backend API. This includes:
1. Loading user profile information
2. Listing children associated with the user
3. Creating new child profiles (CRUD)
4. Managing child data in real-time

---

## Architecture

```
Frontend (Flutter)
├── lib/services/child_service.dart (NEW)
│   ├── getChildren()
│   ├── addChild()
│   ├── updateChild()
│   └── deleteChild()
├── lib/screens/dashboard_page.dart (UPDATE)
│   └── Fetch user profile + children on load
└── lib/sections/dashboard_section.dart (UPDATE)
    └── Show child list, add/edit/delete dialogs

Backend (Flask)
├── routes/child_routes.py (EXISTING - needs completion)
│   ├── GET /children (fetch all children for user)
│   ├── POST /children (create new child)
│   ├── PUT /children/<child_id> (update child)
│   └── DELETE /children/<child_id> (delete child)
└── database.py (EXISTING)
    └── children_col collection
```

---

## Task Breakdown

### Task 1: Create Child Service (lib/services/child_service.dart)
**Time:** 30 minutes

#### Methods to Implement:
1. `getChildren(userId)` - Fetch all children for a user
2. `addChild(userId, name, age, notes)` - Create new child
3. `updateChild(childId, name, age, notes)` - Update child info
4. `deleteChild(childId)` - Delete child profile

#### Data Model:
```dart
{
  "child_id": "uuid",
  "user_id": "uuid",
  "name": "John",
  "age": 7,
  "notes": "Struggles with letter formation",
  "created_at": "2026-01-02T20:00:00Z",
  "last_session": "2026-01-02T18:30:00Z"
}
```

#### Error Handling:
- 401: Unauthorized (invalid token)
- 404: Child not found
- 409: Child already exists
- 500: Server error

---

### Task 2: Update Dashboard Page (lib/screens/dashboard_page.dart)
**Time:** 20 minutes

#### Changes:
1. Add `UserProfile` state variable
2. Add `List<Child>` state variable
3. Implement `initState()` to fetch user profile + children
4. Add loading indicator while fetching
5. Pass children list to DashboardSection

#### Code Flow:
```
initState()
  ├── Get stored user_id from SharedPreferences
  ├── Fetch user profile from backend
  ├── Fetch children list from backend
  ├── Handle errors gracefully
  └── Update UI with data
```

---

### Task 3: Update Dashboard Section (lib/sections/dashboard_section.dart)
**Time:** 40 minutes

#### Changes:
1. Accept `UserProfile` and `List<Child>` as parameters
2. Display children list instead of mock data
3. Show "No children" message if list is empty
4. Add/Edit/Delete child functionality
5. Refresh children list after operations

#### UI Components:
- Children list widget (stateful)
- Add child dialog
- Edit child dialog
- Delete confirmation dialog
- Loading indicators
- Error messages

---

### Task 4: Verify Backend Endpoints (smartboard-backend)
**Time:** 20 minutes

#### Required Endpoints:
- `GET /children` - Returns all children for authenticated user
- `POST /children` - Create new child
- `PUT /children/<child_id>` - Update child
- `DELETE /children/<child_id>` - Delete child

#### Expected Responses:

**GET /children (200 OK)**
```json
{
  "msg": "children fetched",
  "children": [
    {
      "child_id": "uuid",
      "name": "John",
      "age": 7,
      "notes": "Notes here",
      "created_at": "2026-01-02T20:00:00Z"
    }
  ]
}
```

**POST /children (201 CREATED)**
```json
{
  "msg": "child created",
  "child_id": "uuid",
  "name": "John",
  "age": 7
}
```

**PUT /children/<child_id> (200 OK)**
```json
{
  "msg": "child updated",
  "child_id": "uuid"
}
```

**DELETE /children/<child_id> (200 OK)**
```json
{
  "msg": "child deleted"
}
```

---

## Implementation Order

**Phase 1: Backend Setup (20 min)**
1. ✅ Verify child_routes.py endpoints exist
2. ✅ Test endpoints manually (curl/Postman)
3. ✅ Fix any issues with database queries

**Phase 2: Frontend Service (30 min)**
4. ✅ Create lib/services/child_service.dart
5. ✅ Implement all 4 methods
6. ✅ Add error handling for all responses
7. ✅ Test service independently

**Phase 3: Dashboard Integration (40 min)**
8. ✅ Update dashboard_page.dart to fetch data
9. ✅ Update dashboard_section.dart to display data
10. ✅ Implement add/edit/delete dialogs
11. ✅ Add loading states and error handling

**Phase 4: Testing (30 min)**
12. ✅ Test child creation
13. ✅ Test child editing
14. ✅ Test child deletion
15. ✅ Test error scenarios
16. ✅ Test on mobile and desktop layouts

---

## Key Implementation Details

### 1. Authentication Header
All child API requests must include JWT token:
```dart
headers: {
  'Authorization': 'Bearer ${token}',
  'Content-Type': 'application/json',
}
```

Token is automatically added via `Config.apiCall()` helper.

### 2. User ID Context
The user_id is needed to:
- Fetch children: Filter by user_id
- Create child: Associate child with user_id
- Update/Delete: Verify ownership before modification

Retrieve from SharedPreferences:
```dart
final userId = await Config.getUserId();
```

### 3. Error Messages
Display user-friendly messages:
- "Unauthorized. Please login again." (401)
- "Child not found." (404)
- "Failed to add child. Please try again." (500)
- "No internet connection." (network error)

### 4. Loading States
Show loading indicators during:
- Initial dashboard load
- Adding child
- Updating child
- Deleting child

Disable buttons while loading to prevent double-submission.

### 5. Validation
Validate before submission:
- Name: Non-empty, min 2 characters
- Age: Valid number, 1-18 range
- Notes: Optional, max 500 characters

---

## Files to Create

### lib/services/child_service.dart (NEW)
- Implements all child CRUD operations
- Uses Config.apiCall() helper for requests
- Comprehensive error handling
- Returns typed responses

---

## Files to Update

### lib/screens/dashboard_page.dart
- Add user profile state
- Add children list state
- Fetch data in initState()
- Handle loading and error states
- Pass data to child widgets

### lib/sections/dashboard_section.dart
- Accept UserProfile and children list as constructor parameters
- Display children in a ListView or DataTable
- Implement add/edit/delete functionality
- Refresh list after each operation

---

## Testing Checklist

### Create Child
- [ ] Can add child with valid data
- [ ] Error message shown for empty name
- [ ] Error message shown for invalid age
- [ ] Loading spinner shows during submission
- [ ] Child appears in list immediately after creation
- [ ] Multiple children can be added

### Update Child
- [ ] Can edit child's name, age, notes
- [ ] Child updates in list after editing
- [ ] Error message shown for invalid data
- [ ] Cannot update to existing child name (if unique constraint)

### Delete Child
- [ ] Can delete child
- [ ] Confirmation dialog shown
- [ ] Child removed from list after deletion
- [ ] Error message shown if deletion fails

### Error Handling
- [ ] Network error displays message
- [ ] 401 error redirects to login
- [ ] 404 error shows "child not found"
- [ ] 500 error shows generic error message

### UI/UX
- [ ] Responsive on mobile (<600px)
- [ ] Responsive on tablet (600-1200px)
- [ ] Responsive on desktop (>1200px)
- [ ] Loading indicators shown
- [ ] No buttons disabled during non-loading
- [ ] Dialogs are dismissible

---

## Success Criteria

✅ **Code Quality**
- All child operations work correctly
- Error handling is comprehensive
- No hardcoded data (all from backend)
- Code follows Flutter best practices
- No null safety warnings

✅ **Functionality**
- Can view all children for logged-in user
- Can add new child profile
- Can edit existing child profile
- Can delete child profile
- All operations persist to database

✅ **User Experience**
- Loading states clear
- Error messages friendly
- Responsive design maintained
- No crashes or exceptions
- Smooth animations/transitions

✅ **Backend Integration**
- Uses correct API endpoints
- Includes JWT token in all requests
- Handles all HTTP status codes
- Validates response data

---

## Next Steps After Step 2

**Step 3: Pre-Writing Integration**
- Implement pre-writing exercise analysis
- Show assessment results on dashboard
- Store pre-writing data

**Step 4: Writing Interface**
- Integrate handwriting capture
- Connect to ML models
- Show real-time feedback

**Step 5+: Advanced Features**
- Reports and analytics
- Session management
- Appointment scheduling

---

## References

**Backend Routes:** `smartboard-backend/routes/child_routes.py`  
**Database Models:** `smartboard-backend/database.py`  
**Frontend Config:** `handwriting_frontend/lib/config/api_config.dart`  
**Auth Service:** `handwriting_frontend/lib/services/auth_service.dart`

---

## Quick Commands

**Test Backend Endpoint (curl):**
```bash
curl -X GET http://localhost:5000/children \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"
```

**Test Add Child (curl):**
```bash
curl -X POST http://localhost:5000/children \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"John","age":7,"notes":"Test"}'
```

---

**Ready to proceed?** Let me know and I'll implement Step 2 code files!
