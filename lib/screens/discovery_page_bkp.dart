import 'dart:async';

import 'package:bluetooth_enable_fork/bluetooth_enable_fork.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'discovery_page_device_list.dart';

class DiscoveryPage extends StatefulWidget {

  // If autostart is true, the device scanning will start automatically.
  final bool autostart;
  const DiscoveryPage({super.key, this.autostart = true});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPage();
}




class _DiscoveryPage extends State<DiscoveryPage> {


  /// Değişkenler (Cihaz Arama Ekranı)
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;

  List<BluetoothDiscoveryResult> results =
      List<BluetoothDiscoveryResult>.empty(growable: true);

  bool isDiscovering = false;
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  bool isConnected = false;
  BluetoothConnection? conn;




  _DiscoveryPage();





  /// State initial parametreleri
  @override
  void initState() {
    super.initState();




    // BT bağlantı durumunu al
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });





    // BT bağlantı değişikliklerini state'e aktar
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
    });




    BluetoothEnable.enableBluetooth.then((result) {
      if (result == "false") {
        customEnableBT(context);
      } else if (result == "true") {
        isDiscovering = widget.autostart;
        if (isDiscovering) {
          _startDiscovery();
        }
      }
    });



    if (kDebugMode) {
      print(FlutterBluetoothSerial.instance.address);
    }


  }




  /// BT cihaz aramayı yeniden başlatan fonksiyon
  /// _startDiscovery() fonksiyonunu da tetikler
  void _restartDiscovery() {
    results.clear();

    BluetoothEnable.enableBluetooth.then((result) {
      if (result == "false") {
        customEnableBT(context);
      } else if (result == "true") {
        setState(() {
          isDiscovering = true;
        });

        _startDiscovery();
      }
    });
  }




  void _startDiscovery() {
    _streamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        final existingIndex = results.indexWhere(
            (element) => element.device.address == r.device.address);
        if (existingIndex >= 0) {
          results[existingIndex] = r;
        } else {
          results.add(r);
        }
      });
    });

    _streamSubscription!.onDone(() {
      setState(() {
        isDiscovering = false;
      });
    });
  }


  /// Bellek sızıntılarını önlemek için dispose işlemi
  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and cancel discovery
    _streamSubscription?.cancel();
    super.dispose();
  }



  /// Page Scaffold
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: isDiscovering
            ? const Text('Cihaz Aranıyor...')
            : const Text('EKG Cihazı Ara'),
        actions: <Widget>[
          isDiscovering
              ? FittedBox(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.replay),
                  onPressed: _restartDiscovery,
                )
        ],
      ),


      body: Column(
        children: [
          const SizedBox(height: 20),

          SwitchListTile(
              title: const Text('Bluetooth Aç/Kapat'),
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                // Do the request and update with the true value then
                future() async {
                  if (value) {
                    await FlutterBluetoothSerial.instance.requestEnable();
                  } else {
                    await FlutterBluetoothSerial.instance.requestDisable();
                    setState(() {
                      isDiscovering = false;
                    });
                  }
                }
                future().then((_) {
                  setState(() {});
                });
              }),


          /*Image.asset(
            'assets/images/heart-rate-monitor.png',
            height: 128,
            width: 128,
          ),*/

          const Icon(Icons.bluetooth_searching_rounded, size: 128, color: Colors.blueGrey),


          const SizedBox(height: 20),


          ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (BuildContext context, index) {
              BluetoothDiscoveryResult result = results[index];
              final device = result.device;
              //final address = device.address;
              return Card(
                child: DiscoveryPageDeviceList(
                  device: device,
                  rssi: result.rssi,
                  onTap: () {
                    var deviceName_ = device.name;
                    var deviceAddress_ = device.address;
                    //FlutterBluetoothSerial.instance.openSettings();
                    Get.toNamed('/device-detail', arguments: {
                      'deviceName': deviceName_,
                      'deviceAddress': deviceAddress_
                    });
                  },

                ),
              );
            },
          ),




        ],
      ),
    );
  }



  /// Bluetooth cihazlarını kapatmak için bir fonksiyon
  void kapatBluetoothCihazlarini() async {
    // Bluetooth cihazlarını ara ve listele
    List<BluetoothDevice> cihazlar =
        await FlutterBluetoothSerial.instance.getBondedDevices();

    // Tüm cihazları kapat
    for (BluetoothDevice cihaz in cihazlar) {
      await FlutterBluetoothSerial.instance
          .removeDeviceBondWithAddress(cihaz.address); // Cihazı
      // eşleştirme listesinden kaldır
    }
  }


  Future<void> customEnableBT(BuildContext context) async {
    String dialogTitle = "Hey! Please give me permission to use Bluetooth!";
    bool displayDialogContent = true;
    String dialogContent = "This app requires Bluetooth to connect to device.";
    String cancelBtnText = "Nope";
    String acceptBtnText = "Sure";
    double dialogRadius = 10.0;
    bool barrierDismissible = true; //

    BluetoothEnable.customBluetoothRequest(
            context,
            dialogTitle,
            displayDialogContent,
            dialogContent,
            cancelBtnText,
            acceptBtnText,
            dialogRadius,
            barrierDismissible)
        .then((value) {
      //print(value);
    });
  }
}
