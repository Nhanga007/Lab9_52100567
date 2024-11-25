import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late MqttBrowserClient client;
  String connectionStatus = 'Connecting...';

  @override
  void initState() {
    super.initState();
    client = MqttBrowserClient('ws://broker.hivemq.com/mqtt', '');
    connect();
  }

  Future<void> connect() async {
    client.port = 8000; // Port WebSocket cho HiveMQ
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;

    try {
      await client.connect();
      setState(() {
        connectionStatus = 'Connected';
      });
    } catch (e) {
      print('Exception: $e');
      setState(() {
        connectionStatus = 'Connection failed: $e';
      });
      client.disconnect();
    }

    client.subscribe("your_topic/power", MqttQos.atMostOnce);
  }

  void onConnected() {
    print('Connected');
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final String payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);
      print('Received message: $payload from topic: ${c[0].topic}');
      setState(() {
        connectionStatus = 'Message received: $payload';
      });
    });
  }

  void onDisconnected() {
    print('Disconnected');
    setState(() {
      connectionStatus = 'Disconnected';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IoT với ESP32 và Flutter Web'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(connectionStatus,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final builder = MqttClientPayloadBuilder();
                builder.addString('toggle');
                client.publishMessage('your_topic/control', MqttQos.atLeastOnce,
                    builder.payload!);
              },
              child: Text('Bật/Tắt thiết bị'),
            ),
          ],
        ),
      ),
    );
  }
}
