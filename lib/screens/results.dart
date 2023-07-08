import 'package:arduino_ekg/screens/result_detail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';


class Results extends StatefulWidget {
  const Results({Key? key}) : super(key: key);

  @override
  State<Results> createState() => _ResultsState();
}

class _ResultsState extends State<Results> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sonuçlar (Firestore)'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('ekg_results').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Veri alınamıyor: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Firestore'dan gelen verileri ListView.builder ile listeleyin
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              Map<String, dynamic> veri = document.data() as Map<String, dynamic>;

              String dt = '-';
              if(veri.containsKey('datetime')){ //containsValue.
                DateTime dtime = (veri['datetime'] as Timestamp).toDate();
                dt = dtime.toString();
              }

              return ListTile(
                title: Text(veri['name']+" "+veri['surname']),
                subtitle: Text(dt),
                //todo detay sayfasına git
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultDetail(document),
                    ),
                  );

                },
              );
            },
          );
        },
      ),
    );
  }
}
