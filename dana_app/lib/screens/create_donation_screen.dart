import 'dart:io';
import 'package:dana_app/screens/donation_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

// --- Placeholder for your ApiService ---
// You should replace this with your actual ApiService.
// NOTE: I've added a 'quantity' parameter to match the new form.


// --- Main Screen Widget ---
class CreateDonationScreen extends StatefulWidget {
  final String token;
  const CreateDonationScreen({super.key, required this.token});

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  // Form and State Management
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String _message = "";

  // Form Field Controllers and Variables
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _pickupDateController = TextEditingController();
  final TextEditingController _pickupTimeController = TextEditingController();

  String _title = "";
  String? _foodType; // Use nullable for dropdown hint
  String _quantity = "";
  String _address = "";
  File? _image;
  Position? _position;

  final picker = ImagePicker();

  // --- LOGIC METHODS (from your original code) ---

  Future<void> _getCurrentLocation() async {
    setState(() => _loading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permission denied.");
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied, we cannot request permissions.");
      }

      _position = await Geolocator.getCurrentPosition();
      setState(() {
        _message = "📍 Location fetched successfully!";
      });

    } catch (e) {
      setState(() => _message = "Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
  final picked = await picker.pickImage(source: ImageSource.gallery);
  if (picked != null) setState(() => _image = File(picked.path));
}

Future<void> _submit() async {
  print("📩 Submit pressed");

  if (!_formKey.currentState!.validate() || _position == null) return;
  _formKey.currentState!.save();

  setState(() {
    _loading = true;
    _message = "creating...";
  });

  try {
    print("🛰️ Sending donation creation request...");
    final result = await ApiService.createDonation(
      widget.token,
      _title,
      _foodType!,
      _expiryDateController.text,
      "${_pickupDateController.text} ${_pickupTimeController.text}",
      _address,
      _position!.latitude,
      _position!.longitude,
      _quantity,
      _image,
    );
    print("✅ Donation response: $result");
    setState(() => _loading = false);

// ✅ Navigate to success screen
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => DonationSuccessScreen(
      title: _title,
      foodType: _foodType!,
      expiryDate: _expiryDateController.text,
      pickupTime: "${_pickupDateController.text} ${_pickupTimeController.text}",
    ),
  ),
);

  } catch (e) {
    setState(() {
      _message = "Error: $e";
      _loading = false;
    });
  }
}

  // --- UI HELPER METHODS ---

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.format(context);
      });
    }
  }

  @override
  void dispose() {
    _expiryDateController.dispose();
    _pickupDateController.dispose();
    _pickupTimeController.dispose();
    super.dispose();
  }

  // --- BUILD METHOD (New UI) ---

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF4CAF50);
    final Color fieldColor = Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
        ),
        title: const Text(
          "New Donation",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food Type Dropdown
              _buildLabel("Food Type"),
              DropdownButtonFormField<String>(
                value: _foodType,
                hint: const Text('Select Food Type', style: TextStyle(color: Colors.grey)),
                decoration: _buildInputDecoration(fieldColor),
                items: ['Cooked Meal', 'Fruits', 'Vegetables', 'Bakery', 'Dairy', 'Other']
                    .map((label) => DropdownMenuItem(child: Text(label), value: label))
                    .toList(),
                onChanged: (value) => setState(() => _foodType = value),
                validator: (v) => v == null ? "Please select a food type" : null,
              ),
              const SizedBox(height: 16),

              // Quantity and Expiry Date Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Quantity"),
                        TextFormField(
                          decoration: _buildInputDecoration(fieldColor, hint: 'e.g., 5 kg'),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                          onSaved: (v) => _quantity = v!,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Expiry Date"),
                        TextFormField(
                          controller: _expiryDateController,
                          readOnly: true,
                          decoration: _buildInputDecoration(fieldColor, hint: 'mm/dd/yyyy', suffixIcon: Icons.calendar_today),
                          onTap: () => _selectDate(context, _expiryDateController),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Address and Get Location
              _buildLabel("Address"),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: _buildInputDecoration(fieldColor, hint: 'Enter your address'),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                      onSaved: (v) => _address = v!,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.location_searching),
                    label: const Text("Get\nLocation"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              
              // Pickup Date and Time
               Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Pick-up Date"),
                        TextFormField(
                          controller: _pickupDateController,
                          readOnly: true,
                          decoration: _buildInputDecoration(fieldColor, hint: 'mm/dd/yyyy', suffixIcon: Icons.calendar_today),
                          onTap: () => _selectDate(context, _pickupDateController),
                           validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Pick-up Time"),
                        TextFormField(
                          controller: _pickupTimeController,
                           readOnly: true,
                          decoration: _buildInputDecoration(fieldColor, hint: '--:-- --', suffixIcon: Icons.access_time),
                           onTap: () => _selectTime(context, _pickupTimeController),
                           validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              _buildLabel("Title"),
              TextFormField(
                decoration: _buildInputDecoration(fieldColor, hint: 'e.g., Fresh bread from local bakery'),
                validator: (v) => v!.isEmpty ? "Required" : null,
                onSaved: (v) => _title = v!,
              ),
              const SizedBox(height: 24),
              
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400, width: 2, style: BorderStyle.solid)
                  ),
                  child: _image == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined, color: Colors.grey, size: 48),
                            SizedBox(height: 8),
                            Text('Click to upload an image', style: TextStyle(color: Colors.grey)),
                            Text('SVG, PNG, JPG or GIF', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        )
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_image!, fit: BoxFit.cover)
                      ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Message and Loading
              if (_message.isNotEmpty) Center(child: Text(_message, style: TextStyle(color: _message.startsWith("Error") ? Colors.red : Colors.black))),
              const SizedBox(height: 10),

              // Submit Button
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Submit Donation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER METHODS ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  InputDecoration _buildInputDecoration(Color fillColor, {String? hint, IconData? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      filled: true,
      fillColor: fillColor,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.grey) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
