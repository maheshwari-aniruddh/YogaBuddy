import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MqttScreen());
  }
}

class MqttScreen extends StatefulWidget {
  @override
  _MqttScreenState createState() => _MqttScreenState();
}

class _MqttScreenState extends State<MqttScreen> {
  final client = MqttServerClient('localhost', 'flutter_client');
  String resultText = "Waiting for result...";

  @override
  void initState() {
    super.initState();
    connectToMqtt();
  }

  void connectToMqtt() async {
    client.logging(on: true);
    client.port = 1883;
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier("flutter_client")
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print("MQTT connection error: $e");
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print("Connected to MQTT broker");

      client.subscribe('flutter/result', MqttQos.atLeastOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        print('Received message: $payload');

        try {
          final decoded = jsonDecode(payload);
          setState(() {
            resultText = decoded['result'] ?? "Invalid result";
          });
        } catch (e) {
          print("JSON decode error: $e");
        }
      });
    } else {
      print("Connection failed");
    }
  }

  void onConnected() {
    print('Connected');
  }

  void onDisconnected() {
    print('Disconnected');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Brain Tumor Detection')),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Text(
            resultText,
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
