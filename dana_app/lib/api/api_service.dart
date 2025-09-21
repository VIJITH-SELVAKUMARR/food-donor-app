// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000/api";

  /// 🔹 Always attach Firebase ID token automatically
  static Future<Map<String, String>> _getAuthHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();

    final headers = <String, String>{
      "Content-Type": "application/json",
    };

    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  /// Secure GET
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final url = Uri.parse("$baseUrl/$endpoint");
    print("📡 GET $url");

    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("❌ GET $endpoint failed: ${response.statusCode}");
    }
  }

  /// Secure POST
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse("$baseUrl/$endpoint");
    print("📡 POST $url");

    final headers = await _getAuthHeaders();
    final response = await http.post(url, headers: headers, body: json.encode(body));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception("❌ POST $endpoint failed: ${response.statusCode}");
    }
  }

  static Future<Map<String, dynamic>> syncUser(
    String token, String userType, String phone, String address) async {
  final response = await http.post(
    Uri.parse("$baseUrl/auth/sync/"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "user_type": userType,
      "phone_number": phone,
      "address": address,
    }),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception("Failed to sync user: ${response.statusCode}");
  }
}


  static Future secureHealthCheck(String token) async {}

  static Future healthCheck() async {}
}
