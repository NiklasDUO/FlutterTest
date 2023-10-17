import 'package:flutter/material.dart';
import 'package:mainflutter/utilities/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SharedPreferences prefs;
  final Settings settings = Settings();

  @override
  void initState() {
    super.initState();
    initSharedPreferences();
  }

  Future<void> initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {}); // Trigger a rebuild after initializing prefs
  }

  @override
  Widget build(BuildContext context) {
    if (prefs == null) {
      // Show a loading indicator or handle the case when prefs is not initialized yet
      return CircularProgressIndicator();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            Row(
              children: [
                const Text("Sound"),
                Switch(
                  value: prefs.getBool("Sound") ?? false,
                  onChanged: (value) {
                    setState(() {
                      prefs.setBool("Sound", value);
                    });
                  },
                ),
              ],
            ),

          ],
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
