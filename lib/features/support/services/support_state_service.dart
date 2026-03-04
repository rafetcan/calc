import 'package:shared_preferences/shared_preferences.dart';

const _keyHasSupported = 'calc_has_supported_project';

class SupportStateService {
  final SharedPreferences _prefs;

  SupportStateService(this._prefs);

  bool get hasSupported => _prefs.getBool(_keyHasSupported) ?? false;

  Future<void> setSupported() async {
    await _prefs.setBool(_keyHasSupported, true);
  }
}
