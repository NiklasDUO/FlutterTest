import 'package:flutter/material.dart';
import 'package:mainflutter/utilities/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utilities/notifiedsettings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SharedPreferences prefs;
  late NotifiedSettings notifiedSettings;

  @override
  void initState() {
    super.initState();
  }
   _SettingsPageState() {
    initSharedPreferences();
   }

  Future<void> initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    notifiedSettings = NotifiedSettings();
    notifiedSettings.initialize();
    setState(() {}); // Trigger a rebuild after initializing prefs
  }

  @override
  Widget build(BuildContext context) {
    if (prefs == null) {
      // Show a loading indicator or handle the case when prefs is not initialized yet
      return const CircularProgressIndicator();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.all(10),
        child: Center(
          child: Column(
            children: [
              Row(
                children: [
                  const Text("Sound"),
                  Switch(
                    value: prefs.getBool("SoundEnabled") as bool,
                    onChanged: (value) {
                      setState(() {
                        prefs.setBool("SoundEnabled", value);
                      });
                      prefs.setBool("SoundEnabled", value);
                      print(prefs.getBool("SoundEnabled"));
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  const Text("Vibro"),
                  Switch(
                    value: prefs.getBool("VibroEnabled") as bool,
                    onChanged: (value) {
                      setState(() {
                        prefs.setBool("VibroEnabled", value);
                      });
                    },
                  ),

                ],
              ),
              Row(
                children: [
                  const Text("Dupes Check"),
                  ValueListenableBuilder(valueListenable: notifiedSettings.dupesCheck,
                    builder: (context, value, child) {
                      return Switch(
                        value: notifiedSettings.dupesCheck.value,
                        onChanged: (value) {
                          notifiedSettings.dupesCheck.value = value;
                        },
                      );
                    }
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*TODO
  * 1. Зміна кольорів
  * 2. Вкл/викл звук
  * 3. Вкл/викл вібрацію
  * 4. Вкл/викл мультискан
  * 5. Інтервал мультискану
  * 6. Вкл/викл дуплікати
  * 7. Про/звикла версія
  * 8. Темна тема
  * 9. Зміна розміру шрифтів
  * 10. Параметри пошуку Емайл/мак/посилання/
  * 11. Зміна сортування індентифікатор  min/max max/min
*/
