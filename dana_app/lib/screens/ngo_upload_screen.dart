import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_service.dart';

class NGOUploadScreen extends StatefulWidget {
  final String token;
  const NGOUploadScreen({super.key, required this.token});

  @override
  State<NGOUploadScreen> createState() => _NGOUploadScreenState();
}

class _NGOUploadScreenState extends State<NGOUploadScreen> {
  File? _file;
  final picker = ImagePicker();
  String message = "";

  Future<void> _pickFile() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _file = File(picked.path));
    }
  }

  Future<void> _uploadFile() async {
    if (_file == null) {
      setState(() => message = "Please pick a file first.");
      return;
    }

    try {
      print("🪪 Using token: ${widget.token}");

      final result = await ApiService.uploadNGODoc(widget.token, _file!);
      
      setState(() => message = "✅ Uploaded! Status: ${result["status"] ? "status" : "Pending"}");
    } catch (e) {
      setState(() => message = "❌ Error: $e");
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NGO Verification")),
      body: SafeArea(
  child: SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_file != null)
          Image.file(_file!, height: 150, width: 150, fit: BoxFit.cover),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _pickFile, child: const Text("Pick Document")),
        ElevatedButton(onPressed: _uploadFile, child: const Text("Upload")),
        const SizedBox(height: 20),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  ),
),

    );
  }
}
