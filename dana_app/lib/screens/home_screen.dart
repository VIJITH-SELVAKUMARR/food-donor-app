import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import 'ngo_upload_screen.dart';


class HomeScreen extends StatefulWidget {
  final String? message; // ✅ add constructor parameter

  const HomeScreen({super.key, this.message});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String message = "Loading...";
  @override
  void initState() {
    super.initState();
    if (widget.message != null) {
      message = widget.message!;
    } // ✅ initialize with constructor value
    _checkApi();
    _initFCM();
  }

  void _checkApi() async {
  try {
    // 🔑 Get Firebase ID token
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();

    if (token == null) {
      setState(() => message = "❌ No Firebase token found");
      return;
    }

    // ✅ Call syncUser with required params
    final result = await ApiService.syncUser(
      token,
      "donor",         // default user_type
      "9876543210",    // placeholder phone
      "Chennai",       // placeholder address
    );

    setState(() => message = result["message"] ?? "No message in response");
  } catch (e) {
    setState(() => message = "Error: $e");
  }
}

  void _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      print("FCM Token: $token");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dana App")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 30),

            // ✅ Navigation button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NGOUploadScreen(token: '',)),
                );
              },
              child: const Text("Go to NGO Upload"),
            ),
          ],
        ),
      ),
    );
  }
}


