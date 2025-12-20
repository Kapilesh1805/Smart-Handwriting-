import 'package:flutter/material.dart';

class Sentence {
  final String id;
  final String text;
  final String difficulty; // easy, medium, hard
  final String language;
  final int wordCount;

  Sentence({
    required this.id,
    required this.text,
    required this.difficulty,
    required this.language,
    required this.wordCount,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) {
    return Sentence(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      difficulty: json['difficulty'] ?? 'easy',
      language: json['language'] ?? 'en',
      wordCount: json['word_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'difficulty': difficulty,
      'language': language,
      'word_count': wordCount,
    };
  }
}

class LetterVerification {
  final int letterIndex;
  final String expectedLetter;
  final double confidence; // 0.0 to 1.0
  final bool correct;
  final String pressureAnalysis;
  final List<String> suggestions;

  LetterVerification({
    required this.letterIndex,
    required this.expectedLetter,
    required this.confidence,
    required this.correct,
    required this.pressureAnalysis,
    required this.suggestions,
  });

  factory LetterVerification.fromJson(Map<String, dynamic> json) {
    return LetterVerification(
      letterIndex: json['letter_index'] ?? 0,
      expectedLetter: json['expected_letter'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      correct: json['correct'] ?? false,
      pressureAnalysis: json['pressure_analysis'] ?? 'Analysis pending',
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'letter_index': letterIndex,
      'expected_letter': expectedLetter,
      'confidence': confidence,
      'correct': correct,
      'pressure_analysis': pressureAnalysis,
      'suggestions': suggestions,
    };
  }
}

class SentenceAnalysisResult {
  final String sentenceText;
  final double overallAccuracy; // 0.0 to 1.0
  final double overallCompletion; // 0.0 to 1.0
  final List<LetterVerification> letterVerifications;
  final String pressureAnalysis;
  final String controlAnalysis;
  final List<String> improvementSuggestions;

  SentenceAnalysisResult({
    required this.sentenceText,
    required this.overallAccuracy,
    required this.overallCompletion,
    required this.letterVerifications,
    required this.pressureAnalysis,
    required this.controlAnalysis,
    required this.improvementSuggestions,
  });

  factory SentenceAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SentenceAnalysisResult(
      sentenceText: json['sentence_text'] ?? '',
      overallAccuracy: (json['overall_accuracy'] ?? 0.0).toDouble(),
      overallCompletion: (json['overall_completion'] ?? 0.0).toDouble(),
      letterVerifications: (json['letter_verifications'] as List?)
              ?.map((v) => LetterVerification.fromJson(v))
              .toList() ??
          [],
      pressureAnalysis: json['pressure_analysis'] ?? 'Analysis pending',
      controlAnalysis: json['control_analysis'] ?? 'Analysis pending',
      improvementSuggestions:
          List<String>.from(json['improvement_suggestions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sentence_text': sentenceText,
      'overall_accuracy': overallAccuracy,
      'overall_completion': overallCompletion,
      'letter_verifications':
          letterVerifications.map((v) => v.toJson()).toList(),
      'pressure_analysis': pressureAnalysis,
      'control_analysis': controlAnalysis,
      'improvement_suggestions': improvementSuggestions,
    };
  }
}

class DrawingPoint {
  final Offset? points;
  final Paint paint;

  DrawingPoint({
    required this.points,
    required this.paint,
  });
}
