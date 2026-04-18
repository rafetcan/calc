import 'package:shared_preferences/shared_preferences.dart';

/// Her [versionName] için otomatik puan/geri bildirim diyaloğunu en fazla bir kez gösterir.
/// Aynı sürümde hemen sormaz: önce yeterli açılış sayısı gerekir (UX).
class RatingPromptService {
  static const _keyLastVersionPrompted = 'calc_rating_prompt_last_version';
  static const _keyTrackedVersion = 'calc_rating_tracked_version';
  static const _keyLaunchCount = 'calc_rating_launch_count';

  /// Bu sürüm için kaç uygulama açılışından sonra sorulsun (1 = ilk açılışta; önerilen 3+).
  static const int minLaunchesBeforePrompt = 3;

  final SharedPreferences _prefs;

  RatingPromptService(this._prefs);

  /// Her soğuk açılışta çağrılır; sürüm değiştiyse sayaç sıfırlanır.
  void recordLaunchForVersion(String currentVersion) {
    final tracked = _prefs.getString(_keyTrackedVersion);
    if (tracked != currentVersion) {
      _prefs.setString(_keyTrackedVersion, currentVersion);
      _prefs.setInt(_keyLaunchCount, 1);
    } else {
      final c = _prefs.getInt(_keyLaunchCount) ?? 0;
      _prefs.setInt(_keyLaunchCount, c + 1);
    }
  }

  /// [recordLaunchForVersion] sonrası bu sürüm için birikmiş açılış sayısı.
  int launchCountForVersion(String currentVersion) {
    final tracked = _prefs.getString(_keyTrackedVersion);
    if (tracked != currentVersion) return 0;
    return _prefs.getInt(_keyLaunchCount) ?? 0;
  }

  /// Bu sürüm için henüz otomatik sorulmadıysa true.
  bool shouldShowAutoPrompt(String currentVersion) {
    final last = _prefs.getString(_keyLastVersionPrompted);
    if (last == null) return true;
    return last != currentVersion;
  }

  /// Göstermek için: bu sürümde sorulmadı + yeterli açılış.
  bool shouldShowNow(String currentVersion) {
    return shouldShowAutoPrompt(currentVersion) &&
        launchCountForVersion(currentVersion) >= minLaunchesBeforePrompt;
  }

  Future<void> markShownForVersion(String version) async {
    await _prefs.setString(_keyLastVersionPrompted, version);
  }
}
