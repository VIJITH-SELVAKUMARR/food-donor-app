// api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// ✅ Single source of truth for API configuration
class ApiConfig {
  /// Change this depending on where your backend is running:
  /// - Android emulator → http://10.0.2.2:8000
  /// - iOS simulator → http://127.0.0.1:8000
  /// - Physical device → http://<your-local-IP>:8000
  /// - Deployed server → https://yourdomain.com
  static const String baseUrl = "http://10.0.2.2:8000";
}

class ApiService {
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

  /// ✅ Generic GET method
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/$endpoint");
    print("📡 GET $url");

    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("❌ GET $endpoint failed: ${response.statusCode}");
    }
  }

  /// ✅ Generic POST method
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/$endpoint");
    print("📡 POST $url");

    final headers = await _getAuthHeaders();
    final response =
        await http.post(url, headers: headers, body: json.encode(body));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception("❌ POST $endpoint failed: ${response.statusCode}");
    }
  }

  /// ✅ Sync User (for authentication)
  static Future<Map<String, dynamic>> syncUser(
      String token, String phone, String address) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/auth/sync/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
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

  /// ✅ Fetch Donations
  static Future<List<dynamic>> fetchDonations(String token, {int limit = 10, int offset = 0}) async {
  final url = Uri.parse("${ApiConfig.baseUrl}/api/donations/?limit=$limit&offset=$offset");
  final response = await http.get(
    url,
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception("Failed to fetch donations: ${response.body}");
  }
}

  /// ✅ Upload NGO / Donor Verification Document
  static Future<Map<String, dynamic>> uploadNGODoc(
      String token, File file) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/auth/donor-upload/'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('document', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception("Upload failed: ${response.statusCode} - ${response.body}");
    }
  }

  /// ✅ Create Donation
  static Future<Map<String, dynamic>> createDonation(
    String token,
    String title,
    String foodType,
    String expiry,
    String pickupDateTime,
    String address,
    double latitude,
    double longitude,
    String quantity,
    File? image,
  ) async {
    try {
      final expiryDate = DateFormat('MM/dd/yyyy').parse(expiry);
      final expiryFormatted = DateFormat('yyyy-MM-dd').format(expiryDate);

      final pickupDateTimeParsed =
          DateFormat('MM/dd/yyyy hh:mm a').parse(pickupDateTime);
      final pickupFormatted =
          DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(pickupDateTimeParsed);

      var request = http.MultipartRequest(
          "POST", Uri.parse("${ApiConfig.baseUrl}/api/donations/"));
      request.headers["Authorization"] = "Bearer $token";

      request.fields["title"] = title;
      request.fields["food_type"] = foodType;
      request.fields["expiry_date"] = expiryFormatted;
      request.fields["pickup_time"] = pickupFormatted;
      request.fields["location.address"] = address;
      request.fields["location.latitude"] = latitude.toString();
      request.fields["location.longitude"] = longitude.toString();
      request.fields["quantity"] = quantity;

      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath("image", image.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("🧾 Body: ${response.body}");

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception("Failed to create donation: ${response.body}");
      }
    } catch (e) {
      throw Exception("Date conversion or upload failed: $e");
    }
  }
}

/// 🔹 Firebase Auth Helper
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
