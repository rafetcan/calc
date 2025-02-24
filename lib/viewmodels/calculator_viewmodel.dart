import 'package:flutter/material.dart';
import '../models/calculator_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CalculatorViewModel extends ChangeNotifier {
  CalculatorModel _model = CalculatorModel();
  final List<String> _history = [];
  final _numberFormat = NumberFormat('#,###', 'tr_TR');
  DateTime? _lastOperation;
  static const _minOperationInterval = Duration(milliseconds: 100);

  String get expression => _model.expression;
  String get result => _model.result;
  List<String> get history => _history;

  CalculatorViewModel() {
    // _initAds() metodunu kaldır
  }

  void onButtonPressed(String buttonText, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
            _model = _model.copyWith(result: l10n.expressionEmpty);
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
            String errorMessage = l10n.formatError;
            if (e.toString().contains('division by zero')) {
              errorMessage = l10n.divisionByZero;
            } else if (e.toString().contains('parenthesis')) {
              errorMessage = l10n.parenthesisError;
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
            _model = _model.copyWith(result: l10n.expressionEmpty);
            break;
          }

          try {
            String expr = _model.expression;

            // Eğer ifade sadece bir sayıdan oluşuyorsa
            if (!expr.contains(RegExp(r'[+\-×÷]'))) {
              _model = _model.copyWith(
                expression: expr.startsWith('-') ? expr.substring(1) : '-$expr',
              );
              break;
            }

            // Son operatörün konumunu bul
            int lastOperatorIndex = -1;
            for (int i = expr.length - 1; i >= 0; i--) {
              if (_isOperator(expr[i])) {
                lastOperatorIndex = i;
                break;
              }
            }

            // Eğer son karakter operatörse işlem yapma
            if (lastOperatorIndex == expr.length - 1) break;

            String beforeOperator = expr.substring(0, lastOperatorIndex + 1);
            String number = expr.substring(lastOperatorIndex + 1);

            // Sayının işaretini değiştir
            String newNumber =
                number.startsWith('-') ? number.substring(1) : '-$number';

            _model = _model.copyWith(expression: beforeOperator + newNumber);
          } catch (e) {
            _model = _model.copyWith(result: l10n.formatError);
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
      String errorMessage = l10n.formatError;
      if (e.toString().contains('division by zero')) {
        errorMessage = l10n.divisionByZero;
      } else if (e.toString().contains('parenthesis')) {
        errorMessage = l10n.parenthesisError;
      }
      _model = _model.copyWith(result: errorMessage);
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
      // × ve ÷ işaretlerini * ve / ile değiştir
      expression = expression.replaceAll('×', '*').replaceAll('÷', '/');

      // Parantezleri işle
      while (expression.contains('(') && expression.contains(')')) {
        final openIndex = expression.lastIndexOf('(');
        final closeIndex = expression.indexOf(')', openIndex);
        if (closeIndex == -1) throw Exception('parenthesis');

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
      // İfadeyi tokenlara ayır
      List<String> tokens = [];
      String number = '';
      bool isNegative = false;

      // İfadeyi parse et
      for (int i = 0; i < expression.length; i++) {
        String char = expression[i];

        // Boşlukları atla
        if (char.trim().isEmpty) continue;

        // Sayı veya nokta ise
        if (isDigit(char) || char == '.') {
          number += char;
          continue;
        }

        // Sayı bittiyse listeye ekle
        if (number.isNotEmpty) {
          tokens.add(isNegative ? '-$number' : number);
          number = '';
          isNegative = false;
        }

        // Operatör kontrolü
        if (char == '-' &&
            (tokens.isEmpty || tokens.last == '*' || tokens.last == '/')) {
          isNegative = true;
        } else if (_isOperator(char) || char == '*' || char == '/') {
          tokens.add(char);
        }
      }

      // Son sayıyı ekle
      if (number.isNotEmpty) {
        tokens.add(isNegative ? '-$number' : number);
      }

      // Çarpma ve bölme işlemlerini yap
      int i = 0;
      while (i < tokens.length) {
        if (tokens[i] == '*' || tokens[i] == '/') {
          double num1 = double.parse(tokens[i - 1]);
          double num2 = double.parse(tokens[i + 1]);
          double result;

          if (tokens[i] == '*') {
            result = num1 * num2;
          } else {
            if (num2 == 0) throw Exception('division by zero');
            result = num1 / num2;
          }

          tokens[i - 1] = result.toString();
          tokens.removeAt(i);
          tokens.removeAt(i);
        } else {
          i++;
        }
      }

      // Toplama ve çıkarma işlemlerini yap
      double result = double.parse(tokens[0]);
      for (i = 1; i < tokens.length - 1; i += 2) {
        double number = double.parse(tokens[i + 1]);
        if (tokens[i] == '+') {
          result += number;
        } else if (tokens[i] == '-') {
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
}
