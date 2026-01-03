import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;

class BackendConnectionIndicator extends StatefulWidget {
  const BackendConnectionIndicator({super.key});

  @override
  State<BackendConnectionIndicator> createState() =>
      _BackendConnectionIndicatorState();
}

class _BackendConnectionIndicatorState extends State<BackendConnectionIndicator> {
  bool _isConnected = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkBackendConnection();
  }

  Future<void> _checkBackendConnection() async {
    try {
      final response = await http
          .get(Uri.parse('${Config.apiBaseUrl}/'))
          .timeout(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _isConnected = response.statusCode == 200;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const SizedBox.shrink();
    }

    if (!_isConnected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          border: Border.all(color: Colors.orange[400]!),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber, color: Colors.orange[700], size: 16),
            const SizedBox(width: 8.0),
            Text(
              'Backend unavailable (${Config.apiBaseUrl})',
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.green[100],
        border: Border.all(color: Colors.green[400]!),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: 16),
          const SizedBox(width: 8.0),
          Text(
            'Backend connected',
            style: TextStyle(
              color: Colors.green[800],
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
