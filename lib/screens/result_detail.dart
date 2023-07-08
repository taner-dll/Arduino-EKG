import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:mailer/mailer.dart';
import 'package:flutter/material.dart';
import 'package:mailer/smtp_server/gmail.dart';



class ResultDetail extends StatelessWidget {


  final DocumentSnapshot document;

  ResultDetail(this.document, {super.key});

  final _email = TextEditingController();



  @override
  Widget build(BuildContext context) {

    String emailHtml = '<h3>BMI (VKİ): </h3>${document['bmi']}\n'
        '<h3>BPM (Heart Rate): </h3>${document['bpm']}\n'
        '<h3>ASCVD risk %: </h3>${document['risk']}\n'
        '<h3>ECG Signals: </h3><p>${document['signals']}</p>\n';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sonuç Detayı'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Icon(Icons.person, size: 48,),
            const SizedBox(height: 8),
            Text(document['name']+" "+document['surname'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
                (document['datetime'] as Timestamp).toDate().toString(),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text("BMI (VKİ): ${document['bmi']}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("BPM (Heart Rate): ${document['bpm']}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("ASCVD risk %: ${document['risk']}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Lütfen e-posta adresi giriniz';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Uzman e-posta adresi giriniz:',
                ),
              ),
            ),
            ElevatedButton(onPressed: () {
              sendEmail(_email.text,emailHtml);
            }, child: const Text("Uzmana Gönder")),

          ],
        ),
      ),
    );
  }
}


void sendEmail(String email, String emailHtml) async {
  String username = 'tnr...@gmail.com';

  //todo silinecek
  String password = '******';

  final smtpServer = gmail(username, password); // E-posta sağlayıcınıza göre smtpServer'ı ayarlayın

  // E-posta başlığı ve içeriği
  final message = Message()
    ..from = Address(username, 'Arduino EKG')
    ..recipients.add(email) // Alıcının e-posta adresini buraya yazın
    ..subject = 'Flutter E-posta Gönderimi'
    ..html = emailHtml;

  try {
    final sendReport = await send(message, smtpServer);
    print('E-posta gönderildi: ${sendReport.toString()}');

    Get.snackbar(
      "E-posta gönderildi",
      "EKG analizi ve risk sonuçları uzmana gönderildi",
      icon: const Icon(Icons.mail, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.lightGreen,
      borderRadius: 20,
      margin: const EdgeInsets.all(15),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
    );

  } catch (e) {
    print('E-posta gönderilemedi: $e');
  }
}