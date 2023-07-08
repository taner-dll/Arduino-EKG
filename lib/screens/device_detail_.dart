import 'dart:async';
import 'dart:convert';

import 'package:arduino_ekg/screens/results.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:oscilloscope/oscilloscope.dart';
import 'dart:math';
import 'package:collection/collection.dart';

import '../helpers/database_helper.dart';

class DeviceDetailBkp extends StatefulWidget {
  const DeviceDetailBkp({super.key});

  @override
  State<DeviceDetailBkp> createState() => _DeviceDetailBkpState();
}

class _DeviceDetailBkpState extends State<DeviceDetailBkp> {
  /// Değişkenler (Cihaz Detay Ekranı)
  var param = Get.arguments;
  bool isConnected = false;
  bool isProcessing = false;
  bool isStreamListened = false;
  BluetoothConnection? conn;
  List<double> traceX = [];
  List<double> signals = [];
  String message = '';

  String _bmi = '0';
  String _heartRate = '0';
  String _risk = '0';


  StreamSubscription? streamSubscription;
  int pulse = 0;
  int pulseSum = 0;
  int pulseCount = 0;



  _DeviceDetailBkpState();

  /// State initial parametreleri
  @override
  void initState() {
    super.initState();

    setState(() {
      isConnected = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Osiloskop konfigürasyonları

    Oscilloscope scopeX = Oscilloscope(
      //showYAxis: true,
      yAxisColor: Colors.redAccent,
      margin: const EdgeInsets.all(20.0),
      strokeWidth: 1.0,
      backgroundColor: const Color.fromRGBO(252, 232, 229, 1),
      traceColor: Colors.black87,
      yAxisMax: 900.0,
      yAxisMin: -50,
      dataSet: traceX,
      showYAxis: true,
    );

    // Oscilloscope scopeX = Oscilloscope(
    //   showYAxis: true,
    //   yAxisColor: Colors.orange,
    //   margin: const EdgeInsets.all(20.0),
    //   strokeWidth: 1.0,
    //   backgroundColor: Colors.black,
    //   traceColor: Colors.green,
    //   yAxisMax: 1000.0,
    //   yAxisMin: -1.0,
    //   dataSet: traceX,
    // );

    //osilloscope için saturasyon ve kalibrasyon sağlıyor
    Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      setState(() {});
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("EKG & Risk Analizi"),
        actions: <Widget>[
          isProcessing
              ? FittedBox(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : FittedBox(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                    ),
                  ),
                )
        ],
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        color: Theme.of(context).canvasColor,
        child: Center(
          child: Column(
            children: [
              /// Osiloskop alanı
              Expanded(flex: 3, child: scopeX),

              /// Analizi başlat
              Expanded(
                  flex: 1,
                  child: Row(
                    //  Yatay hizlama
                    mainAxisAlignment: MainAxisAlignment.center,
                    //  Yukarıdan-Aşağıya Hizalama
                    crossAxisAlignment: CrossAxisAlignment.center,

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

                                Get.snackbar(
                                  "Bağlantı Kuruldu",
                                  "HC-05",
                                  icon: const Icon(Icons.bluetooth_connected, color: Colors.white),
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: Colors.lightGreen,
                                  borderRadius: 20,
                                  margin: const EdgeInsets.all(15),
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 4),
                                  isDismissible: true,
                                  forwardAnimationCurve: Curves.easeOutBack,
                                );
                              },
                              icon: const Icon(Icons.bluetooth_connected),
                              //icon data for elevated button
                              label: const Text("HC-05"),
                              //label text
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
                            label: const Text("HC-05"),
                            //label text
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.only(left: 5, right: 15),
                          child: OutlinedButton.icon(
                            onPressed: () {
                              //cihaz bağlı değilse devam etme
                              if (!isConnected) {
                                Get.snackbar(
                                  "Bağlı cihaz bulunamadı",
                                  "Lütfen bluetooth bağlantısı kurunuz.",
                                  icon: const Icon(Icons.bluetooth_disabled, color: Colors.white),
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: Colors.red,
                                  borderRadius: 20,
                                  margin: const EdgeInsets.all(15),
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 7),
                                  isDismissible: true,
                                  forwardAnimationCurve: Curves.easeOutBack,
                                );
                              } else {
                                setState(() {
                                  isProcessing = true;
                                });

                                //connection listened önceden başlamışsa
                                if (!isStreamListened) {
                                  setState(() {
                                    isStreamListened = true;
                                  });

                                  conn?.input!.map(ascii.decode).transform(const LineSplitter()).listen((line) {
                                    if (line.contains("!")) {
                                      // print(line);
                                      // setState(() {
                                      //   traceX.add(0.00);
                                      // });
                                    } else {
                                      double newdbl1 = double.parse(line.replaceAll(RegExp(r'[^0-9.]'), ''));
                                      print(newdbl1);

                                      setState(() {
                                        traceX.add(newdbl1);
                                        signals.add(newdbl1);
                                      });

                                    }
                                  });
                                }

                                _bmiHesapla();
                                calculate10YearASCVDRisk();
                              }
                            },
                            icon: const Icon(Icons.play_circle),
                            //icon data for elevated button
                            label: const Text("Başlat"),
                            //label text
                          )),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              traceX.clear();
                              _bmi = '0';
                              _heartRate = '0';
                              _risk = '0';
                              isProcessing = false;
                              signals.clear();
                            });
                          },

