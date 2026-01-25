import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/services/theme_service.dart';
import '../services/history_service.dart';
import 'history_view.dart';
import '../../feedback/services/feedback_service.dart';
import '../../feedback/views/feedback_dialog.dart';

class CalculatorView extends StatefulWidget {
  const CalculatorView({super.key});

  @override
  State<CalculatorView> createState() => _CalculatorViewState();
}

class _CalculatorViewState extends State<CalculatorView> {
  String _display = '0';
  String _expression = '';
  bool _shouldResetDisplay = false;

  void _onButtonPressed(String value) {
    setState(() {
      if (_shouldResetDisplay) {
        _display = '0';
        _expression = '';
        _shouldResetDisplay = false;
      }

      if (value == 'C') {
        _display = '0';
        _expression = '';
      } else if (value == '=') {
        try {
          double result = _evaluateExpression(_expression);
          _display = _formatNumber(result);
          // Sonucu expression'a kaydet (binlik ayracı olmadan)
          _expression = result.toString();
          _shouldResetDisplay = true;
        } catch (e) {
          _display = 'Hata';
          _expression = '';
          _shouldResetDisplay = true;
        }
      } else if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
          if (_expression.isEmpty) {
            _display = '0';
          } else {
            _display = _formatExpression(_expression);
          }
        } else {
          _display = '0';
        }
      } else {
        _expression += value;
        _display = _formatExpression(_expression);
      }
    });
  }

  String _formatExpression(String expr) {
    // İfadeyi formatla ve göster
    // Binlik ayracı eklemek için sayıları parse et
    if (expr.isEmpty) return '0';

    String formatted = '';
    String currentNumber = '';

    for (int i = 0; i < expr.length; i++) {
      String char = expr[i];
      if (_isDigit(char) ||
          char == '.' ||
          (char == '-' &&
              currentNumber.isEmpty &&
              (i == 0 || !_isDigit(expr[i - 1]) && expr[i - 1] != ')'))) {
        currentNumber += char;
      } else {
        if (currentNumber.isNotEmpty) {
          try {
            double num = double.parse(currentNumber);
            formatted += _formatNumber(num);
          } catch (e) {
            formatted += currentNumber;
          }
          currentNumber = '';
        }
        formatted += char;
      }
    }

    if (currentNumber.isNotEmpty) {
      try {
        double num = double.parse(currentNumber);
        formatted += _formatNumber(num);
      } catch (e) {
        formatted += currentNumber;
      }
    }

    return formatted.isEmpty ? '0' : formatted;
  }

  String _formatNumber(double number) {
    // Binlik ayracı ekle
    if (number == number.toInt()) {
      // Tam sayı
      String numStr = number.toInt().toString();
      return _addThousandSeparator(numStr);
    } else {
      // Ondalık sayı
      String numStr = number.toString();
      if (numStr.contains('.')) {
        List<String> parts = numStr.split('.');
        String intPart = _addThousandSeparator(parts[0]);
        String decPart = parts[1];
        // Ondalık kısmı maksimum 10 haneye sınırla
        if (decPart.length > 10) {
          decPart = decPart.substring(0, 10);
        }
        return '$intPart.$decPart';
      }
      return _addThousandSeparator(numStr);
    }
  }

  String _addThousandSeparator(String number) {
    bool isNegative = number.startsWith('-');
    if (isNegative) {
      number = number.substring(1);
    }

    String result = '';
    int count = 0;
    for (int i = number.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result = '.$result';
      }
      result = number[i] + result;
      count++;
    }

    return isNegative ? '-$result' : result;
  }

  bool _isDigit(String char) {
    return char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
  }

  double _evaluateExpression(String expression) {
    if (expression.isEmpty) return 0;

    // Boşlukları temizle
    expression = expression.replaceAll(' ', '');

    // Parantezleri recursive olarak çöz (içten dışa)
    return _evaluateWithParentheses(expression);
  }

  double _evaluateWithParentheses(String expression) {
    // Parantezleri bul ve çöz (içten dışa)
    while (expression.contains('(')) {
      // En içteki parantez çiftini bul (en sağdaki açılış parantezinden başla)
      int start = expression.lastIndexOf('(');
      if (start == -1) break;

      int end = expression.indexOf(')', start);
      if (end == -1) {
        throw Exception('Parantez hatası: Kapanmayan parantez');
      }

      // Parantez içindeki ifadeyi çöz
      String subExpr = expression.substring(start + 1, end);
      if (subExpr.isEmpty) {
        throw Exception('Boş parantez');
      }

      // İç içe parantezler için recursive çağrı
      double subResult = _evaluateWithParentheses(subExpr);

      // Sonucu string'e çevir
      String resultStr = _formatResultForExpression(subResult);

      // Parantez öncesi karakteri kontrol et
      bool needsMultiplication = false;
      if (start > 0) {
        String before = expression[start - 1];
        // Eğer önünde sayı veya parantez kapanışı varsa çarpma işlemi gerekir
        // Operatör veya açılış parantezi varsa çarpma gerekmez
        if ((_isDigit(before) || before == ')') &&
            before != '+' &&
            before != '-' &&
            before != '*' &&
            before != '/' &&
            before != '(') {
          needsMultiplication = true;
        }
      }

      // Parantez sonrası karakteri kontrol et
      bool needsMultiplicationAfter = false;
      if (end + 1 < expression.length) {
        String after = expression[end + 1];
        // Eğer sonrasında sayı veya açılış parantezi varsa çarpma işlemi gerekir
        // Operatör veya kapanış parantezi varsa çarpma gerekmez
        if ((_isDigit(after) || after == '(') &&
            after != '+' &&
            after != '-' &&
            after != '*' &&
            after != '/' &&
            after != ')') {
          needsMultiplicationAfter = true;
        }
      }

      // Expression'ı güncelle
      String beforePart = start > 0 ? expression.substring(0, start) : '';
      String afterPart =
          end + 1 < expression.length ? expression.substring(end + 1) : '';

      String newExpression = beforePart;
      if (needsMultiplication) {
        newExpression += '*';
      }
      newExpression += resultStr;
      if (needsMultiplicationAfter) {
        newExpression += '*';
      }
      newExpression += afterPart;

      expression = newExpression;
    }

    return _evaluateSimpleExpression(expression);
  }

  String _formatResultForExpression(double result) {
    // Sonucu string'e çevir, negatif sayıları doğru işle
    if (result == result.toInt()) {
      return result.toInt().toString();
    } else {
      // Ondalık kısmı sınırla
      String str = result.toString();
      if (str.contains('e') || str.contains('E')) {
        // Bilimsel gösterim
        return str;
      }
      // Çok uzun ondalık kısımları kısalt
      if (str.length > 15) {
        return result
            .toStringAsFixed(10)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
      }
      return str;
    }
  }

  double _evaluateSimpleExpression(String expression) {
    if (expression.isEmpty) return 0;

    // Tokenize: sayıları ve operatörleri ayır
    List<String> tokens = _tokenize(expression);
    if (tokens.isEmpty) return 0;

    // Önce çarpma ve bölme işlemlerini yap
    for (int i = 1; i < tokens.length - 1; i += 2) {
      if (tokens[i] == '*' || tokens[i] == '/') {
        double left = double.parse(tokens[i - 1]);
        double right = double.parse(tokens[i + 1]);
        double result = tokens[i] == '*' ? left * right : left / right;

        tokens[i - 1] = result.toString();
        tokens.removeAt(i);
        tokens.removeAt(i);
        i -= 2;
      }
    }

    // Sonra toplama ve çıkarma işlemlerini yap
    double result = double.parse(tokens[0]);
    for (int i = 1; i < tokens.length; i += 2) {
      double num = double.parse(tokens[i + 1]);
      if (tokens[i] == '+') {
        result += num;
      } else if (tokens[i] == '-') {
        result -= num;
      }
    }

    return result;
  }

  List<String> _tokenize(String expression) {
    List<String> tokens = [];
    String currentNumber = '';

    for (int i = 0; i < expression.length; i++) {
      String char = expression[i];
      if (_isDigit(char) || char == '.') {
        currentNumber += char;
      } else if (char == '+' || char == '-' || char == '*' || char == '/') {
        if (currentNumber.isNotEmpty) {
          tokens.add(currentNumber);
          currentNumber = '';
        }
        // Negatif sayıları işle
        if (char == '-' &&
            (tokens.isEmpty ||
                tokens.last == '+' ||
                tokens.last == '-' ||
                tokens.last == '*' ||
                tokens.last == '/')) {
          currentNumber = '-';
        } else {
          tokens.add(char);
        }
      } else if (char == 'e' || char == 'E') {
        // Bilimsel gösterim desteği (örn: 1e5)
        if (currentNumber.isNotEmpty) {
          currentNumber += char;
        }
      }
    }

    if (currentNumber.isNotEmpty) {
      tokens.add(currentNumber);
    }

    return tokens;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.feedback_outlined),
            tooltip: 'feedback.title'.tr(),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => FeedbackDialog(
                  feedbackService: context.read<FeedbackService>(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'app.history'.tr(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryView(
                    historyService: context.read<HistoryService>(),
                  ),
                ),
              );
            },
          ),
          Consumer<ThemeService>(
            builder: (context, themeService, _) {
              return IconButton(
                icon: Icon(
                  themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                tooltip: themeService.isDarkMode
                    ? 'theme.light'.tr()
                    : 'theme.dark'.tr(),
                onPressed: themeService.toggleTheme,
              );
            },
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Ekran
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        _display,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Butonlar
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('C', isOperator: true),
                          _buildButton('(', isOperator: true),
                          _buildButton(')', isOperator: true),
                          _buildButton('/', isOperator: true),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('7'),
                          _buildButton('8'),
                          _buildButton('9'),
                          _buildButton('*', isOperator: true),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('4'),
                          _buildButton('5'),
                          _buildButton('6'),
                          _buildButton('-', isOperator: true),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('1'),
                          _buildButton('2'),
                          _buildButton('3'),
                          _buildButton('+', isOperator: true),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton('⌫', isOperator: true),
                          _buildButton('0'),
                          _buildButton('.'),
                          _buildButton('=', isOperator: true, isEquals: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    String text, {
    bool isOperator = false,
    bool isEquals = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: isEquals
              ? Theme.of(context).colorScheme.primary
              : isOperator
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _onButtonPressed(text),
            child: Container(
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: isEquals
                      ? Theme.of(context).colorScheme.onPrimary
                      : isOperator
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
