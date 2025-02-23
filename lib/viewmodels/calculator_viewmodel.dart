import 'package:flutter/material.dart';
import '../models/calculator_model.dart';
import '../services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class CalculatorViewModel extends ChangeNotifier {
  final AdService _adService = AdService();
  CalculatorModel _model = CalculatorModel();
  final List<String> _history = [];
  bool _isScreenLocked = false;
  final _numberFormat = NumberFormat('#,###', 'tr_TR');
  DateTime? _lastOperation;
  static const _minOperationInterval = Duration(milliseconds: 100);

  String get expression => _model.expression;
  String get result => _model.result;
  BannerAd? get bannerAd => _adService.bannerAd;
  List<String> get history => _history;
  bool get isScreenLocked => _isScreenLocked;

  CalculatorViewModel() {
    _initAds();
  }

  void _initAds() {
    _adService.loadBannerAd(
      onAdLoaded: () => notifyListeners(),
      onAdFailedToLoad: (_) {},
    );
  }

  void onButtonPressed(String buttonText) {
    // Rate limiting
    if (_lastOperation != null) {
      final timeSinceLastOp = DateTime.now().difference(_lastOperation!);
      if (timeSinceLastOp < _minOperationInterval) {
        return; // Çok hızlı işlemleri engelle
      }
    }
    _lastOperation = DateTime.now();

    try {
      switch (buttonText) {
        case 'C':
          _model = CalculatorModel();
          break;
        case '=':
          if (_model.expression.isEmpty) {
            _model = _model.copyWith(result: 'İfade boş');
            break;
          }
          try {
            final resultValue = _evaluateExpression(_model.expression);
            final formattedResult = _formatResult(resultValue);
            _history.add('${_model.expression} = $formattedResult');
            _model = _model.copyWith(
              result: formattedResult,
              expression: formattedResult,
            );
          } catch (e) {
            String errorMessage = 'Hata';
            if (e.toString().contains('Sıfıra bölme')) {
              errorMessage = 'Sıfıra bölünemez';
            } else if (e.toString().contains('Parantez')) {
              errorMessage = 'Parantez hatası';
            } else if (e.toString().contains('Format')) {
              errorMessage = 'Geçersiz format';
            }
            _model = _model.copyWith(result: errorMessage);
          }
          break;
        case '⌫':
          if (_model.expression.isNotEmpty) {
            _model = _model.copyWith(
              expression: _model.expression.substring(
                0,
                _model.expression.length - 1,
              ),
            );
          }
          break;
        case '( )':
          _handleParentheses();
          break;
        case '%':
          if (_model.expression.isEmpty) {
            _model = _model.copyWith(result: 'İfade boş');
            break;
          }
          try {
            final value = double.parse(_model.expression);
            _model = _model.copyWith(expression: (value / 100).toString());
          } catch (e) {
            _model = _model.copyWith(result: 'Geçersiz sayı');
          }
          break;
        case '+/-':
          if (_model.expression.isEmpty) {
            _model = _model.copyWith(result: 'İfade boş');
            break;
          }
          try {
            // Son sayıyı bul ve işaretini değiştir
            String expr = _model.expression;
            int lastIndex = expr.length - 1;

            // Son karakterden geriye doğru sayı olmayan karakteri bul
            while (lastIndex >= 0 &&
                (isDigit(expr[lastIndex]) || expr[lastIndex] == '.')) {
              lastIndex--;
            }

            if (lastIndex < 0) {
              // Tüm ifade bir sayı
              _model = _model.copyWith(
                expression: expr.startsWith('-') ? expr.substring(1) : '-$expr',
              );
            } else {
              // Sayı operatörden sonra geliyor
              String beforeNumber = expr.substring(0, lastIndex + 1);
              String number = expr.substring(lastIndex + 1);
              if (number.startsWith('-')) {
                _model = _model.copyWith(
                  expression: beforeNumber + number.substring(1),
                );
              } else {
                _model = _model.copyWith(
                  expression: beforeNumber + '-' + number,
                );
              }
            }
          } catch (e) {
            _model = _model.copyWith(result: 'İşaret değiştirilemedi');
          }
          break;
        case '.':
          // Son sayıda zaten nokta varsa ekleme
          if (_hasDecimalPoint()) {
            break;
          }
          // Boşsa veya son karakter operatörse 0. ekle
          if (_model.expression.isEmpty ||
              _isOperator(_model.expression[_model.expression.length - 1])) {
            _model = _model.copyWith(expression: _model.expression + '0.');
          } else {
            _model = _model.copyWith(expression: _model.expression + '.');
          }
          break;
        default:
          if (_isOperator(buttonText)) {
            if (_model.expression.isEmpty) {
              // İlk karakter - değilse operatörü ekleme
              if (buttonText != '-') break;
            } else {
              // Son karakter operatörse değiştir
              final lastChar = _model.expression[_model.expression.length - 1];
              if (_isOperator(lastChar.toString())) {
                _model = _model.copyWith(
                  expression:
                      _model.expression.substring(
                        0,
                        _model.expression.length - 1,
                      ) +
                      buttonText,
                );
                break;
              }
            }
          }
          _model = _model.copyWith(expression: _model.expression + buttonText);
      }
    } catch (e) {
      debugPrint('Calculator Error: $e'); // Güvenli loglama
      _model = _model.copyWith(result: 'Hata');
    }
    notifyListeners();
  }

  void _handleParentheses() {
    final expression = _model.expression;
    final openCount = '('.allMatches(expression).length;
    final closeCount = ')'.allMatches(expression).length;

    if (openCount == closeCount) {
      final lastChar =
          expression.isNotEmpty ? expression[expression.length - 1] : '';
      if (expression.isEmpty ||
          _isOperator(lastChar.toString()) ||
          lastChar == '(') {
        _model = _model.copyWith(expression: expression + '(');
      } else {
        _model = _model.copyWith(expression: expression + '×(');
      }
    } else {
      _model = _model.copyWith(expression: expression + ')');
    }
  }

  bool _isOperator(String text) {
    return text == '+' || text == '-' || text == '×' || text == '÷';
  }

  double _evaluateExpression(String expression) {
    try {
      expression = expression.replaceAll('×', '*');
      expression = expression.replaceAll('÷', '/');

      // Negatif sayıları işle
      expression = expression.replaceAll('--', '+');

      // İşlem önceliği için parantezleri kontrol et
      while (expression.contains('(') && expression.contains(')')) {
        final openIndex = expression.lastIndexOf('(');
        final closeIndex = expression.indexOf(')', openIndex);
        if (closeIndex == -1) throw Exception('Parantez hatası');

        final subExpr = expression.substring(openIndex + 1, closeIndex);
        final result = _calculateBasicExpression(subExpr);
        expression =
            expression.substring(0, openIndex) +
            result.toString() +
            expression.substring(closeIndex + 1);
      }

      return _calculateBasicExpression(expression);
    } catch (e) {
      throw Exception('Hesaplama hatası');
    }
  }

  double _calculateBasicExpression(String expression) {
    try {
      // Çarpma ve bölme işlemlerini önce yap
      List<String> tokens = expression.split(RegExp(r'([+\-*/])'));
      List<String> operators =
          expression
              .split(RegExp(r'[^+\-*/]+'))
              .where((o) => o.isNotEmpty)
              .toList();

      // İlk sayıyı al
      double result = double.parse(tokens[0].trim());

      // Önce çarpma ve bölme
      for (int i = 0; i < operators.length; i++) {
        if (operators[i] == '*' || operators[i] == '/') {
          double number = double.parse(tokens[i + 1].trim());
          if (operators[i] == '*') {
            result *= number;
          } else {
            if (number == 0) throw Exception('Sıfıra bölme hatası');
            result /= number;
          }
          // İşlenen sayıları ve operatörleri kaldır
          tokens.removeAt(i + 1);
          operators.removeAt(i);
          i--;
        }
      }

      // Sonra toplama ve çıkarma
      for (int i = 0; i < operators.length; i++) {
        double number = double.parse(tokens[i + 1].trim());
        if (operators[i] == '+') {
          result += number;
        } else if (operators[i] == '-') {
          result -= number;
        }
      }

      return result;
    } catch (e) {
      throw Exception('Hesaplama hatası');
    }
  }

  String _formatResult(double value) {
    if (value.isInfinite || value.isNaN) {
      return 'Error';
    }

    if (value % 1 == 0) {
      return _numberFormat.format(value.toInt());
    } else {
      String numStr = value.toString();
      List<String> parts = numStr.split('.');
      String integerPart = _numberFormat.format(int.parse(parts[0]));
      return parts.length > 1 ? '$integerPart.${parts[1]}' : integerPart;
    }
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void toggleScreenLock() {
    _isScreenLocked = !_isScreenLocked;
    if (_isScreenLocked) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
    notifyListeners();
  }

  bool isDigit(String char) {
    return RegExp(r'[0-9]').hasMatch(char);
  }

  bool _hasDecimalPoint() {
    String expr = _model.expression;
    int lastOperatorIndex = -1;

    // Son operatörün indeksini bul
    for (int i = expr.length - 1; i >= 0; i--) {
      if (_isOperator(expr[i])) {
        lastOperatorIndex = i;
        break;
      }
    }

    // Son sayıyı kontrol et
    String lastNumber = expr.substring(lastOperatorIndex + 1);
    return lastNumber.contains('.');
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _adService.dispose();
    super.dispose();
  }
}
