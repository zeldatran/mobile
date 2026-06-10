import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 10.0.2.2 is the special IP alias for localhost in the Android emulator.
  // Use your computer's Wi-Fi/LAN IP when running on a physical Android device.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://172.20.10.3:8080/api',
  );

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': normalizedEmail, 'password': password}),
      );

      final data = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': data};
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'success': false, 'message': 'NETWORK_ERROR: ${e.toString()}'},
      };
    }
  }

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/signup');
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': normalizedEmail,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': data};
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'success': false, 'message': 'NETWORK_ERROR: ${e.toString()}'},
      };
    }
  }

  static Future<Map<String, dynamic>> socialLogin(
    String provider,
    String token, {
    bool signUp = false,
  }) async {
    final url = Uri.parse('$baseUrl/auth/social-login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'token': token,
          'signUp': signUp,
        }),
      );

      final data = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': data};
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'success': false, 'message': 'NETWORK_ERROR: ${e.toString()}'},
      };
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/auth/forgot-password');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': data};
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'success': false, 'message': 'NETWORK_ERROR: ${e.toString()}'},
      };
    }
  }

  static Future<Map<String, dynamic>> getProductsByTag(String tagName) async {
    final url = Uri.parse('$baseUrl/products/tag/$tagName');
    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': data};
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'success': false, 'message': 'NETWORK_ERROR: ${e.toString()}'},
      };
    }
  }

  static Future<Map<String, dynamic>> getAllProducts() async {
    final url = Uri.parse('$baseUrl/products');
    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': data};
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'success': false, 'message': 'NETWORK_ERROR: ${e.toString()}'},
      };
    }
  }
}
