import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/calculator_model.dart';
import '../models/calculation_history.dart';
import '../services/calculator_service.dart';
import '../services/history_service.dart';
import 'package:flutter/foundation.dart';

class CalculatorViewModel extends ChangeNotifier {
  final CalculatorModel _model = CalculatorModel();
  final CalculatorService _calculatorService = CalculatorService();
  final HistoryService _historyService;
  bool _isCalculating = false;
  String _lastError = '';
  int _openParenthesesCount = 0;

  CalculatorViewModel(this._historyService);

  String get displayText => _model.displayText;
  String get result => _model.result;
  bool get hasError => _model.hasError;
  bool get isCalculating => _isCalculating;
  String get lastError => _lastError;
  int get openParenthesesCount => _openParenthesesCount;

  void onButtonPressed(String button) {
    if (_model.hasError) {
      clear();
    }

    // Maksimum karakter sınırı kontrolü
    if (_model.displayText.length >= 50) {
      _showError('calculator.error.too_long'.tr());
      return;
    }

    if (button == '()') {
      _handleParentheses();
      return;
    }

    if (_isOperator(button)) {
      if (_model.displayText.isEmpty && button != '-') {
        return;
      }
      if (_model.displayText.endsWith('+') ||
          _model.displayText.endsWith('-') ||
          _model.displayText.endsWith('×') ||
          _model.displayText.endsWith('÷')) {
        backspace();
      }
    }

    _model.displayText += button;
    if (_model.canCalculate) {
      calculate();
    } else {
      notifyListeners();
    }
  }

  void _handleParentheses() {
    final expression = _model.displayText;
    final openCount = '('.allMatches(expression).length;
    final closeCount = ')'.allMatches(expression).length;

    if (openCount == closeCount) {
      // Açılış parantezi ekleme durumu
      final lastChar =
          expression.isNotEmpty ? expression[expression.length - 1] : '';

      // Eğer son karakter bir sayı veya kapanış parantezi ise, çarpma operatörü ekle
      if (expression.isNotEmpty &&
          !_isOperator(lastChar.toString()) &&
          lastChar != '(') {
        _model.displayText += '×(';
      } else {
        _model.displayText += '(';
      }
    } else if (openCount > closeCount) {
      // Kapanış parantezi ekleme durumu
      final lastChar = expression[expression.length - 1];
      if (!_isOperator(lastChar.toString()) && lastChar != '(') {
        _model.displayText += ')';
      }
    }

    if (_model.canCalculate) {
      calculate();
    } else {
      notifyListeners();
    }
  }

  void clear() {
    _model.clear();
    _calculatorService.clearCache();
    _lastError = '';
    _openParenthesesCount = 0;
    notifyListeners();
  }

  void backspace() {
    if (_model.displayText.isNotEmpty) {
      final lastChar = _model.displayText[_model.displayText.length - 1];

      // Parantez sayısını güncelle
      if (lastChar == '(') {
        _openParenthesesCount--;
      } else if (lastChar == ')') {
        _openParenthesesCount++;
      }

      // Son karakteri sil
      _model.displayText =
          _model.displayText.substring(0, _model.displayText.length - 1);

      if (_model.canCalculate) {
        calculate();
      } else {
        _model.result = '';
        _model.hasError = false;
        _lastError = '';
        notifyListeners();
      }
    }
  }

  Future<void> calculate() async {
    if (_isCalculating) return;

    try {
      _isCalculating = true;
      notifyListeners();

      if (!_model.canCalculate) return;

      if (_openParenthesesCount > 0) {
        throw FormatException('calculator.error.unmatched_parentheses'.tr());
      }

      final result = _calculatorService.evaluate(_model.displayText);
      final newResult = result.toString();

      if (_model.result != newResult) {
        _model.result = newResult;
        _model.hasError = false;
        _lastError = '';

        await _historyService.addToHistory(
          CalculationHistory(
            expression: _model.displayText,
            result: _model.result,
            timestamp: DateTime.now(),
          ),
        );
        notifyListeners();
      }
    } catch (e) {
      if (!_model.hasError) {
        _model.hasError = true;
        _lastError = e.toString().replaceAll('Exception: ', '');
        _model.result = 'calculator.error'.tr();
        notifyListeners();
      }
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }

  void loadFromHistory(CalculationHistory history) {
    if (_model.displayText != history.expression ||
        _model.result != history.result) {
      _model.displayText = history.expression;
      _model.result = history.result;
      _model.hasError = false;
      _lastError = '';
      _openParenthesesCount = _countOpenParentheses(history.expression);
      notifyListeners();
    }
  }

  int _countOpenParentheses(String expression) {
    int count = 0;
    for (final char in expression.split('')) {
      if (char == '(') count++;
      if (char == ')') count--;
    }
    return count;
  }

  void _showError(String message) {
    _model.hasError = true;
    _lastError = message;
    _model.result = message;
    notifyListeners();
  }

  bool _isOperator(String button) {
    return ['+', '-', '×', '÷'].contains(button);
  }

  /// Yapıştırılan metni parse eder ve display'e ekler
  /// Samsung Calculator gibi çalışır: sayılar ve denklemleri kabul eder
  Future<void> pasteText(String? pastedText) async {
    if (pastedText == null || pastedText.trim().isEmpty) {
      return;
    }

    // Metni temizle ve normalize et
    String cleanedText = pastedText.trim();
    
    // Operatörleri normalize et (* -> ×, / -> ÷, x/X -> ×) - önce normalize et
    cleanedText = cleanedText
        .replaceAll('*', '×')
        .replaceAll('/', '÷')
        .replaceAll('x', '×')
        .replaceAll('X', '×');
    
    // Geçersiz karakterleri temizle - sadece sayılar, operatörler, parantezler, nokta
    // - karakteri character class'ın sonunda olmalı (range olarak yorumlanmaması için)
    cleanedText = cleanedText.replaceAll(RegExp(r'[^0-9+×÷().\-]'), '');
    
    // Boşlukları kaldır
    cleanedText = cleanedText.replaceAll(' ', '');
    
    if (cleanedText.isEmpty) {
      _showError('calculator.error.invalid_paste'.tr());
      return;
    }

    // Maksimum uzunluk kontrolü
    if (cleanedText.length > 50) {
      _showError('calculator.error.too_long'.tr());
      return;
    }

    // Hata varsa temizle
    if (_model.hasError) {
      clear();
    }

    // Yapıştırılan metni display'e ekle veya değiştir
    // Samsung Calculator gibi: eğer display boşsa veya son karakter operatörse, ekle
    // Aksi halde, yeni metinle değiştir
    if (_model.displayText.isEmpty || 
        _model.displayText.endsWith('+') ||
        _model.displayText.endsWith('-') ||
        _model.displayText.endsWith('×') ||
        _model.displayText.endsWith('÷')) {
      // Display boş veya son karakter operatör, ekle
      _model.displayText += cleanedText;
    } else {
      // Display dolu, değiştir
      _model.displayText = cleanedText;
    }

    // Parantez sayısını güncelle
    _openParenthesesCount = _countOpenParentheses(_model.displayText);

    // Eğer hesaplanabilirse, hesapla
    if (_model.canCalculate) {
      await calculate();
    } else {
      _model.result = '';
      _model.hasError = false;
      _lastError = '';
      notifyListeners();
    }
  }

  // Diğer işlemler eklenecek
}
