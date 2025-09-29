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
    if (_file == null) return;
    try {
      final result = await ApiService.uploadNGODoc(widget.token, _file!);
      setState(() => message = "Uploaded! Status: ${result["verified"] ? "Verified" : "Pending"}");
    } catch (e) {
      setState(() => message = "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NGO Verification")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_file != null) Image.file(_file!, height: 150),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _pickFile, child: const Text("Pick Document")),
            ElevatedButton(onPressed: _uploadFile, child: const Text("Upload")),
            const SizedBox(height: 20),
            Text(message, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
