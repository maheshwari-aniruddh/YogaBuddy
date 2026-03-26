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
  MqttServerClient? client;
  Uint8List? selectedImage;
  String resultMessage = '';
  String connectionStatus = 'Disconnected';
  bool isMqttConnected = false;

  @override
  void initState() {
    super.initState();
    connectToBroker();
  }

  @override
  void dispose() {
    client?.disconnect();
    super.dispose();
  }

  // Connect to MQTT Broker
  Future<void> connectToBroker() async {
    final clientId = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
    print('Connecting with client ID: $clientId');
    
    client = MqttServerClient('test.mosquitto.org', clientId);
    client!.port = 1883;
    client!.keepAlivePeriod = 20;
    client!.logging(on: true);
    
    client!.onDisconnected = () {
      print('Disconnected from MQTT broker');
      setState(() {
        connectionStatus = 'Disconnected';
        isMqttConnected = false;
      });
    };
    
    client!.onConnected = () {
      print('Connected to MQTT broker');
      setState(() {
        connectionStatus = 'Connected';
        isMqttConnected = true;
      });
    };

    client!.onSubscribed = (String topic) {
      print('Subscribed to topic: $topic');
    };

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client!.connectionMessage = connMessage;

    try {
      print('Connecting to MQTT broker...');
      await client!.connect();
      
      // Subscribe to the result topic
      print('Subscribing to flutter/result topic');
      client!.subscribe('flutter/result', MqttQos.atLeastOnce);
      
      // Listen for incoming messages with enhanced debugging
      client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
        print('MQTT update callback triggered');
        
        if (messages == null || messages.isEmpty) {
          print('Received empty message list');
          return;
        }
        
        final recMess = messages[0];
        print('Topic: ${recMess.topic}');
        
        final MqttPublishMessage message = recMess.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        print('Received message payload: $payload');
        
        try {
          final resultData = jsonDecode(payload);
          print('Successfully decoded JSON: $resultData');
          
          if (resultData.containsKey('result')) {
            setState(() {
              resultMessage = resultData['result'];
              print('Updated resultMessage: $resultMessage');
            });
          } else {
            print('JSON does not contain "result" key: $resultData');
          }
        } catch (e) {
          print('Error decoding JSON: $e');
        }
      });
    } catch (e) {
      print('MQTT connection failed: $e');
      setState(() {
        connectionStatus = 'Connection Failed: $e';
        isMqttConnected = false;
      });
      client!.disconnect();
    }
  }

  // Reconnect to MQTT broker
  Future<void> reconnectToBroker() async {
    print('Attempting to reconnect to MQTT broker');
    if (client != null) {
      client!.disconnect();
    }
    await connectToBroker();
  }

  // Pick an image file
  Future<void> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) {
        print('No image selected');
        return;
      }

      final fileBytes = result.files.first.bytes;
      final filePath = result.files.first.path;
      final fileName = result.files.first.name;
      print('Selected image: $fileName');

      if (fileBytes == null && filePath != null) {
        final file = File(filePath);
        selectedImage = await file.readAsBytes();
        print('Image loaded from file, size: ${selectedImage!.length} bytes');
      } else if (fileBytes != null) {
        selectedImage = fileBytes;
        print('Image loaded from memory, size: ${selectedImage!.length} bytes');
      }

      setState(() {});
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Send the image to MQTT broker
  Future<void> sendImage() async {
    if (selectedImage == null) {
      print('No image selected to send');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    if (!isMqttConnected) {
      print('MQTT not connected, attempting to reconnect');
      await reconnectToBroker();
      if (!isMqttConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MQTT not connected. Cannot send image.')),
        );
        return;
      }
    }

    try {
      print('Encoding image to base64, size: ${selectedImage!.length} bytes');
      final base64Image = base64Encode(selectedImage!);
      print('Base64 encoded length: ${base64Image.length}');

      final messageJson = jsonEncode({
        'sentence': 'Here is your image!',
        'image': base64Image,
      });

      final builder = MqttClientPayloadBuilder();
      builder.addString(messageJson);
      print('Created MQTT payload, size: ${builder.payload!.length} bytes');

      print('Publishing to flutter/image topic');
      client?.publishMessage(
        'flutter/image', 
        MqttQos.atLeastOnce, 
        builder.payload!,
        retain: false
      );
      print('Image sent successfully!');

      // Reset the result message until we get a new one
      setState(() {
        resultMessage = 'Processing...';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image sent successfully!')),
      );
    } catch (e) {
      print('Error sending image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Image via MQTT'),
        actions: [
          // Connection status indicator
          Container(
            padding: EdgeInsets.all(10),
            child: Center(
              child: Text(
                connectionStatus,
                style: TextStyle(
                  color: isMqttConnected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status
            Card(
              color: isMqttConnected ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(
                      isMqttConnected ? Icons.cloud_done : Icons.cloud_off,
                      color: isMqttConnected ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'MQTT Status: $connectionStatus',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: reconnectToBroker,
                      child: Text('Reconnect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMqttConnected ? Colors.grey : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Image preview
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: selectedImage != null
                    ? Image.memory(
                        selectedImage!,
                        fit: BoxFit.contain,
                      )
                    : Center(
                        child: Text(
                          'No image selected',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.photo_library),
                    onPressed: pickImage,
                    label: Text('Pick Image'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.send),
                    onPressed: isMqttConnected ? sendImage : null,
                    label: Text('Send Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Inference Results
            Expanded(
              flex: 1,
              child: Card(
                elevation: 3,
                color: resultMessage.isEmpty 
                    ? Colors.grey.shade100 
                    : (resultMessage.contains("Tumor") 
                        ? Colors.red.shade50 
                        : Colors.green.shade50),
                child: Center(
                  child: resultMessage.isNotEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Inference Result:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              resultMessage,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: resultMessage.contains("Tumor") 
                                    ? Colors.red.shade800 
                                    : Colors.green.shade800,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'No inference results yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
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