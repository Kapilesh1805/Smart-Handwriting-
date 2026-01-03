import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../config/api_config.dart';

class Appointment {
  final String id;
  final String childName;
  final String therapistName;
  final String sessionType;
  final String date;
  final String time;
  final String status;
  final String? createdAt;

  Appointment({
    required this.id,
    required this.childName,
    required this.therapistName,
    required this.sessionType,
    required this.date,
    required this.time,
    required this.status,
    this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['_id'] ?? '',
      childName: json['child_name'] ?? '',
      therapistName: json['therapist_name'] ?? '',
      sessionType: json['session_type'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'],
    );
  }
}

class AppointmentService {
  static Future<List<Appointment>> getAllAppointments() async {
    try {
      final token = await Config.getAuthToken();
      // Token is optional for appointment endpoint
      
      final url = '${Config.apiBaseUrl}/appointment/all';
      print('🔗 Fetching appointments from: $url');
      
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout. Please try again.'),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Decoded data: $data');
        final appointmentsData = data['appointments'] as List?;

        if (appointmentsData == null) {
          print('⚠️ No appointments data in response');
          return [];
        }

        print('📋 Found ${appointmentsData.length} appointments');
        return appointmentsData
            .map((apt) => Appointment.fromJson(apt as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to fetch appointments: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      print('🌐 Network error: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      print('❌ Error fetching appointments: $e');
      rethrow;
    }
  }

  static Future<List<Appointment>> getTodayAppointments() async {
    try {
      final token = await Config.getAuthToken();
      // Token is optional for appointment endpoint
      
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('${Config.apiBaseUrl}/appointment/today'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout. Please try again.'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final appointmentsData = data['appointments'] as List?;

        if (appointmentsData == null) {
          return [];
        }

        return appointmentsData
            .map((apt) => Appointment.fromJson(apt as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to fetch today\'s appointments');
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Appointment> addAppointment({
    required String childName,
    required String therapistName,
    required String sessionType,
    required String date,
    required String time,
  }) async {
    try {
      final token = await Config.getAuthToken();
      if (token == null) {
        throw Exception('Unauthorized. Please login again.');
      }

      if (childName.isEmpty ||
          therapistName.isEmpty ||
          sessionType.isEmpty ||
          date.isEmpty ||
          time.isEmpty) {
        throw Exception('All fields are required');
      }

      final url = '${Config.apiBaseUrl}/appointment/add';
      print('🔗 Adding appointment to: $url');
      print('📝 Data: childName=$childName, therapistName=$therapistName, date=$date, time=$time');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'child_name': childName,
          'therapist_name': therapistName,
          'session_type': sessionType,
          'date': date,
          'time': time,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout. Please try again.'),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Appointment created successfully');
        return Appointment.fromJson(data['data'] as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Invalid request');
      } else {
        throw Exception('Failed to add appointment: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      print('🌐 Socket error: $e');
      throw Exception('Network error: Please check your internet connection.');
    } catch (e) {
      print('❌ Error adding appointment: $e');
      rethrow;
    }
  }

  static Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    try {
      final token = await Config.getAuthToken();
      if (token == null) {
        throw Exception('Unauthorized. Please login again.');
      }

      if (appointmentId.isEmpty) {
        throw Exception('Appointment ID is required');
      }

      final validStatuses = ['pending', 'completed', 'missed'];
      if (!validStatuses.contains(status)) {
        throw Exception('Invalid status. Must be pending, completed, or missed');
      }

      final url = '${Config.apiBaseUrl}/appointment/update_status';
      print('🔗 Updating appointment status at: $url');
      print('📝 Data: appointmentId=$appointmentId, status=$status');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'appointment_id': appointmentId,
          'status': status,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout. Please try again.'),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to update appointment status: ${response.statusCode} - ${response.body}');
      }
      
      print('✅ Appointment status updated successfully');
    } on SocketException catch (e) {
      print('🌐 Socket error: $e');
      throw Exception('Network error: Please check your internet connection.');
    } catch (e) {
      print('❌ Error updating appointment: $e');
      rethrow;
    }
  }

  static Future<void> deleteAppointment(String appointmentId) async {
    try {
      final token = await Config.getAuthToken();
      if (token == null) {
        throw Exception('Unauthorized. Please login again.');
      }

      if (appointmentId.isEmpty) {
        throw Exception('Appointment ID is required');
      }

      final url = '${Config.apiBaseUrl}/appointment/delete/$appointmentId';
      print('🔗 Deleting appointment at: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout. Please try again.'),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete appointment: ${response.statusCode} - ${response.body}');
      }
      
      print('✅ Appointment deleted successfully');
    } on SocketException catch (e) {
      print('🌐 Socket error: $e');
      throw Exception('Network error: Please check your internet connection.');
    } catch (e) {
      print('❌ Error deleting appointment: $e');
      rethrow;
    }
  }
}
