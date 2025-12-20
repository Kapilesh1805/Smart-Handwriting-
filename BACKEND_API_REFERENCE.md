# Backend API Reference Guide

Complete backend API connectivity documentation for the Smart Handwriting Frontend application.

---

## Table of Contents
1. [Health Check Endpoint](#health-check-endpoint)
2. [Writing Interface Endpoints](#writing-interface-endpoints)
3. [Pre-Writing Endpoints](#pre-writing-endpoints)
4. [Sentence Writing Endpoints](#sentence-writing-endpoints)
5. [API Base URL Configuration](#api-base-url-configuration)
6. [Error Handling](#error-handling)

---

## Health Check Endpoint

### Health Status Check

**Purpose:** Verify backend server connectivity

**Endpoint:** `GET /api/health`

**Base URL:** `http://localhost:8000`

**Implementation Locations:**

| File | Line | Function |
|------|------|----------|
| `lib/sections/writing_interface_section.dart` | 137 | `_checkBackendStatus()` |
| `lib/sections/pre_writing_section.dart` | 185 | `_checkBackendStatus()` |
| `lib/sections/sentence_section.dart` | 49 | `_checkBackendStatus()` |
| `handwriting_frontend/lib/sections/writing_interface_section.dart` | 137 | `_checkBackendStatus()` |
| `handwriting_frontend/lib/sections/pre_writing_section.dart` | 185 | `_checkBackendStatus()` |
| `handwriting_frontend/lib/sections/sentence_section.dart` | 49 | `_checkBackendStatus()` |

**Request:**
```dart
final response = await http
    .get(Uri.parse('http://localhost:8000/api/health'))
    .timeout(const Duration(seconds: 3));
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

**Expected Status Code:** `200`

---

## Writing Interface Endpoints

### 1. Recognize Handwriting Character

**Purpose:** Analyze drawn character and provide ML feedback with confidence score

**Endpoint:** `POST /api/recognize-handwriting`

**Implementation Locations:**

| File | Line | Function |
|------|------|----------|
| `lib/sections/writing_interface_section.dart` | 178 | `_checkML()` |
| `handwriting_frontend/lib/sections/writing_interface_section.dart` | 178 | `_checkML()` |

**Request Timeout:** 10 seconds

**Request Body:**
```json
{
  "character": "A",
  "strokes": [
    {
      "points": [
        {"x": 10.5, "y": 20.3, "pressure": 75},
        {"x": 15.2, "y": 25.1, "pressure": 80}
      ],
      "color": "#0066FF"
    }
  ],
  "pressurePoints": [
    {
      "x": 10.5,
      "y": 20.3,
      "pressure": 75,
      "timestamp": 0
    }
  ],
  "timestamp": "2024-01-01T12:00:00Z"
}
```

**Response:**
```json
{
  "confidence": 0.92,
  "isCorrect": true,
  "character": "A",
  "suggestions": [
    "Good stroke flow",
    "Maintain consistency"
  ],
  "pressureAnalysis": {
    "averagePressure": 77.5,
    "pressureVariation": "Good",
    "consistency": "High"
  }
}
```

**Expected Status Code:** `200`

**Error Handling:** See [Error Handling](#error-handling)

---

## Pre-Writing Endpoints

### 1. Load Pre-Writing Shapes

**Purpose:** Fetch available tracing shapes by difficulty level

**Endpoint:** `GET /api/shapes`

**Query Parameters:**
- `difficulty`: `easy` | `medium` | `hard`

**Implementation Locations:**

| File | Line | Function |
|------|------|----------|
| `lib/sections/pre_writing_section.dart` | 241 | `_loadShapes()` |
| `handwriting_frontend/lib/sections/pre_writing_section.dart` | 241 | `_loadShapes()` |

**Request Timeout:** 5 seconds

**Request Example:**
```dart
final response = await http
    .get(Uri.parse('http://localhost:8000/api/shapes?difficulty=easy'))
    .timeout(const Duration(seconds: 5));
```

**Response:**
```json
{
  "shapes": [
    {
      "id": "shape_1",
      "name": "Straight Lines",
      "difficulty": "easy",
      "description": "Trace vertical and horizontal lines",
      "imageUrl": "/images/straight_lines.svg"
    },
    {
      "id": "shape_2",
      "name": "Circles",
      "difficulty": "easy",
      "description": "Trace circular patterns",
      "imageUrl": "/images/circles.svg"
    }
  ]
}
```

**Expected Status Code:** `200`

### 2. Analyze Pre-Writing Shape

**Purpose:** Evaluate traced shape and provide accuracy feedback

**Endpoint:** `POST /api/shape-analysis`

**Implementation Locations:**

| File | Line | Function |
|------|------|----------|
| `lib/sections/pre_writing_section.dart` | 283 | `_checkShape()` |
| `handwriting_frontend/lib/sections/pre_writing_section.dart` | 283 | `_checkShape()` |

**Request Timeout:** 15 seconds

**Request Body:**
```json
{
  "shapeId": "shape_1",
  "drawing": [
    {
      "x": 50,
      "y": 100,
      "pressure": 80,
      "timestamp": 0
    },
    {
      "x": 50,
      "y": 200,
      "pressure": 82,
      "timestamp": 50
    }
  ],
  "timestamp": "2024-01-01T12:00:00Z"
}
```

**Response:**
```json
{
  "shapeId": "shape_1",
  "accuracy": 0.87,
  "completion": 0.95,
  "feedback": "Good shape! Keep the lines straighter.",
  "pressureAnalysis": {
    "averagePressure": 81,
    "consistency": "Good",
    "control": "Excellent"
  },
  "suggestions": [
    "Reduce hand tremor",
    "Maintain consistent speed"
  ]
}
```

**Expected Status Code:** `200`

---

## Sentence Writing Endpoints

### 1. Load Sentences

**Purpose:** Fetch sentences by difficulty level for writing practice

**Endpoint:** `GET /api/sentences`

**Query Parameters:**
- `difficulty`: `easy` | `medium` | `hard`

**Implementation Locations:**

| File | Line | Function |
|------|------|----------|
| `lib/sections/sentence_section.dart` | 76 | `_loadSentences()` |
| `handwriting_frontend/lib/sections/sentence_section.dart` | 76 | `_loadSentences()` |

**Request Timeout:** 5 seconds

**Request Example:**
```dart
final response = await http
    .get(Uri.parse('http://localhost:8000/api/sentences?difficulty=easy'))
    .timeout(const Duration(seconds: 5));
```

**Response:**
```json
{
  "sentences": [
    {
      "id": "sent_1",
      "text": "Hello World",
      "difficulty": "easy",
      "language": "English",
      "wordCount": 2
    },
    {
      "id": "sent_2",
      "text": "The quick brown fox",
      "difficulty": "easy",
      "language": "English",
      "wordCount": 4
    }
  ]
}
```

**Expected Status Code:** `200`

### 2. Analyze Sentence Writing

**Purpose:** Analyze full sentence handwriting with per-letter verification

**Endpoint:** `POST /api/sentence-analysis`

**Implementation Locations:**

| File | Line | Function |
|------|------|----------|
| `lib/sections/sentence_section.dart` | 172 | `_checkSentenceWriting()` |
| `handwriting_frontend/lib/sections/sentence_section.dart` | 172 | `_checkSentenceWriting()` |

**Request Timeout:** 15 seconds

**Request Body:**
```json
{
  "sentence_text": "Hello World",
  "drawing_strokes": [
    {
      "points": [
        {"x": 10.5, "y": 20.3, "pressure": 75},
        {"x": 15.2, "y": 25.1, "pressure": 80}
      ],
      "color": "#0066FF"
    }
  ],
  "pressure_points": [
    {
      "x": 10.5,
      "y": 20.3,
      "pressure": 75,
      "timestamp": 0
    }
  ],
  "timestamp": "2024-01-01T12:00:00Z"
}
```

**Response:**
```json
{
  "sentenceText": "Hello World",
  "overallAccuracy": 0.88,
  "overallCompletion": 0.95,
  "letterVerifications": [
    {
      "letterIndex": 0,
      "expectedLetter": "H",
      "confidence": 0.92,
      "correct": true,
      "pressureAnalysis": {
        "pressure": 78,
        "control": "Good"
      },
      "suggestions": ["Good shape"]
    },
    {
      "letterIndex": 1,
      "expectedLetter": "e",
      "confidence": 0.85,
      "correct": true,
      "pressureAnalysis": {
        "pressure": 76,
        "control": "Good"
      },
      "suggestions": ["Keep consistent size"]
    }
  ],
  "pressureAnalysis": "Average pressure: 77 | Control: Excellent",
  "controlAnalysis": "Hand control is very good",
  "improvementSuggestions": [
    "Work on letter spacing",
    "Maintain consistent baseline"
  ]
}
```

**Expected Status Code:** `200`

---

## API Base URL Configuration

### Current Base URL
```
http://localhost:8000
```

### To Change API Base URL

Replace all occurrences of `http://localhost:8000` with your production URL in these files:

| File | Occurrences |
|------|------------|
| `lib/sections/writing_interface_section.dart` | 2 (lines 137, 178) |
| `lib/sections/pre_writing_section.dart` | 2 (lines 185, 283) |
| `lib/sections/sentence_section.dart` | 3 (lines 49, 76, 172) |
| `handwriting_frontend/lib/sections/writing_interface_section.dart` | 2 (lines 137, 178) |
| `handwriting_frontend/lib/sections/pre_writing_section.dart` | 2 (lines 185, 283) |
| `handwriting_frontend/lib/sections/sentence_section.dart` | 3 (lines 49, 76, 172) |

### Recommended: Create API Constants File

Create `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';
  
  // Health Check
  static const String healthEndpoint = '$baseUrl/api/health';
  static const Duration healthTimeout = Duration(seconds: 3);
  
  // Writing Interface
  static const String recognizeHandwritingEndpoint = '$baseUrl/api/recognize-handwriting';
  static const Duration mlTimeout = Duration(seconds: 10);
  
  // Pre-Writing
  static const String shapesEndpoint = '$baseUrl/api/shapes';
  static const String shapeAnalysisEndpoint = '$baseUrl/api/shape-analysis';
  static const Duration preWritingTimeout = Duration(seconds: 5);
  static const Duration analysisTimeout = Duration(seconds: 15);
  
  // Sentence Writing
  static const String sentencesEndpoint = '$baseUrl/api/sentences';
  static const String sentenceAnalysisEndpoint = '$baseUrl/api/sentence-analysis';
  static const Duration sentenceTimeout = Duration(seconds: 5);
}
```

Then update code to use:
```dart
final response = await http.get(Uri.parse(ApiConfig.healthEndpoint))
    .timeout(ApiConfig.healthTimeout);
```

---

## Error Handling

### Common Error Responses

#### Backend Not Connected
**Status Code:** Connection timeout (not 200)

**Handling:**
```dart
catch (e) {
  setState(() {
    isBackendConnected = false;
    feedbackMessage = '🔌 Backend not connected!\n\nPlease ensure the backend server is running at http://localhost:8000';
    showFeedback = true;
  });
}
```

**Implementation Locations:**
- `lib/sections/writing_interface_section.dart` - Line 214
- `lib/sections/pre_writing_section.dart` - Line 317
- `lib/sections/sentence_section.dart` - Line 229

#### Invalid Request (400)
**Meaning:** Missing or invalid parameters in request

**Response:**
```json
{
  "error": "Invalid parameters",
  "details": "Missing 'character' field"
}
```

#### Server Error (500)
**Meaning:** Backend processing error

**Response:**
```json
{
  "error": "Internal server error",
  "message": "Error processing analysis"
}
```

### Timeout Configuration

| Operation | Timeout | Line | File |
|-----------|---------|------|------|
| Health Check | 3s | 49 | `sentence_section.dart` |
| ML Recognition | 10s | 178 | `writing_interface_section.dart` |
| Load Sentences | 5s | 76 | `sentence_section.dart` |
| Shape Analysis | 15s | 283 | `pre_writing_section.dart` |
| Sentence Analysis | 15s | 172 | `sentence_section.dart` |

---

## Pressure Calculation Formula

Used across all modules:

```dart
double pressure = (strokeWidth / 5.0) * 100;
// Normalizes pressure to 0-100 scale
// Default strokeWidth: 5.0
// Result: 0-100 pressure value
```

**Location:** All drawing implementations use this formula

---

## Testing the Backend Connection

### Quick Test with cURL

```bash
# Test health endpoint
curl http://localhost:8000/api/health

# Test sentences endpoint
curl "http://localhost:8000/api/sentences?difficulty=easy"

# Test shapes endpoint
curl "http://localhost:8000/api/shapes?difficulty=easy"
```

### Flutter Logger Setup

Add to `pubspec.yaml`:
```yaml
dependencies:
  logger: ^2.0.0
```

Use in code:
```dart
import 'package:logger/logger.dart';

final logger = Logger();

logger.i('Health check response: $response');
logger.e('Backend error: $e');
```

---

## Summary Table: All API Endpoints

| Operation | Method | Endpoint | Timeout | File | Line |
|-----------|--------|----------|---------|------|------|
| Health Check | GET | `/api/health` | 3s | `sentence_section.dart` | 49 |
| Recognize Character | POST | `/api/recognize-handwriting` | 10s | `writing_interface_section.dart` | 178 |
| Load Shapes | GET | `/api/shapes?difficulty=` | 5s | `pre_writing_section.dart` | 241 |
| Analyze Shape | POST | `/api/shape-analysis` | 15s | `pre_writing_section.dart` | 283 |
| Load Sentences | GET | `/api/sentences?difficulty=` | 5s | `sentence_section.dart` | 76 |
| Analyze Sentence | POST | `/api/sentence-analysis` | 15s | `sentence_section.dart` | 172 |

---

## Production Deployment Checklist

- [ ] Update `baseUrl` from `http://localhost:8000` to production URL
- [ ] Test all endpoints with production backend
- [ ] Configure proper CORS headers on backend
- [ ] Add API authentication (Bearer token, API key)
- [ ] Implement error logging/monitoring
- [ ] Test timeout values for production latency
- [ ] Add backend URL to environment configuration
- [ ] Document production API credentials securely
- [ ] Test on staging environment first
- [ ] Monitor backend logs during rollout

---

**Last Updated:** December 18, 2025  
**Version:** 1.0  
**Backend Base URL:** `http://localhost:8000`
