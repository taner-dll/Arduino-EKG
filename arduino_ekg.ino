#include <Arduino.h>

void setup() {
  // Seri Port haberleşme hızı 9600bit/s Baud rate 9600'e ayarlayalım.
  Serial.begin(9600);

  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(8, OUTPUT);

  //EKG sensör
  pinMode(10, INPUT);
  pinMode(11, INPUT);
}

void loop() {

  // EKG Kontrolü
  // EKG Elektrotları boşta iken 1 gönderir.
  // Elektrot boşta iken bağlantıyı dinlemeyi sonlandırabiliriz.
  if ((digitalRead(10) == 1) || (digitalRead(11) == 1)) {
    Serial.println('!');
  } else {
    // send the value of analog input 0:
    Serial.println(analogRead(A0));
  }

  //  //Doygunluk için bekletiyoruz. BT sinyali gecikmeye neden oluyor.
  delay(500);  // Pause

}