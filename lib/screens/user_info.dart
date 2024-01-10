import 'package:arduino_ekg/helpers/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class UserInfo extends StatefulWidget {
  const UserInfo({Key? key}) : super(key: key);

  @override
  State<UserInfo> createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo> {
  final _formKey = GlobalKey<FormState>();

  // kişisel bilgiler
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _birthdayController = TextEditingController();
  String _gender = "Erkek";

  //final _genderController = TextEditingController(); //todo dropdown controller?
  // bmi
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  final int _stepLength = 3;
  int _currentStep = 0;
  DateTime? _selectedDate;

  //sağlık bilgileri
  bool _smoker = false;
  bool _diabetes = false;
  bool _hypertension = false;
  final _totalLDL = TextEditingController();
  final _hdl = TextEditingController();

  @override
  void initState() {
    super.initState();

    _getFormData();

    //todo DB'de kayıtlı verilerle formu doldur
    //_nameController.text = "aaa";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _birthdayController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    //_genderController.dispose();
    _totalLDL.dispose();
    _hdl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arduino EKG - Gerekli Bilgiler'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Stepper(
            controlsBuilder: (context, ControlsDetails details) {
              return Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: stepControls(details),
              );
            },
            currentStep: _currentStep,
            onStepContinue: () {
              stepContinue();
            },
            onStepCancel: () {
              stepCancel();
            },
            steps: steps(),
            onStepTapped: (int step) {
              setState(() {
                _currentStep = step;
              });
            },
          ),
        ),
      ),
    );
  }

  List<Step> steps() {
    return [
      Step(
          title: const Text('Kullanıcı Bilgileri'),
          content: Column(
            children: [
              TextFormField(
                controller: _nameController,
                validator: (value) {
                  if (value!.isEmpty) {
                    _nameController.text = 'Taner';
                    //return 'Lütfen adınızı giriniz';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Adınız:',
                ),

              ),
              TextFormField(
                controller: _surnameController,
                validator: (value) {
                  if (value!.isEmpty) {
                    _surnameController.text = 'Dll';
                    //return 'Lütfen soyadınızı giriniz';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Soyadınız:',
                ),
              ),
              TextFormField(
                controller: _birthdayController,
                readOnly: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    _birthdayController.text = '15-03-1988';
                    //return 'Lütfen doğum tarihinizi giriniz';
                  }
                  return null;
                },
                onTap: () => _showDatePicker(context),

                decoration:
                    const InputDecoration(labelText: 'Doğum Tarihiniz:', suffixIcon: Icon(Icons.calendar_today)),
              ),
              DropdownButtonFormField<String>(
                items: <String>['Erkek', 'Kadın'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _gender = value!;
                  });
                },
                value: 'Erkek',
                decoration: const InputDecoration(labelText: 'Cinsiyet:'),
              ),
              const SizedBox(height: 20),
            ],
          ),
          state: _currentStep == 0 ? StepState.editing : StepState.indexed,
          isActive: _currentStep == 0 ? true : false),
      Step(
          title: const Text('Vücut Kitle Endeksi (BMI) Hesaplama Bilgileri'),
          content: Column(
            children: [
              TextFormField(
                controller: _heightController,
                maxLength: 3,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value!.isEmpty) {
                    _heightController.text = '177';
                    //return 'Lütfen boyunuzu cm cinsinden giriniz';
                  }
                  // You can add more complex email validation logic here
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Boy (cm):',
                ),
              ),
              TextFormField(
                controller: _weightController,
                maxLength: 3,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value!.isEmpty) {
                    _weightController.text = '92';
                    //return 'Lütfen ağırlığınızı kilogram cinsinden giriniz';
                  }
                  // You can add more complex email validation logic here
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Ağırlık (kg):',
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
          state: _currentStep == 1 ? StepState.editing : StepState.indexed,
          isActive: _currentStep == 1 ? true : false),
      Step(
          title: const Text('ASCVD Kardiyovasküler Risk Hesaplama Bilgileri'),
          content: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                alignment: AlignmentDirectional.topStart,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    //color: Colors.blueGrey,
                    border: Border.all(color: Colors.blueGrey, style: BorderStyle.solid, width: 1.0)),
                child: const Text(
                  'ASCVD risk hesaplama yöntemi, American College of Cardiology (ACC) algoritması ile uyumludur.',
                  style: TextStyle(
                      //color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold
                      //fontSize: 20,
                      ),
                ),
              ),
              SwitchListTile(
                title: const Text('Sigara Kullanımı'),
                value: _smoker,
                onChanged: (value) {
                  setState(() {
                    _smoker = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Diyabet Tedavisi'),
                value: _diabetes,
                onChanged: (value) {
                  setState(() {
                    _diabetes = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Hipertansiyon Tedavisi'),
                value: _hypertension,
                onChanged: (value) {
                  setState(() {
                    _hypertension = value;
                  });
                },
              ),
              TextFormField(
                controller: _totalLDL,
                maxLength: 3,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value!.isEmpty) {
                    _totalLDL.text = '110';
                    //return 'Lütfen LDL bilgisi giriniz';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Toplam LDL Kolesterol (mg/dl):',
                ),
              ),
              TextFormField(
                controller: _hdl,
                maxLength: 3,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value!.isEmpty) {
                    _hdl.text = '45';
                    //return 'Lütfen HDL bilgisi giriniz';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'HDL Kolesterol (mg/dl):',
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
          state: _currentStep == 2 ? StepState.editing : StepState.indexed,
          isActive: _currentStep == 2 ? true : false),
    ];
  }

  void stepContinue() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        if (_currentStep < _stepLength - 1) {
          _currentStep++;
          print(_currentStep);
        } else {
          _submitForm();
        }
      });
    } else {
      if (_nameController.text.isEmpty || _surnameController.text.isEmpty || _birthdayController.text.isEmpty) {
        setState(() {
          _currentStep = 0;
        });
      } else if (_heightController.text.isEmpty || _weightController.text.isEmpty) {
        setState(() {
          _currentStep = 1;
        });
      } else {
        setState(() {
          _currentStep = 2;
        });
      }
    }
  }

  List<Widget> stepControls(ControlsDetails details) {
    return <Widget>[
      ElevatedButton(
        onPressed: details.onStepCancel,
        child: const Text('Önceki'),
      ),
      ElevatedButton(
        onPressed: details.onStepContinue,
        child: const Text('Sonraki'),
      ),
    ];
  }

  void stepCancel() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      } else {
        _currentStep = 0;
      }
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Formu başarıyla gönderme işlemleri burada yapılabilir
      // Örneğin, kullanıcı bilgilerini bir veritabanına kaydedebilirsiniz

      //analiz bilgilerini db'ye kaydet.
      Map<String, dynamic> data = {
        "name": _nameController.text,
        "surname": _surnameController.text,
        "age": 36, //todo d.tarihi -> yaş
        "gender": _gender,
        "height": _heightController.text,
        "weight": _weightController.text,
        "smoke": _smoker,
        "diabetes": _diabetes,
        "hypertension": _hypertension,
        "ldl": _totalLDL.text,
        "hdl": _hdl.text
      };

      var db = await DatabaseHelper().db;
      //db.insert("user", data);
      db.update("user", data);

      // Formu sıfırlamak için aşağıdaki satırları ekleyebilirsiniz
      _nameController.clear();
      _surnameController.clear();
      _birthdayController.clear();
      _heightController.clear();
      _totalLDL.clear();
      _hdl.clear();
      setState(() {
        _currentStep = 0;
      });

      //Get.toNamed('/discovery-page');
      Get.toNamed('/discovery-page');
    }
  }

  void _getFormData() async {


    var db = await DatabaseHelper().db;

    // await db.execute("CREATE TABLE user(id INTEGER PRIMARY KEY, name TEXT, surname TEXT,"
    //     "age INTEGER, gender TEXT, "
    //     "height INTEGER, weight INTEGER, "
    //     "smoke BOOLEAN, diabetes BOOLEAN, hypertension BOOLEAN, "
    //     "ldl INTEGER, hdl INTEGER)");

    //drop table
    //await db.execute("DROP TABLE IF EXISTS user");



    //List<Map> result = await db.rawQuery('SELECT * FROM user');
    List<Map> result = await DatabaseHelper.internal().getData();

    // print the results
    // ignore: avoid_function_literals_in_foreach_calls
    result.forEach((row) {

      //print(row);

      _nameController.text = row['name'].toString();
      _surnameController.text = row['surname'].toString();
      _heightController.text = row['height'].toString();
      _weightController.text = row['weight'].toString();
      _smoker = row['smoke'] == 0 ? false : true;
      _diabetes = row['diabetes'] == 0 ? false : true;
      _hypertension = row['hypertension'] == 0 ? false : true;
      _totalLDL.text = row['ldl'].toString();
      _hdl.text = row['hdl'].toString();
      _birthdayController.text = '15-03-1988';

    });
  }

  void _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Başlangıç tarihi
      firstDate: DateTime(1960), // İlk tarih seçeneği
      lastDate: DateTime(2025), // Son tarih seçeneği
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthdayController.text = DateFormat('dd-MM-yyyy').format(_selectedDate!);
      });
    }
  }
}
