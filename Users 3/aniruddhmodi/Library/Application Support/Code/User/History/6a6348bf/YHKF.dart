import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Send Image via MQTT',
      home: ImageSenderPage(),
    );
  }
}

class ImageSenderPage extends StatefulWidget {
  @override
  _ImageSenderPageState createState() => _ImageSenderPageState();
}

class _ImageSenderPageState extends State<ImageSenderPage> {
  MqttServerClient? client;
  Uint8List? selectedImage;

  @override
  void initState() {
    super.initState();
    connectToBroker();
  }

  // Connects to the MQTT broker
  Future<void> connectToBroker() async {
    client = MqttServerClient('localhost', 'flutter_client_${DateTime.now().millisecondsSinceEpoch}');
    client!.port = 1883;
    client!.keepAlivePeriod = 20;
    client!.logging(on: false);
    client!.onDisconnected = () => print('Disconnected');
    client!.onConnected = () => print('Connected');

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client!.connectionMessage = connMessage;

    try {
      await client!.connect();
      print('Connected to MQTT broker');
    } catch (e) {
      print('MQTT connection failed: $e');
      client!.disconnect();
    }
  }

  // Picks and sends the image
  Future<void> pickAndSendImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;

    final fileBytes = result.files.first.bytes;
    final filePath = result.files.first.path;

    if (fileBytes == null && filePath != null) {
      final file = File(filePath);
      selectedImage = await file.readAsBytes();
    } else {
      selectedImage = fileBytes;
    }

    if (selectedImage == null) return;

    final base64Image = base64Encode(selectedImage!);

    final messageJson = jsonEncode({
      'sentence': 'Here is your image!',
      'image': base64Image,
    });

    final builder = MqttClientPayloadBuilder();
    builder.addString(messageJson);

    if (client != null && client!.connectionStatus!.state == MqttConnectionState.connected) {
      // Publish message only if client is connected
      print('Publishing image...');
      client!.publishMessage('your/topic', MqttQos.atLeastOnce, builder.payload!);

      // Show a confirmation Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image sent successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Show error Snackbar if not connected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send image. MQTT not connected!'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Image via MQTT'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selectedImage != null)
              Image.memory(selectedImage!, height: 250),
            ElevatedButton(
              onPressed: pickAndSendImage,
              child: Text('Pick Image and Send'),
            ),
          ],
        ),
      ),
    );
  }
}
