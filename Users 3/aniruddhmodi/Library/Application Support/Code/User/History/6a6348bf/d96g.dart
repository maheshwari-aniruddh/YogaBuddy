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
  String resultMessage = '';
  TextEditingController resultController = TextEditingController();

  @override
  void initState() {
    super.initState();
    connectToBroker();
  }

  // Connect to MQTT Broker
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

      // Subscribe to the result topic to get inference results
      client!.subscribe('flutter/result', MqttQos.atLeastOnce);
      client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
        final message = messages![0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        print("Received message: $payload");

        // Parse the result and update the UI
        final resultData = jsonDecode(payload);
        setState(() {
          resultMessage = resultData['result']; // Update result with the server's response
          resultController.text = resultMessage; // Update the text field with the result
        });
      });
    } catch (e) {
      print('MQTT connection failed: $e');
      client!.disconnect();
    }
  }

  // Pick an image file
  Future<void> pickImage() async {
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

    setState(() {});
  }

  // Send the image to MQTT broker
  Future<void> sendImage() async {
    if (selectedImage == null) return;

    final base64Image = base64Encode(selectedImage!);

    final messageJson = jsonEncode({
      'sentence': 'Here is your image!',
      'image': base64Image,
    });

    final builder = MqttClientPayloadBuilder();
    builder.addString(messageJson);

    await client?.connect();
    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      print('MQTT connected');
      client?.publishMessage('flutter/image', MqttQos.atLeastOnce, builder.payload!);
      print("Image sent successfully!");

      // Show SnackBar after sending the image
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image sent successfully!')),
      );
    } else {
      print('MQTT not connected');
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickImage,
              child: Text('Pick Image'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendImage,
              child: Text('Send Image'),
            ),
            SizedBox(height: 20),
            // Text box for result message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: resultController,
                maxLines: 5, // Makes the text box a bit bigger
                decoration: InputDecoration(
                  labelText: 'Inference Result',
                  border: OutlineInputBorder(),
                )
                readOnly: true, // Makes the text box read-only
              ),
            ),
          ],
        ),
      ),
    );
  }
}
