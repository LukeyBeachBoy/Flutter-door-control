import 'dart:async';
import 'package:my_app/models/message.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(title: 'Door Control System'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String server = 'm24.cloudmqtt.com';
  int port = 12432;
  String user = 'dprfbxja';
  String password = 'dprfbxja';
  String topic = 'Door';
  Set<String> topics = Set<String>();
  List<Message> messages = <Message>[];
  StreamSubscription subscription;
  mqtt.MqttClient client;
  mqtt.MqttConnectionState connectionState;

  String _batteryPercentage = 'Battery percentage';

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    IconData connectionStateIcon;
    switch (client?.connectionState) {
      case mqtt.MqttConnectionState.connected:
        connectionStateIcon = Icons.cloud_done;
        break;
      case mqtt.MqttConnectionState.disconnected:
        connectionStateIcon = Icons.cloud_off;
        break;
      case mqtt.MqttConnectionState.connecting:
        connectionStateIcon = Icons.cloud_upload;
        break;
      case mqtt.MqttConnectionState.disconnecting:
        connectionStateIcon = Icons.cloud_download;
        break;
      case mqtt.MqttConnectionState.faulted:
        connectionStateIcon = Icons.error;
        break;
      default:
        connectionStateIcon = Icons.cloud_off;
    }

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Stack(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        children: <Widget>[
          new Container(
              decoration: new BoxDecoration(
                  image: new DecorationImage(
                      image: new AssetImage('assets/images/background.png'),
                      fit: BoxFit.cover))),
          new Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  connectionStateIcon,
                  size: 100,
                ),
                MaterialButton(
                  minWidth: 250,
                  color: Colors.redAccent,
                  onPressed: () {
                    if (client?.connectionState ==
                        mqtt.MqttConnectionState.connected) {
                      _disconnect();
                    } else
                      _connect();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      client?.connectionState ==
                              mqtt.MqttConnectionState.connected
                          ? 'Disconnect'
                          : 'Connect',
                      style: TextStyle(color: Colors.white, fontSize: 35),
                    ),
                  ),
                ),
                Container(
                    margin: EdgeInsets.all(20),
                    child: Column(
                      children: <Widget>[
                        MaterialButton(
                          onPressed: _unlockDoor,
                          minWidth: 250,
                          // onPressed: _getBatteryInformation,
                          color: Colors.greenAccent,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Unlock',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 35),
                            ),
                          ),
                        ),
                        MaterialButton(
                          onPressed: _lockDoor,
                          minWidth: 250,
                          // onPressed: _getBatteryInformation,
                          color: Colors.deepOrangeAccent,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Lock',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 35),
                            ),
                          ),
                        ),
                      ],
                    ))
              ],
            ),
          )
        ],
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future _connect() async {
    client = mqtt.MqttClient.withPort(server, '', port);
    client.onDisconnected = _onDisconnected;

    final mqtt.MqttConnectMessage connMess = mqtt.MqttConnectMessage()
        .authenticateAs('dprfbxja', '_3rLfEpgyHqs')
        .withClientIdentifier('Mqtt_MyClientUniqueId2')
        // Must agree with the keep alive set above or not set
        .startClean() // Non persistent session for testing
        .keepAliveFor(600)
        // If you set this you must set a will message
        .withWillTopic('Door')
        .withWillMessage('Mobile connected')
        .withWillQos(mqtt.MqttQos.atLeastOnce);
    print('MQTT client connecting....');
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } catch (e) {
      print(e);
      _disconnect();
    }

    if (client.connectionState == mqtt.MqttConnectionState.connected) {
      print('MQTT client connected');
      setState(() {
        connectionState = client.connectionState;
        _subscribeToTopic('Door');
      });
    } else {
      print('ERROR: MQTT client connection failed - '
          'disconnecting, state is ${client.connectionState}');
      _disconnect();
    }
    subscription = client.updates.listen(_onMessage);
  }

  void _disconnect() {
    client.disconnect();
    _onDisconnected();
  }

  void _onDisconnected() {
    setState(() {
      topics.clear();
      connectionState = client.connectionState;
      client = null;
      subscription.cancel();
      subscription = null;
    });
    print('MQTT client disconnected');
  }

  void _onMessage(List<mqtt.MqttReceivedMessage> event) {
    print(event.length);
    final mqtt.MqttPublishMessage recMess =
        event[0].payload as mqtt.MqttPublishMessage;
    final String message =
        mqtt.MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    /// The above may seem a little convoluted for users only interested in the
    /// payload, some users however may be interested in the received publish message,
    /// lets not constrain ourselves yet until the package has been in the wild
    /// for a while.
    /// The payload is a byte buffer, this will be specific to the topic
    print('MQTT message: topic is <${event[0].topic}>, '
        'payload is <-- ${message} -->');
    print(client.connectionState);
    setState(() {
      messages.add(Message(
        topic: event[0].topic,
        message: message,
        qos: recMess.payload.header.qos,
      ));
    });
  }

  void _subscribeToTopic(String topic) {
    if (connectionState == mqtt.MqttConnectionState.connected) {
      setState(() {
        if (topics.add(topic.trim())) {
          print('Subscribing to ${topic.trim()}');
          client.subscribe(topic, mqtt.MqttQos.exactlyOnce);
        }
      });
    }
  }

  void _unlockDoor() {
    final mqtt.MqttClientPayloadBuilder builder =
        mqtt.MqttClientPayloadBuilder();
    builder.addString('unlock');
    client.publishMessage('Door', mqtt.MqttQos.exactlyOnce, builder.payload);
  }

  void _lockDoor() {
    final mqtt.MqttClientPayloadBuilder builder =
        mqtt.MqttClientPayloadBuilder();
    builder.addString('lock');
    client.publishMessage('Door', mqtt.MqttQos.exactlyOnce, builder.payload);
  }
  // static const batteryChannel = const MethodChannel('battery');
  // Future<void> _getBatteryInformation() async {
  //   String batteryPercentage;
  //   try {
  //     var res = await batteryChannel.invokeMethod('getBatteryLevel');
  //     batteryPercentage = 'Battery level at $res%';
  //   } on PlatformException catch (e) {
  //     batteryPercentage = "Failed to get battery level: '${e.message}'.";
  //   }
  //   setState(() {
  //     _batteryPercentage = batteryPercentage;
  //   });
  // }
}
