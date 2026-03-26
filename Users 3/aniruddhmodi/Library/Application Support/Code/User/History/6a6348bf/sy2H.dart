import 'dart:convert';
import 'dart:typed_data';
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

  // Pick an image from the file system
  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.isNotEmpty) {
      final fileBytes = result.files.first.bytes;
      
      setState(() {
        selectedImage = fileBytes;
      });
      print('Image selected: ${result.files.first.name}');
    } else {
      print('No image selected');
    }
  }

  // Send the picked image
  Future<void> sendImage() async {
    if (selectedImage == null) return;

    final base64Image = base64Encode(selectedImage!);

    final messageJson = jsonEncode({
      'sentence': 'Here is your image!',
      'image': base64Image,
    });

    final builder = MqttClientPayloadBuilder();
    builder.addString(messageJson);

    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      print('Sending image...');
      client?.publishMessage('flutter/image', MqttQos.atLeastOnce, builder.payload!);
      print("Image sent successfully!");
    } else {
      print('Not connected to MQTT broker');
    }
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
            // Display the image if selected
            if (selectedImage != null)
              Image.memory(selectedImage!, height: 250),
            // Buttons to pick and send image
            ElevatedButton(
              onPressed: pickImage,
              child: Text('Pick Image'),
            ),
            ElevatedButton(
              onPressed: sendImage,
              child: Text('Send Image'),
            ),
          ],
        ),
      ),
    );
  }
}
