import 'package:shared_preferences/shared_preferences.dart';

class Settings{
  late final SharedPreferences prefs;
    Settings(){
    init();
  }
  void init() async{
    prefs = await SharedPreferences.getInstance();
    prefs.setBool("multiscan", false);
    prefs.setString('theme', "green");
    prefs.setBool("SoundEnabled", true);
    prefs.setBool("VibroEnabled", true);
    prefs.setBool("LightEnabled", true);
    prefs.setBool("DupesCheck", false);
    prefs.setInt("FontSize", 12);
    prefs.setBool("AscendingOrder", false);
    prefs.setBool("DarkTheme", true);
    prefs.setBool("zoom",false);
  }
}