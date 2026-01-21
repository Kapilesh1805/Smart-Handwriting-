import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class EvaluationResultWidget extends StatefulWidget {
  final String childId;
  final String letter;
  final String? imageBase64;
  final String evaluationMode;
  final VoidCallback? onComplete;

  const EvaluationResultWidget({
    super.key,
    required this.childId,
    required this.letter,
    this.imageBase64,
    this.evaluationMode = 'alphabet',
    this.onComplete,
  });

  @override
  State<EvaluationResultWidget> createState() => _EvaluationResultWidgetState();
}

class _EvaluationResultWidgetState extends State<EvaluationResultWidget> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _result;

  int _retryCount = 0;
  final int _maxRetries = 6;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _startEvaluation();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  /// ================= START EVALUATION =================
  Future<void> _startEvaluation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
      _retryCount = 0;
    });

    final success = await _sendEvaluationRequest();
    if (!success) {
      _scheduleRetry();
    }
  }

  /// ================= SEND REQUEST =================
  Future<bool> _sendEvaluationRequest() async {
    try {
      final token = await Config.getAuthToken();
      final mode = widget.evaluationMode.toLowerCase();
      final endpoint =
          mode == 'number' ? '/handwriting/analyze-number' : '/handwriting/analyze';

      final url = '${Config.apiBaseUrl}$endpoint';

      final body = {
        'child_id': widget.childId,
        'meta': {'letter': widget.letter},
        'evaluation_mode': mode,
        if (widget.imageBase64 != null) 'image_b64': widget.imageBase64,
      };

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (!mounted) return true;

        setState(() {
          _result = data;
          _isLoading = false;
          _errorMessage = null;
        });

        widget.onComplete?.call();
        return true;
      }

      if (response.statusCode == 202) {
        if (!mounted) return false;
        setState(() {
          _isLoading = true;
          _errorMessage = '⏳ Preparing engine…';
        });
        return false;
      }

      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      return true;
    }
  }

  /// ================= RETRY HANDLER =================
  void _scheduleRetry() {
    if (_retryCount >= _maxRetries) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Evaluation failed. Please try again.';
      });
      return;
    }

    _retryCount++;

    _retryTimer = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      final success = await _sendEvaluationRequest();
      if (!success) {
        _scheduleRetry();
      }
    });
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_errorMessage != null && _result == null) {
      return _buildError();
    }

    if (_result != null) {
      return _buildResult();
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        CircularProgressIndicator(),
        SizedBox(height: 12),
        Text('Evaluating handwriting…'),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        const Icon(Icons.error, color: Colors.red),
        const SizedBox(height: 8),
        Text(_errorMessage ?? 'Error'),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _startEvaluation,
          child: const Text('Try Again'),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final isCorrect = _result!['is_correct'] == true;

    if (!isCorrect) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEAEA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '❌ Incorrect',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    final confidence = (_result!['confidence'] as num?)?.toDouble();
    final formation = (_result!['formation'] as num?)?.toDouble();
    final pressure = (_result!['pressure'] as num?)?.toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F9EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✅ Correct Letter',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (confidence != null) _score('Accuracy', confidence),
          if (formation != null) _score('Letter Formation', formation),
          if (pressure != null) _score('Pressure', pressure),
        ],
      ),
    );
  }

  Widget _score(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('${value.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}
