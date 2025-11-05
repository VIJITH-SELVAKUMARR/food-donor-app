import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../api/api_service.dart';
import 'create_donation_screen.dart';
import 'ngo_upload_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // ✅ For reverse geocoding
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' show cos, sqrt, asin;

class DonationDetailPage extends StatelessWidget {
  final dynamic donation;

  const DonationDetailPage({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(donation["title"] ?? "Donation Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(donation["title"] ?? "Untitled Donation",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text("Food Type: ${donation["food_type"] ?? "Food"}"),
          Text("Expiry: ${donation["expiry_date"] ?? "N/A"}"),
          Text("Pickup: ${donation["pickup_time"] ?? "N/A"}"),
        ]),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String? message;
  const HomeScreen({super.key, this.message});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _donations = [];
  List<dynamic> _visibleDonations = [];
  bool _isLoadingDonations = true;
  bool _isLoadingMore = false;

  int _visibleCount = 5;
  final int _loadStep = 5;
  final String baseUrl = ApiConfig.baseUrl;

  String _apiMessage = "Loading...";
  int _selectedIndex = 0;

  Position? _currentPosition;
  String _currentAddress = "Fetching location..."; // ✅ Added

  @override
  void initState() {
    super.initState();
    if (widget.message != null) _apiMessage = widget.message!;
    _checkApi();
    _initFCM();
    _fetchDonations();
    _getCurrentLocation();
  }

  /// 🧭 Get current location + address
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _currentAddress = "Location disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _currentAddress = "Permission denied");
          return;
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      print("📍 Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}");

      await _getAddressFromLatLng(_currentPosition!);
    } catch (e) {
      print("⚠️ Location error: $e");
      setState(() => _currentAddress = "Location unavailable");
    }
  }

  /// 📍 Convert coordinates → readable address
  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address =
            "${place.street?.split(',').first ?? ''}, ${place.locality ?? ''}";
        setState(() => _currentAddress = address.trim().isNotEmpty
            ? address
            : "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}");
      }
    } catch (e) {
      print("⚠️ Reverse geocoding failed: $e");
      setState(() => _currentAddress =
          "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}");
    }
  }

  /// 📡 Fetch donations
  void _fetchDonations() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return;
      final data = await ApiService.fetchDonations(token);
      setState(() {
        _donations = data;
        _visibleDonations = _donations.take(_visibleCount).toList();
        _isLoadingDonations = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDonations = false;
        _apiMessage = "Error fetching donations: $e";
      });
    }
  }

  void _loadMore() {
    if (_isLoadingMore || _visibleCount >= _donations.length) return;
    setState(() => _isLoadingMore = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _visibleCount += _loadStep;
        _visibleDonations = _donations.take(_visibleCount).toList();
        _isLoadingMore = false;
      });
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _checkApi() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        setState(() => _apiMessage = "❌ No Firebase token found");
        _showApiMessage();
        return;
      }
      final result = await ApiService.syncUser(token, "9876543210", "Chennai");
      setState(() => _apiMessage = result["message"] ?? "Connected");
    } catch (e) {
      setState(() => _apiMessage = "Error: $e");
    }
    _showApiMessage();
  }

  void _showApiMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_apiMessage), duration: const Duration(seconds: 3)),
      );
    }
  }

  void _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      print("📱 FCM Token: $token");
    }
  }

  void _navigateToNgoUpload() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => NGOUploadScreen(token: token)));
    } else {
      _showApiMessage();
    }
  }

  void _navigateToCreateDonation() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => CreateDonationScreen(token: token)));
    } else {
      _showApiMessage();
    }
  }

  void _onBottomNavTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateDonation,
        backgroundColor: primaryGreen,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        shape: const CircleBorder(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), label: 'My Donations'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Messages'),
        ],
      ),
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://i.imgur.com/39S5w0j.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _locationChip(_currentAddress),
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person_outline, color: Colors.black54),
              ),
            ]),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.35,
          maxChildSize: 0.8,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
            ),
            child: _isLoadingDonations
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(children: [
                        _sheetHeader(primaryGreen),
                        const SizedBox(height: 20),
                        ..._buildDonationCards(),
                        if (_visibleCount < _donations.length)
                          Center(
                            child: TextButton.icon(
                              onPressed: _loadMore,
                              icon: const Icon(Icons.expand_more),
                              label: const Text("Load More"),
                            ),
                          ),
                        if (_isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                      ]),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }

  Widget _locationChip(String address) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined, color: Color(0xFF4CAF50), size: 20),
            const SizedBox(width: 6),
            Text(
              address.length > 25 ? "${address.substring(0, 25)}..." : address,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );

  Widget _sheetHeader(Color primaryGreen) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Available Donations",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ElevatedButton.icon(
            onPressed: _navigateToNgoUpload,
            icon: const Icon(Icons.verified_outlined, size: 18),
            label: const Text("Verify"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      );

  List<Widget> _buildDonationCards() {
    return _visibleDonations.map((d) {
      final donorName = d["donor"]?["username"] ?? "Anonymous";
      final imageUrl = d["image"] != null ? "$baseUrl${d["image"]}" : null;
      final expiry = d["expiry_date"] ?? "N/A";
      final pickup = d["pickup_time"] ?? "N/A";
      final foodType = d["food_type"] ?? "Food";

      double? distanceKm;
      if (_currentPosition != null &&
          d["location"]?["latitude"] != null &&
          d["location"]?["longitude"] != null) {
        distanceKm = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          d["location"]["latitude"],
          d["location"]["longitude"],
        );
      }

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => DonationDetailPage(donation: d))),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl ?? "",
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.food_bank, size: 40),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d["title"] ?? "Untitled Donation",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 8),
                      _foodTypeChip(foodType),
                      Text("by $donorName",
                          style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 8),
                      Text("Expires: $expiry",
                          style: const TextStyle(color: Colors.black54)),
                      if (distanceKm != null)
                        Text("${distanceKm.toStringAsFixed(1)} km away",
                            style: const TextStyle(color: Colors.black54)),
                      Text("Pickup: $pickup",
                          style: const TextStyle(color: Colors.black54)),
                    ]),
              ),
            ]),
          ),
        ),
      );
    }).toList();
  }

  Widget _foodTypeChip(String type) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      );
}
