// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Import your screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_donation_screen.dart';
import 'screens/donation_success_screen.dart';
import 'screens/forgot_password_screen.dart'; // ✅ Import here


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      
      // Initial screen
      home: const LoginScreen(),

      // ✅ Named routes for navigation
      routes: {
        '/home': (context) => const HomeScreen(),
        '/create-donation': (context) => const CreateDonationScreen(token: ''),
        '/forgot-password': (context) => const ForgotPasswordScreen(),          
        // This screen takes arguments, so we’ll handle them safely:
        '/donation-success': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

          return DonationSuccessScreen(
            title: args?['title'] ?? '',
            foodType: args?['foodType'] ?? '',
            expiryDate: args?['expiryDate'] ?? '',
            pickupTime: args?['pickupTime'] ?? '',
          );
        },
      },
    );
  }
}




