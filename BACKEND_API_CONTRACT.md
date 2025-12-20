# Backend API Contract - Quick Reference

## Backend Health Check
**Purpose**: Verify backend is running and ready

```
GET /api/health

Response (200 OK):
Any response with 200 status code
```

---

## Handwriting Recognition Endpoint

**Purpose**: Analyze handwritten character with ML model and return confidence + pressure analysis

```
POST /api/recognize-handwriting
Content-Type: application/json

Request Body:
{
  "character": "A",                    // Target character to recognize
  "strokes": [                         // Array of drawing strokes
    {
      "points": [                      // Points in the stroke
        {
          "x": 150.5,                  // X coordinate
          "y": 200.0,                  // Y coordinate
          "pressure": 85.0             // Pressure (0-100)
        },
        // ... more points
      ],
      "color": "#0000FF"               // Hex color of stroke
    }
    // ... more strokes
  ],
  "pressurePoints": [                  // Detailed pressure analysis
    {
      "x": 150.5,
      "y": 200.0,
      "pressure": 85.0,
      "timestamp": 0
    }
    // ... more pressure points
  ],
  "timestamp": "2024-12-18T10:30:00.000Z"  // ISO 8601 timestamp
}

Response (200 OK):
{
  "confidence": 0.95,                          // 0.0 to 1.0 (0-100%)
  "recognized_character": "A",                 // Recognized character
  "suggestions": [                             // Array of improvement tips
    "Keep the letter straight",
    "Make the crossbar more centered",
    "Increase pressure for stability"
  ],
  "pressureAnalysis": [                        // Pressure analysis data
    {
      "region": "top_stroke",
      "avgPressure": 80,
      "feedback": "Good pressure control"
    }
  ]
}
```

---

## Pre-Writing Assessment Endpoint

**Purpose**: Analyze pre-writing shape with focus on accuracy, completion, and motor control

```
POST /api/pre-writing-assessment
Content-Type: application/json

Request Body:
{
  "shapeType": "circle",                 // Shape type: circle, lines, curves, zigzag, triangle, square
  "shapeName": "Circle",                 // Human-readable shape name
  "drawingData": [                        // Canvas drawing data (structure depends on backend)
    // ... drawing points/strokes
  ],
  "pressurePoints": [                    // Pressure analysis data
    {
      "x": 200.0,
      "y": 150.0,
      "pressure": 75.0,
      "timestamp": 0
    }
    // ... more pressure points
  ],
  "timestamp": "2024-12-18T10:30:00.000Z"  // ISO 8601 timestamp
}

Response (200 OK):
{
  "accuracy": 0.85,                           // 0.0 to 1.0 (how well the shape matches target)
  "completion": 0.95,                         // 0.0 to 1.0 (how complete the shape is)
  "suggestions": [                            // Array of improvement tips (up to 4)
    "Try to keep the circle more round",
    "Draw with consistent pressure",
    "Reduce the wobble at the edges",
    "Practice starting from the top"
  ],
  "pressure_analysis": "Consistent pressure with good control throughout",  // Pressure feedback
  "control_analysis": "Smooth movements, minor wobble at corners"           // Motor control feedback
}
```

---

## Expected Frontend Behavior

### Handwriting Interface - When Backend Connected ✅
1. Extract strokes from drawing canvas
2. Calculate pressure from stroke width
3. POST to `/api/recognize-handwriting`
4. Display confidence score (e.g., "92% match")
5. Show suggestions
6. Show pressure analysis

### Handwriting Interface - When Backend Down ❌
1. Show message: "🔌 Backend not connected!"
2. Show: "Please ensure the backend server is running at http://localhost:8000"
3. Show: "Note: Running local character analysis instead."
4. Orange warning snackbar: "⚠️ Backend unavailable - using local analysis"

### Pre-Writing Interface - When Backend Connected ✅
1. Extract drawing data from canvas
2. Calculate pressure points
3. POST to `/api/pre-writing-assessment`
4. Display accuracy % and completion %
5. Show pressure analysis feedback
6. Show motor control feedback
7. Display up to 4 suggestions

### Pre-Writing Interface - When Backend Down ❌
1. Show message: "🔌 Backend not connected!"
2. Show: "Please ensure the backend server is running at http://localhost:8000"
3. Show: "To get AI-powered analysis with pressure points and detailed feedback, start the backend server."
4. Orange warning snackbar: "⚠️ Backend unavailable - AI analysis disabled"

---

## Pressure Point Normalization

Frontend normalizes pressure from stroke width to 0-100 scale:
```
pressure = (strokeWidth / 5.0) * 100

Where:
- 5.0 = default stroke width
- If strokeWidth = 5.0 → pressure = 100
- If strokeWidth = 2.5 → pressure = 50
- If strokeWidth = 1.0 → pressure = 20
```

Backend should denormalize if needed:
```
strokeWidth = (pressure / 100) * 5.0
```

---

## Error Handling

### Frontend Error Handling:
```
Timeout: 3 seconds for health check, 10 seconds for API calls
If timeout or connection refused → Backend considered "not connected"
Show user-friendly message with instructions
```

### Expected HTTP Status Codes:
- **200**: Success
- **400**: Bad request (malformed data)
- **422**: Validation failed (invalid character, etc.)
- **500**: Server error
- **Connection refused**: Backend not running

---

## Data Type Mapping

### JavaScript/Dart → JSON Mapping:
```
double/number → JSON number (0.85)
string → JSON string ("A")
List<T> → JSON array [...]
Map<String, dynamic> → JSON object {...}
DateTime → ISO 8601 string "2024-12-18T10:30:00.000Z"
```

---

## Testing the API Manually

### Using cURL:

**Test Health:**
```bash
curl http://localhost:8000/api/health
```

**Test Handwriting Recognition:**
```bash
curl -X POST http://localhost:8000/api/recognize-handwriting \
  -H "Content-Type: application/json" \
  -d '{
    "character": "A",
    "strokes": [{
      "points": [{"x": 100, "y": 200, "pressure": 85}],
      "color": "#0000FF"
    }],
    "pressurePoints": [{"x": 100, "y": 200, "pressure": 85, "timestamp": 0}],
    "timestamp": "2024-12-18T10:30:00.000Z"
  }'
```

**Test Pre-Writing Assessment:**
```bash
curl -X POST http://localhost:8000/api/pre-writing-assessment \
  -H "Content-Type: application/json" \
  -d '{
    "shapeType": "circle",
    "shapeName": "Circle",
    "drawingData": [],
    "pressurePoints": [],
    "timestamp": "2024-12-18T10:30:00.000Z"
  }'
```

---

## Configuration

Backend URL (hardcoded in frontend):
```dart
http://localhost:8000
```

To change, modify these lines in:
- `lib/sections/writing_interface_section.dart`
- `lib/sections/pre_writing_section.dart`

```dart
// Change this:
Uri.parse('http://localhost:8000/api/health')

// To:
Uri.parse('http://<your-backend-url>:8000/api/health')
```

