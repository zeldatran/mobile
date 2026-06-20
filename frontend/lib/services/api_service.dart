import 'dart:convert';
import 'dart:io';
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
    String? name,
    String? email,
    String? photoUrl,
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
          'name': name,
          'email': email,
          'photoUrl': photoUrl,
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

  static Future<Map<String, dynamic>> changePassword({
    required String accountId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/auth/accounts/$accountId/password');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
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

  static Future<Map<String, dynamic>> getReviewSummary({
    required String productKey,
    required String accountId,
  }) async {
    final encodedKey = Uri.encodeComponent(productKey);
    final url = Uri.parse(
      '$baseUrl/reviews/product/$encodedKey/summary?accountId=$accountId',
    );
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
        'data': {'message': 'NETWORK_ERROR: ${e.toString()}'},
      };
    }
  }

  static Future<Map<String, dynamic>> getReviews(String productKey) async {
    final encodedKey = Uri.encodeComponent(productKey);
    final url = Uri.parse('$baseUrl/reviews/product/$encodedKey');
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
        'data': {'message': 'NETWORK_ERROR: ${e.toString()}'},
      };
    }
  }

  static Future<Map<String, dynamic>> createReview({
    required String productKey,
    required String productName,
    required String accountId,
    required int rating,
    required String comment,
    required List<String> photoUrls,
  }) async {
    final url = Uri.parse('$baseUrl/reviews');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'productKey': productKey,
          'productName': productName,
          'accountId': accountId,
          'rating': rating,
          'comment': comment,
          'photoUrls': photoUrls,
        }),
      );
      final data = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': data};
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'message': 'NETWORK_ERROR: ${e.toString()}'},
      };
    }
  }

  static Future<Map<String, dynamic>> uploadReviewPhoto(File file) async {
    final url = Uri.parse('$baseUrl/reviews/photos');
    try {
      final request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': data};
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'message': 'NETWORK_ERROR: ${e.toString()}'},
      };
    }
  }

  static Future<Map<String, dynamic>> getFavorites(String accountId) async {
    final url = Uri.parse('$baseUrl/favorites/account/$accountId');
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
        'data': {'message': 'NETWORK_ERROR: ${e.toString()}'},
      };
    }
  }

  static Future<Map<String, dynamic>> addFavorite({
    required String accountId,
    required String productKey,
    required String productName,
    required String brand,
    required String image,
    required int price,
    int? oldPrice,
    int? discountPercent,
    required double rating,
    required int reviews,
    required String size,
    required String color,
  }) async {
    final url = Uri.parse('$baseUrl/favorites');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accountId': accountId,
          'productKey': productKey,
          'productName': productName,
          'brand': brand,
          'image': image,
          'price': price,
          'oldPrice': oldPrice,
          'discountPercent': discountPercent,
          'rating': rating,
          'reviews': reviews,
          'size': size,
          'color': color,
        }),
      );
      final data = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': data};
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'message': 'NETWORK_ERROR: ${e.toString()}'},
      };
    }
  }

  static Future<Map<String, dynamic>> removeFavorite({
    required String accountId,
    required String productKey,
  }) async {
    final encodedKey = Uri.encodeComponent(productKey);
    final url = Uri.parse(
      '$baseUrl/favorites/account/$accountId/product/$encodedKey',
    );
    try {
      final response = await http.delete(url);
      return {'statusCode': response.statusCode, 'data': <String, dynamic>{}};
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'message': 'NETWORK_ERROR: ${e.toString()}'},
      };
    }
  }

  static Future<Map<String, dynamic>> getCartItems(String accountId) async {
    final url = Uri.parse('$baseUrl/cart/account/$accountId');
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
        'data': {'message': 'NETWORK_ERROR: ${e.toString()}'},
      };
    }
  }

  static Future<Map<String, dynamic>> addCartItem({
    required String accountId,
    required String productKey,
    required String productName,
    required String brand,
    required String image,
    required int price,
    int? oldPrice,
    int? discountPercent,
    required double rating,
    required int reviews,
    required String size,
    required String color,
    int quantity = 1,
  }) async {
    final url = Uri.parse('$baseUrl/cart/items');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accountId': accountId,
          'productKey': productKey,
          'productName': productName,
          'brand': brand,
          'image': image,
          'price': price,
          'oldPrice': oldPrice,
          'discountPercent': discountPercent,
          'rating': rating,
          'reviews': reviews,
          'size': size,
          'color': color,
          'quantity': quantity,
        }),
      );
      final data = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': data};
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'message': 'NETWORK_ERROR: ${e.toString()}'},
      };
    }
  }
}
