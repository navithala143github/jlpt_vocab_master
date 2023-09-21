import 'package:shared_preferences/shared_preferences.dart';

class PreferencesManager {
  late SharedPreferences _prefs;

  PreferencesManager() {
    initPreferences();
  }

  // Initialize SharedPreferences
  Future<void> initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Getter for the integer value
  int getIntValue(String key, {int defaultValue = 0}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  // Setter for the integer value
  Future<void> setIntValue(String key, int value) async {
    await _prefs.setInt(key, value);
  }
}
