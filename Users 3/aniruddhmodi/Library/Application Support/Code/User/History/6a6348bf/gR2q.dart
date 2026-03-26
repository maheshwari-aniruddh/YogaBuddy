import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mqtt_client/mqtt_client.dart';

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
  String result = "";

  @override
  void initState() {
    super.initState();
    connectToBroker();
  }

  // Connect to MQTT broker
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
      client!.subscribe('flutter/result', MqttQos.atLeastOnce);
    } catch (e) {
      print('MQTT connection failed: $e');
      client!.disconnect();
    }

    // Listen for messages from the server (inference result)
    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final MqttReceivedMessage<MqttMessage> message = messages[0];
      final payload = message.payload as MqttPublishMessage;
      final resultString = MqttPublishPayload.bytesToStringAsString(payload.payload.message);

      setState(() {
        result = resultString;
      });

      // Show a snackbar with the result
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Inference result: $result'),
        duration: Duration(seconds: 3),
      ));
    });
  }

  // Pick image
  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;

    final fileBytes = result.files.first.bytes;
    setState(() {
      selectedImage = fileBytes;
    });
  }

  // Send image
  Future<void> sendImage() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected')),
      );
      return;
    }

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
      print('MQTT not connected');
    }
  }

  @override
  void dispose() {
    client?.disconnect();
    super.dispose();
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
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: sendImage,
              child: Text('Send Image'),
            ),
            if (result.isNotEmpty)
              Text(
                'Inference Result: $result',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
