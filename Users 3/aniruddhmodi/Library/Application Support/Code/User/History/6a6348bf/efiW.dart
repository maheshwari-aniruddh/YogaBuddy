import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget
{
  @override
  Widget build(BuildContext context)
  {
    return MaterialApp(
      title: 'Image Inference via HTTP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImageSenderPage(),
    );
  }
}

class ImageSenderPage extends StatefulWidget
{
  @override
  _ImageSenderPageState createState() => _ImageSenderPageState();
}

class _ImageSenderPageState extends State<ImageSenderPage>
{
  Uint8List? selectedImage;
  String resultMessage = '';
  bool isSending = false;

  Future<void> pickImage() async
  {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) return;

      final fileBytes = result.files.first.bytes;
      final filePath = result.files.first.path;

      if (fileBytes != null) {
        selectedImage = fileBytes;
      } else if (filePath != null) {
        selectedImage = await File(filePath).readAsBytes();
      }

      setState(() {});
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> sendImage() async
  {
    if (selectedImage == null) return;

    setState(() {
      resultMessage = 'Processing...';
      isSending = true;
    });

    final base64Image = base64Encode(selectedImage!);

    final url = Uri.http('192.168.1.5:8000', '/infer');
 // Use your FastAPI server IP

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          resultMessage = decoded['result'] ?? 'No result';
        });
      } else {
        print('HTTP ${response.statusCode}: ${response.body}');
        setState(() {
          resultMessage = 'Server Error (${response.statusCode})';
        });
      }
    } catch (e) {
      print('Error sending image: $e');
      setState(() {
        resultMessage = 'Error sending image';
      });
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(title: Text('Image Inference via HTTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: selectedImage != null
                    ? Image.memory(selectedImage!)
                    : Center(child: Text('No image selected')),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.photo),
                    onPressed: pickImage,
                    label: Text('Pick Image'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.send),
                    onPressed: isSending ? null : sendImage,
                    label: Text('Send'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              flex: 1,
              child: Card(
                child: Center(
                  child: Text(
                    resultMessage.isEmpty ? 'No result yet' : resultMessage,
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }
}
