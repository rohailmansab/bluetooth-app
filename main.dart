import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:sensors/sensors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? characteristic;
  AccelerometerEvent? accelerometerData;

  @override
  void initState() {
    super.initState();

    // Check and request Bluetooth permissions.
    checkAndRequestPermissions();

    // Initialize accelerometer
    accelerometerEvents.listen((event) {
      setState(() {
        accelerometerData = event;
      });
      sendAccelerometerData();
    });
  }

  void startBluetoothScanning() {
    flutterBlue.startScan(timeout: Duration(seconds: 4));
    print(flutterBlue.scanResults);
    flutterBlue.scanResults.listen((results) {
      print(results);
      print("This is a debug message!");
      for (ScanResult result in results) {
        print("device name ${result.device.name}"); 
        if (result.device.name == 'Android Bluedroid') {
          print("This is a debug message 2!");
          connectToDevice(result.device);
          break;
        }
      }
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
    }
    await device.connect();
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        if (c.properties.write) {
          setState(() {
            characteristic = c;
            connectedDevice = device;
          });
        }
      }
    }
  }

  void sendAccelerometerData() {
    if (connectedDevice != null && accelerometerData != null && characteristic != null) {
      List<int> data = [
        accelerometerData!.x.toInt(),
        accelerometerData!.y.toInt(),
        accelerometerData!.z.toInt(),
      ];
      characteristic!.write(data);
    }
  }

  Future<void> openBluetoothSettings() async {
    const url = 'package:flutter_settings/settings:open_bluetooth';
    var result = await canLaunch(url);
    print(result);
    if (result) {
      await launch(url);
    } else {
      print('Could not open Bluetooth settings.');
    }
  }

  Future<void> checkAndRequestPermissions() async {
    if (await Permission.bluetooth.isDenied) {
      await Permission.bluetooth.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color interfaceColor = Colors.green;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Bluetooth & Accelerometer'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 200.0,
                height: 200.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: interfaceColor,
                ),
                child: Center(
                  child: Text(
                    "Accelerometer Data\nX: ${accelerometerData?.x ?? 0}\nY: ${accelerometerData?.y ?? 0}\nZ: ${accelerometerData?.z ?? 0}",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              if (connectedDevice == null)
                ElevatedButton(
                  onPressed: () {
                    startBluetoothScanning();
                  },
                  child: Text('Connect to HC-06'),
                ),
              ElevatedButton(
                onPressed: () => AppSettings.openAppSettings(type: AppSettingsType.bluetooth),
                child: Text('Open Bluetooth Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
