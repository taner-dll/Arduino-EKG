//import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';

class BluetoothController extends GetxController {
  var count = 0.obs;


  void increment() {
    count++;
  }



// Flutter Blue Plus -  BLE
/*  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  Future scanDevices() async {
    flutterBlue.startScan(timeout: const Duration(seconds: 5));
    flutterBlue.stopScan();
  }

  Stream<List<ScanResult>> get scanResults => flutterBlue.scanResults;*/
}
