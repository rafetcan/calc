import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculation_history.dart';

class HistoryService extends ChangeNotifier {
  final SharedPreferences _prefs;
  static const _historyKey = 'calculator_history';
  List<CalculationHistory> _history = [];

  HistoryService(this._prefs) {
    _loadHistory();
  }

  List<CalculationHistory> getHistory() => List.unmodifiable(_history);

  Future<void> addToHistory(CalculationHistory item) async {
    _history.insert(0, item);
    if (_history.length > 100) {
      _history = _history.take(100).toList();
    }
    await _saveHistory();
    notifyListeners();
  }

  Future<void> removeFromHistory(CalculationHistory item) async {
    _history.remove(item);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
    notifyListeners();
  }

  void _loadHistory() {
    final historyJson = _prefs.getStringList(_historyKey) ?? [];
    _history = historyJson
        .map((item) => CalculationHistory.fromJson(jsonDecode(item)))
        .toList();
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final historyJson =
        _history.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_historyKey, historyJson);
  }
}
