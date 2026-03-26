import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:convert';

import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQTT Inference Result',
      home: InferenceResultPage(),
    );
  }
}

class InferenceResultPage extends StatefulWidget {
  @override
  _InferenceResultPageState createState() => _InferenceResultPageState();
}

class _InferenceResultPageState extends State<InferenceResultPage> {
  MqttServerClient? client;
  String result = "";

  @override
  void initState() {
    super.initState();
    connectToBroker();
  }

  Future<void> connectToBroker() async {
    client = MqttServerClient('localhost', 'flutter_client_result');
    client!.port = 1883;
    client!.keepAlivePeriod = 20;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client_result')
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

    // Set up the callback for receiving messages
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

  @override
  void dispose() {
    client?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MQTT Inference Result'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (result.isNotEmpty)
              Text(
                'Inference Result: $result',
                style: TextStyle(fontSize: 24),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Trigger the image picking and sending (this part is for picking and sending image)
              },
              child: Text('Pick Image and Send'),
            ),
          ],
        ),
      ),
    );
  }
}