                          icon: const Icon(Icons.reset_tv),
                          //icon data for elevated button
                          label: const Text("Reset"),
                          //label text
                          //style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                        ),
                      ),
                    ],
                  )),
              Expanded(
                flex: 1,
                child: Row(
                  //  Yatay hizlama
                  mainAxisAlignment: MainAxisAlignment.center,
                  //  Yukarıdan-Aşağıya Hizalama
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [Text("Vücut Kitle Endeksi (BMI): $_bmi")],
                ),
              ),

              Expanded(
                flex: 1,
                child: Row(
                  //  Yatay hizlama
                  mainAxisAlignment: MainAxisAlignment.center,
                  //  Yukarıdan-Aşağıya Hizalama
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [Text("ASCVD Risk Tahmini (10 yıl): %$_risk")],
                ),
              ),

              Expanded(
                flex: 1,
                child: Row(
                  //  Yatay hizlama
                  mainAxisAlignment: MainAxisAlignment.center,
                  //  Yukarıdan-Aşağıya Hizalama
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [Text("Ortalama Kalp Atış Hızı (bpm): $_heartRate")],
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
                        child: ElevatedButton(
                          onPressed: () async {


                            // nabız hesapla
                            final sum = signals.sum;
                            double rate = (sum / signals.length) * 0.33;


                            // int pulseRate = calculatePulseRate();
                            // print(pulseRate);


                            setState(() {
                              isProcessing = true;

                              _heartRate = rate.toInt().toString();

                            });




                            List<Map> result = await DatabaseHelper.internal().getData();

                            // print the results
                            // ignore: avoid_function_literals_in_foreach_calls
                            result.forEach((row) {
                              String name = row['name'];
                              String surname = row['surname'];
                              int age = row['age'];


                              CollectionReference result = FirebaseFirestore.instance.collection('ekg_results');
                              result.add({

                                'name':name,
                                'surname':surname,
                                'age':age,
                                'bmi':_bmi,
                                'risk':_risk,
                                'bpm':_heartRate,
                                'datetime': DateTime.now(),
                                'signals': signals

                              });

                              //print(signals);

                            });


                            Get.snackbar(
                              "Analiz Kaydedildi",
                              "Tüm sonuçlar ekranında görüntüleyebilirsiniz",
                              icon: const Icon(Icons.storage, color: Colors.white),
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: Colors.lightGreen,
                              borderRadius: 20,
                              margin: const EdgeInsets.all(15),
                              colorText: Colors.white,
                              duration: const Duration(seconds: 4),
                              isDismissible: true,
                              forwardAnimationCurve: Curves.easeOutBack,
                            );

                            setState(() {
                              isProcessing = false;
                            });

                            
                            
                          },
                          child: const Text("Analizi Kaydet", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  )),
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
                          onPressed: () {
                            Get.to(()=> const Results());
                          },
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



  Future<void> _bmiHesapla() async {
    var db = await DatabaseHelper().db;

    //List<Map> result = await db.rawQuery('SELECT * FROM user');
    List<Map> result = await DatabaseHelper.internal().getData();

    // print the results
    // ignore: avoid_function_literals_in_foreach_calls
    result.forEach((row) {
      print(row);

      // Vücut kitle indeksi (BMI) faktörü
      // boy cm cinsinden olduğu için 100'e bölerek metreye dönüştürüyoruz
      double vucutKitleIndeksi = row['weight'] / pow(row['height'] / 100, 2);

      setState(() {
        _bmi = vucutKitleIndeksi.toStringAsFixed(2);
      });
    });

    //print(_bmi);

    setState(() {
      isProcessing = false;
    });

    Get.snackbar(
      "EKG Testi Hazır",
      "Lütfen elektrotlarınız kontrol ediniz",
      icon: const Icon(Icons.accessibility, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue,
      borderRadius: 20,
      margin: const EdgeInsets.all(15),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  /// Bluetooth cihazına mesaj gönderir.
  // void _sendMessage(String data) {
  //   conn!.output.add(Uint8List.fromList(utf8.encode("$data\r\n")));
  //   conn!.output.allSent;
  // }

  /// Bluetooth bağlantısını sonlandırır.
  void _disconnect() {
    if (isConnected) {
      conn!.finish();

      setState(() {
        isConnected = false;
      });

      Get.snackbar(
        "Bağlantı Kesildi",
        "HC-05",
        icon: const Icon(Icons.bluetooth_disabled, color: Colors.white),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        borderRadius: 20,
        margin: const EdgeInsets.all(15),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        isDismissible: true,
        forwardAnimationCurve: Curves.easeOutBack,
      );
    }
  }

  Future<void> calculate10YearASCVDRisk() async {
    //init dummy before db query
    int age = 45;
    int totalCholesterol = 210;
    int hdlCholesterol = 50;
    bool isMale = true;
    bool hasDiabetes = false;
    bool isSmoker = true;
    bool hasHypertension = true;

    var db = await DatabaseHelper().db;

    //List<Map> result = await db.rawQuery('SELECT * FROM user');
    List<Map> result = await DatabaseHelper.internal().getData();

    // print the results
    // ignore: avoid_function_literals_in_foreach_calls
    result.forEach((row) {
      age = row['age'];
      totalCholesterol = row['ldl'];
      hdlCholesterol = row['hdl'];
      //bool isMale = row['gender'];
      hasDiabetes = row['diabetes'] == 1 ? true : false;
      isSmoker = row['smoke'] == 1 ? true : false;
      hasHypertension = row['hypertension'] == 1 ? true : false;
    });

    double riskScore = 0.0;

    // print(age);
    // print(totalCholesterol);
    // print(hdlCholesterol);
    // print(isMale);
    // print(hasDiabetes);
    // print(isSmoker);
    // print(hasHypertension);

    // Yaş faktörü
    if (age >= 40 && age <= 79) {
      riskScore += 17.83;
    }

    // Toplam kolesterol faktörü
    if (totalCholesterol >= 160 && totalCholesterol <= 199) {
      riskScore += 4.94;
    } else if (totalCholesterol >= 200 && totalCholesterol <= 239) {
      riskScore += 7.77;
    } else if (totalCholesterol >= 240) {
      riskScore += 9.68;
    }

    // HDL kolesterol faktörü
    if (hdlCholesterol < 40) {
      riskScore += 2.53;
    } else if (hdlCholesterol >= 40 && hdlCholesterol <= 49) {
      riskScore += 1.63;
    } else if (hdlCholesterol >= 50 && hdlCholesterol <= 59) {
      riskScore += 0.95;
    } else if (hdlCholesterol >= 60) {
      riskScore += 0.0;
    }

    // Cinsiyet faktörü
    if (isMale) {
      riskScore += 3.61;
    }

    // Diyabet faktörü
    if (hasDiabetes) {
      riskScore += 8.43;
    }

    // Sigara faktörü
    if (isSmoker) {
      riskScore += 7.43;
    }

    // Yüksek tansiyon faktörü
    if (hasHypertension) {
      riskScore += 4.96;
    }

    // 10 yıllık risk skorunu yüzde olarak dönüştürme
    double percentRisk = 1.0 - pow(0.9900, exp(riskScore - 22.3287));

    setState(() {
      _risk = (percentRisk * 100.0).toStringAsFixed(2);
    });

    //print(_risk);
  }

  // Function to calculate pulse rate
  int calculatePulseRate() {

    const int samplingInterval = 10; // Time between analog readings in milliseconds
    const int peakThreshold = 500; // Minimum peak amplitude threshold

    // Find peaks
    List<int> peaks = [];
    bool rising = false;

    for (int i = 1; i < signals.length; i++) {
      int delta = signals[i].toInt() - signals[i - 1].toInt();



      if (delta > peakThreshold && !rising) {
        rising = true;
        peaks.add(i);
      } else if (delta < -peakThreshold && rising) {
        rising = false;
      }
    }


    // Calculate time difference between peaks
    int totalTime = (peaks.length - 1) * samplingInterval; // Time between first and last peak
    int averageTime = totalTime ~/ (peaks.length - 1); // Average time difference between peaks

    // Calculate pulse rate
    int pulseRate = (60000 ~/ averageTime); // Convert to beats per minute

    return pulseRate;
  }

  /// Belirtilen aralıkta double değer üretir.
  double doubleInRange(Random source, num start, num end) => source.nextDouble() * (end - start) + start;
}
