import 'package:arduino_ekg/screens/device_detail_.dart';
import 'package:arduino_ekg/screens/discovery_page.dart';
import 'package:arduino_ekg/screens/user_info.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


Future<void> main() async {

  runApp(const MyApp());

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

}

//FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey
        ,
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const UserInfo()),
        GetPage(
            name: '/device-detail',
            page: () => const DeviceDetailBkp(),
            transition: Transition.leftToRight),
        GetPage(
            name: '/discovery-page',
            page: () => const DiscoveryPage(),
            transition: Transition.leftToRight)
      ],
    );
  }
}





