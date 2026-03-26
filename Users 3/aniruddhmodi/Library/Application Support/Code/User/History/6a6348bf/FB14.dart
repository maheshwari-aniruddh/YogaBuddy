import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Send Image via HTTP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ImageSenderPage(),
    );
  }
}

class ImageSenderPage extends StatefulWidget {
  @override
  _ImageSenderPageState createState() => _ImageSenderPageState();
}

class _ImageSenderPageState extends State<ImageSenderPage> {
  Uint8List? selectedImage;
  String resultMessage = '';

  Future<void> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) return;

      final fileBytes = result.files.first.bytes;
      final filePath = result.files.first.path;

      if (fileBytes == null && filePath != null) {
        final file = File(filePath);
        selectedImage = await file.readAsBytes();
      } else if (fileBytes != null) {
        selectedImage = fileBytes;
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> sendImage() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    final uri = Uri.parse('http://192.168.1.8:8000/infer'); // use your FastAPI IP
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes('image', selectedImage!, filename: 'upload.jpg'),
    );

    setState(() {
      resultMessage = 'Processing...';
    });

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final resultData = jsonDecode(responseBody);

      setState(() {
        resultMessage = resultData['result'] ?? 'No result';
      });
    } catch (e) {
      setState(() {
        resultMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Image via HTTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: selectedImage != null
                    ? Image.memory(selectedImage!, fit: BoxFit.contain)
                    : Center(child: Text('No image selected')),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.photo),
                    label: Text('Pick Image'),
                    onPressed: pickImage,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.send),
                    label: Text('Send Image'),
                    onPressed: sendImage,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              resultMessage,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
