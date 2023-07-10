import 'package:shared_preferences/shared_preferences.dart';

class Settings{
  late final SharedPreferences prefs;
  Settings(){
    init();
  }
  void init() async{
    prefs = await SharedPreferences.getInstance();
    prefs.setBool("multiscan", false);
  }
}