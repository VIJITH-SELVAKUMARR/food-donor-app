import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart';
import '../api/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase (uncomment when you have firebase_options.dart)
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodShare',
      theme: ThemeData(
        primaryColor: const Color(0xFF4CAF50),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistering = false;

  /// 🔹 Google Sign-In
  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);
      
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      await _syncUserAndNavigate(userCredential.user);
    } catch (e) {
      _showError("Google login failed: $e");
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Email/Password Login
  Future<void> _signInWithEmail() async {
    if (!_validateForm()) return;
    
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _syncUserAndNavigate(userCredential.user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showError("No user found for that email.");
      } else if (e.code == 'wrong-password') {
        _showError("Wrong password provided.");
      } else {
        _showError("Login failed: ${e.message}");
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Register New User
  Future<void> _registerWithEmail() async {
    if (!_validateForm()) return;
    
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _syncUserAndNavigate(userCredential.user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _showError("The password provided is too weak.");
      } else if (e.code == 'email-already-in-use') {
        _showError("An account already exists for that email.");
      } else {
        _showError("Registration failed: ${e.message}");
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Sync user with backend and navigate
  Future<void> _syncUserAndNavigate(User? user) async {
    if (user == null) return;

    try {
      final token = await user.getIdToken();
      final result = await ApiService.syncUser(
        token!,
        "donor",
        "9876543210", // You might want to collect this during registration
        "Chennai",    // You might want to collect this during registration
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            message: "Welcome ${user.email}! ${result["message"] ?? "Sync successful"}",
          ),
        ),
      );
    } catch (e) {
      _showError("Sync failed: $e");
    }
  }

  bool _validateForm() {
    if (_emailController.text.trim().isEmpty) {
      _showError("Please enter your email");
      return false;
    }
    if (_passwordController.text.trim().isEmpty) {
      _showError("Please enter your password");
      return false;
    }
    if (_passwordController.text.trim().length < 6) {
      _showError("Password must be at least 6 characters");
      return false;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _isRegistering = !_isRegistering;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF32B768);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('FoodShare', 
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black54),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Help & Support")),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                _isRegistering ? 'Create Account' : 'Welcome Back', 
                textAlign: TextAlign.center, 
                style: const TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black)
              ),
              const SizedBox(height: 48.0),
              
              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                  hintText: 'Email',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0), 
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              
              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0), 
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              
              // Forgot Password (only show in login mode)
              if (!_isRegistering) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Password reset feature coming soon!")),
                      );
                    },
                    child: const Text(
                      'Forgot password?', 
                      style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600)
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),
              ],
              
              // Loading Indicator
              if (_isLoading) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16.0),
              ],
              
              // Login/Register Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  elevation: 5,
                  shadowColor: primaryGreen.withOpacity(0.4),
                ),
                onPressed: _isLoading ? null : _isRegistering ? _registerWithEmail : _signInWithEmail,
                child: Text(
                  _isRegistering ? 'Create Account' : 'Log In', 
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16.0),
              
              // Toggle between Login and Register
              TextButton(
                onPressed: _isLoading ? null : _toggleMode,
                child: Text(
                  _isRegistering 
                    ? 'Already have an account? Log In' 
                    : 'Don\'t have an account? Sign Up',
                  style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 32.0),
              
              const Row(
                children: <Widget>[
                  Expanded(child: Divider(color: Colors.black26)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0), 
                    child: Text('OR', style: TextStyle(color: Colors.black45)),
                  ),
                  Expanded(child: Divider(color: Colors.black26)),
                ],
              ),
              const SizedBox(height: 32.0),
              
              // Google Sign-In Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: Image.network(
                  'http://pngimg.com/uploads/google/google_PNG19635.png', 
                  height: 20.0,
                ),
                label: const Text(
                  'Sign in with Google', 
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 48.0),
              
              // Terms and Privacy (only show in register mode)
              if (_isRegistering) ...[
                Align(
                  alignment: Alignment.bottomCenter,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: "By creating an account, you agree to our ",
                      style: const TextStyle(color: Colors.black54, fontSize: 12.0),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Terms of Service',
                          style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                          recognizer: TapGestureRecognizer()..onTap = () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Terms of Service")),
                            );
                          },
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                          recognizer: TapGestureRecognizer()..onTap = () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Privacy Policy")),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
