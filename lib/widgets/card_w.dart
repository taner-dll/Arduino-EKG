import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CardW extends StatelessWidget {
  const CardW({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Card ve InkWell Kullanımı'),
        ),
        body: Column(
          children: [
            Card(
              child: InkWell(
                onTap: () {
                  print('Kart tıklandı!');
                  Get.defaultDialog();
                },
                child: const ListTile(
                  leading: Icon(
                    Icons.album,
                    size: 50,
                  ),
                  title: Text("title 1."),
                  subtitle: Text("subtitle 1."),
                  trailing: Icon(Icons.arrow_right),
                ),
              ),
            ),
            Card(
              child: InkWell(
                onTap: () {
                  print('Kart tıklandı!');
                  Get.defaultDialog();
                },
                child: const ListTile(
                  leading: Icon(
                    Icons.album,
                    size: 50,
                  ),
                  title: Text("title 1"),
                  subtitle: Text("subtitle 1"),
                  trailing: Icon(Icons.arrow_right),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
