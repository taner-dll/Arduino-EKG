import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/services.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';

class DiscoveryPage extends StatefulWidget {


  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPage();
}

class _DiscoveryPage extends State<DiscoveryPage> {
  String _platformVersion = 'Unknown';
  final _bluetoothClassicPlugin = BluetoothClassic();
  List<Device> _devices = [];
  List<Device> _discoveredDevices = [];
  bool _scanning = false;
  Uint8List _data = Uint8List(0);
  final int _deviceStatus = Device.disconnected;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _bluetoothClassicPlugin.onDeviceStatusChanged().listen((event) {
      setState(() {
      });
    });
    _bluetoothClassicPlugin.onDeviceDataReceived().listen((event) {
      setState(() {
        _data = Uint8List.fromList([..._data, ...event]);
      });
    });
  }

  /// Page Scaffold
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _scanning ? const Text('Cihaz Aranıyor...') : const Text('EKG Cihazı Ara'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.bluetooth_searching_rounded, size: 128, color: Colors.blueGrey),
          const SizedBox(height: 20),
          //Text("Device status is $_deviceStatus"),
          TextButton(
            onPressed: () async {
              await _bluetoothClassicPlugin.initPermissions();
            },
            child: const Text("İzinleri Kontrol et"),
          ),
          TextButton(
            onPressed: _deviceStatus == Device.connected
                ? () async {
              await _bluetoothClassicPlugin.disconnect();
            }
                : null,
            child: const Text("disconnect"),
          ),
          TextButton(
            onPressed: _getDevices,
            child: const Text("Bluetooth Cihazlarını Göster (Paired)"),
          ),

          /*Image.asset(
            'assets/images/heart-rate-monitor.png',
            height: 128,
            width: 128,
          ),*/

          Center(
            child: Text('Running on: $_platformVersion\n'),
          ),
          ...[
            for (var device in _devices)
              TextButton(
                  onPressed: () async {
                    await _bluetoothClassicPlugin.connect(device.address, "00001101-0000-1000-8000-00805f9b34fb");
                    setState(() {
                      _discoveredDevices = [];
                      _devices = [];
                    });
                    Get.toNamed('/device-detail', arguments: {
                      'deviceName': device.name,
                      'deviceAddress': device.address
                    });
                  },
                  child: Text(device.name ?? device.address))
          ],

          TextButton(
            onPressed: () {
              setState(() {
                _scanning = true;
              });
              _scan();
            },
            child: Text(_scanning ? "Taramayı Durdur" : "Yeni Tarama Başlat"),
          ),
          ...[for (var device in _discoveredDevices) Text(device.name ?? device.address)],
        ],
      ),
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _bluetoothClassicPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _getDevices() async {
    var res = await _bluetoothClassicPlugin.getPairedDevices();
    setState(() {
      _devices = res;
    });
  }

  Future<void> _scan() async {
    if (_scanning) {
      await _bluetoothClassicPlugin.stopScan();
      setState(() {
        _scanning = false;
      });
    } else {
      await _bluetoothClassicPlugin.startScan();
      _bluetoothClassicPlugin.onDeviceDiscovered().listen(
        (event) {
          setState(() {
            _discoveredDevices = [..._discoveredDevices, event];
          });
        },
      );
      setState(() {
        _scanning = true;
      });
    }
  }
}
