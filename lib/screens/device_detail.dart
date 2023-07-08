import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:oscilloscope/oscilloscope.dart';
import 'dart:math';

class DeviceDetail extends StatefulWidget {
  const DeviceDetail({super.key});

  @override
  State<DeviceDetail> createState() => _DeviceDetailState();
}

class _DeviceDetailState extends State<DeviceDetail> {
  /// Değişkenler (Cihaz Detay Ekranı)
  var param = Get.arguments;
  bool isConnected = false;
  BluetoothConnection? conn;
  List<double> traceX = [];
  int _heartRate = 0;
  int _heartRisk = 0;

  _DeviceDetailState();

  /// State initial parametreleri
  @override
  void initState() {
    super.initState();

    setState(() {
      isConnected = false;
    });
  }

  /// Avoid Memory Leak
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Osiloskop konfigürasyonları

    Oscilloscope scopeX = Oscilloscope(
      showYAxis: true,
      yAxisColor: Colors.redAccent,
      //margin: const EdgeInsets.all(2.0),
      strokeWidth: 0.7,
      backgroundColor: Colors.black12,
      traceColor: Colors.cyan,
      yAxisMax: 1200.0,
      yAxisMin: -1200.0,
      dataSet: traceX,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("EKG Analizi")),
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        color: Theme.of(context).canvasColor,
        child: Center(
          child: Column(
            children: [
              Row(
                //  Yatay hizlama
                mainAxisAlignment: MainAxisAlignment.end,
                //  Yukarıdan-Aşağıya Hizalama
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Icon(
                      Icons.bluetooth_connected,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(left: 10, right: 50),
                      child: Text(
                        param['deviceName'],
                        style: const TextStyle(fontSize: 20),
                      )),
                  const Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Icon(
                      Icons.monitor_heart,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Text(
                        "$_heartRate bpm",
                        style: const TextStyle(fontSize: 20),
                      )),
                ],
              ),

              /// Osiloskop alanı
              Expanded(flex: 5, child: scopeX),


              /// Bluetooth cihazına bağlan / bağlantıyı kes
              /*Expanded(
                  flex: 1,
                  child: Row(
                    //  Yatay hizlama
                    mainAxisAlignment: MainAxisAlignment.start,
                    //  Yukarıdan-Aşağıya Hizalama
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: <Widget>[
                      Visibility(
                        visible: isConnected ? false : true,
                        child: Padding(
                            padding: const EdgeInsets.only(left: 5, right: 10),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                conn = await BluetoothConnection.toAddress(param['deviceAddress']);
                                if (kDebugMode) {
                                  print("device connected");
                                }

                                setState(() {
                                  isConnected = true;
                                });

                                Get.defaultDialog(title: "Bağlantı Kuruldu", middleText: "HC-05");
                              },
                              icon: const Icon(Icons.bluetooth_connected),
                              //icon data for elevated button
                              label: const Text("Bağlan"),
                              //label text
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent //elevated btton background color
                                  ),
                            )),
                      ),
                      Visibility(
                        visible: isConnected ? true : false,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5, right: 10),
                          child: ElevatedButton.icon(
                            onPressed: () => _disconnect(),

                            icon: const Icon(Icons.bluetooth_disabled),
                            //icon data for elevated button
                            label: const Text("Bağlantıyı Kes"),
                            //label text
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent //elevated btton background color
                                ),
                          ),
                        ),
                      ),
                    ],
                  )),*/

              /// Analizi başlat
              Expanded(
                  flex: 1,
                  child: Row(
                    //  Yatay hizlama
                    mainAxisAlignment: MainAxisAlignment.start,
                    //  Yukarıdan-Aşağıya Hizalama
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: OutlinedButton(
                          onPressed: () async {
                            conn?.input!.map(ascii.decode).transform(const LineSplitter()).listen((line) {
                              if (line.contains("!")) {
                                print(line);
                                setState(() {
                                  _heartRate = 0;
                                  _heartRisk = 0;
                                });
                              } else {
                                double newdbl1 = double.parse(line.replaceAll(RegExp(r'[^0-9.]'), ''));
                                print(newdbl1);
                                setState(() {
                                  traceX.add(newdbl1);
                                  _heartRate = _calculateHeartRate(line.replaceAll(RegExp(r'[^0-9.]'), ''));
                                  _heartRisk = _calculateRisk(line.replaceAll(RegExp(r'[^0-9.]'), ''));
                                });
                              }
                            });
                          },
                          child: const Wrap(
                            children: <Widget>[
                              Icon(
                                Icons.favorite,
                                color: Colors.pink,
                                size: 20.0,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text("Başla", style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              traceX.clear();
                              _heartRate = 0;
                              _heartRisk = 0;
                            });
                            conn?.input?.listen((Uint8List data) {
                              print(data);


                            });
                          },
                          child: const Wrap(
                            children: <Widget>[
                              Icon(
                                Icons.cancel,
                                color: Colors.blueGrey,
                                size: 20.0,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text("İptal", style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Wrap(
                            children: <Widget>[
                              Icon(
                                Icons.save,
                                color: Colors.green,
                                size: 20.0,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text("Kaydet", style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )),
              Expanded(
                flex: 5,
                child: Row(
                  //  Yatay hizlama
                  mainAxisAlignment: MainAxisAlignment.start,
                  //  Yukarıdan-Aşağıya Hizalama
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DataTable(columns: [
                      DataColumn(
                          label: Text(
                            'ANALİZ SONUÇLARI'.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )),
                      DataColumn(
                          label: Text(
                            ''.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )),
                    ], rows: const [
                      DataRow(cells: [
                        DataCell(Text('Vücut Kitle Endeksi (BMI):')),
                        DataCell(Text('aa:')),
                      ]),
                      DataRow(cells: [
                        DataCell(Text('Ortalama Kalp Atış Hızı (bpm):')),
                        DataCell(Text('aa:')),
                      ]),
                      DataRow(cells: [
                        DataCell(Text('ASCVD Risk Tahmini (10 yıl):')),
                        DataCell(Text('aa:')),
                      ])
                    ])
                  ],
                ),
              ),
              Expanded(
                  flex: 1,
                  child: Row(
                    //  Yatay hizlama
                    mainAxisAlignment: MainAxisAlignment.center,
                    //  Yukarıdan-Aşağıya Hizalama
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextButton(
                          onPressed: () {},
                          child: const Text("Tüm Sonuçları Göster", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateHeartRate(String sensorValue) {
    // Burada gelen verileri işleyerek kalp atış hızını hesaplayabilirsiniz
    // Örnek olarak basit bir hesaplama yapalım:
    // Kalp atış hızı = 60000 / (sensorValue.toInt() * 10)
    // Bu hesaplama, EKG sensöründen gelen değerlere bağlı olarak değişebilir

    final value = int.tryParse(sensorValue);
    if (value != null) {
      return 60000 ~/ (value * 10);
    } else {
      return 0;
    }
  }

  int _calculateRisk(String sensorValue) {
    final value = int.tryParse(sensorValue);
    if (value != null) {
      int rate = 60000 ~/ (value * 10);

      // TODO yaş bilgisi alarak risk hesapla
      /// nabız risk sınırı default 100 olarak tanımlandı
      if (rate > 100) {
        return 1;
      } else {
        return 0;
      }
    } else {
      return 0;
    }
  }

  /// Bluetooth cihazından gelen verileri işler.
  void _onDataReceived() {}

  /// Bluetooth cihazına mesaj gönderir.
  void _sendMessage(String data) {
    conn!.output.add(Uint8List.fromList(utf8.encode("$data\r\n")));
    conn!.output.allSent;
  }

  /// Bluetooth bağlantısını sonlandırır.
  void _disconnect() {
    if (isConnected) {
      conn!.finish();

      setState(() {
        isConnected = false;
      });

      Get.defaultDialog(title: "Bağlantı Kesildi", middleText: "HC-05");
    }
  }

  /// Belirtilen aralıkta double değer üretir.
  double doubleInRange(Random source, num start, num end) => source.nextDouble() * (end - start) + start;
}
