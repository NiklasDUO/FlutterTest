import 'package:notified_preferences/notified_preferences.dart';

class NotifiedSettings with NotifiedPreferences {
  late final PreferenceNotifier<bool> multiscan = createSetting(key: 'multiscan', initialValue: false);
  late final PreferenceNotifier<bool> dupesCheck = createSetting(key: 'DupesCheck', initialValue: true);
  late final PreferenceNotifier<String> dropdownValue = createSetting(key: 'dropdownValue', initialValue: 'MAC');
}