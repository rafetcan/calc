class CalculatorService {
  // Hesaplama sonuçlarını önbellekleme
  final Map<String, double> _cache = {};

  double evaluate(String expression) {
    if (expression.trim().isEmpty) {
      throw const FormatException('Empty expression');
    }

    // Önbellekten kontrol
    if (_cache.containsKey(expression)) {
      return _cache[expression]!;
    }

    // Operatörleri standartlaştır
    expression = expression.replaceAll('×', '*').replaceAll('÷', '/');

    // Parantez dengesi kontrolü
    int balance = 0;
    for (int i = 0; i < expression.length; i++) {
      if (expression[i] == '(') balance++;
      if (expression[i] == ')') balance--;
      if (balance < 0) throw const FormatException('Unmatched parentheses');
    }
    if (balance != 0) throw const FormatException('Unmatched parentheses');

    // Parantezleri işle
    while (expression.contains('(')) {
      int openIndex = -1;
      int closeIndex = -1;
      int depth = 0;
      int maxDepth = 0;
      int maxDepthOpenIndex = -1;

      // En içteki parantezi bul
      for (int i = 0; i < expression.length; i++) {
        if (expression[i] == '(') {
          depth++;
          if (depth > maxDepth) {
            maxDepth = depth;
            maxDepthOpenIndex = i;
          }
        } else if (expression[i] == ')') {
          if (depth == maxDepth && openIndex == maxDepthOpenIndex) {
            closeIndex = i;
            break;
          }
          depth--;
        }
      }

      openIndex = maxDepthOpenIndex;

      if (openIndex == -1 || closeIndex == -1) {
        throw const FormatException('Invalid parentheses');
      }

      // Parantez içindeki ifadeyi al ve hesapla
      final subExpr = expression.substring(openIndex + 1, closeIndex);
      if (subExpr.isEmpty) {
        throw const FormatException('Empty parentheses');
      }

      final subResult = evaluate(subExpr);

      // Parantez öncesi ve sonrası kısımları al
      final beforeParentheses =
          openIndex > 0 ? expression.substring(0, openIndex) : '';
      final afterParentheses = closeIndex < expression.length - 1
          ? expression.substring(closeIndex + 1)
          : '';

      // İmplicit çarpma kontrolü
      String newExpression = beforeParentheses;

      // Parantez öncesi çarpma kontrolü
      if (beforeParentheses.isNotEmpty) {
        final lastChar = beforeParentheses[beforeParentheses.length - 1];
        if (!_isOperator(lastChar) && lastChar != '(') {
          newExpression += '*';
        }
      }

      newExpression += subResult.toString();

      // Parantez sonrası çarpma kontrolü
      if (afterParentheses.isNotEmpty) {
        final firstChar = afterParentheses[0];
        if (!_isOperator(firstChar) && firstChar != ')') {
          newExpression += '*';
        }
        newExpression += afterParentheses;
      }

      expression = newExpression;
    }

    // İşlem önceliğine göre hesapla
    List<String> tokens = _tokenize(expression);
    if (tokens.isEmpty) {
      throw const FormatException('Empty expression');
    }

    // Negatif sayıları işle
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == '-' && (i == 0 || _isOperator(tokens[i - 1]))) {
        if (i + 1 < tokens.length) {
          tokens[i + 1] = (-double.parse(tokens[i + 1])).toString();
          tokens.removeAt(i);
          i--;
        }
      }
    }

    // Çarpma ve bölme
    for (int i = 1; i < tokens.length - 1; i++) {
      if (tokens[i] == '*' || tokens[i] == '/') {
        final a = double.parse(tokens[i - 1]);
        final b = double.parse(tokens[i + 1]);

        if (tokens[i] == '/' && b == 0) {
          throw const FormatException('Division by zero');
        }

        final result = tokens[i] == '*' ? a * b : a / b;
        tokens[i - 1] = _formatResult(result);
        tokens.removeRange(i, i + 2);
        i--;
      }
    }

    // Toplama ve çıkarma
    double result = double.parse(tokens[0]);
    for (int i = 1; i < tokens.length - 1; i += 2) {
      final b = double.parse(tokens[i + 1]);
      if (tokens[i] == '+') {
        result += b;
      } else if (tokens[i] == '-') {
        result -= b;
      }
    }

    final finalResult = _formatResult(result);
    _cache[expression] = double.parse(finalResult);
    return double.parse(finalResult);
  }

  List<String> _tokenize(String expression) {
    List<String> tokens = [];
    String number = '';
    bool hasDecimal = false;

    for (int i = 0; i < expression.length; i++) {
      final char = expression[i];

      if (char.contains(RegExp(r'[0-9]'))) {
        number += char;
      } else if (char == '.' && !hasDecimal) {
        number += char;
        hasDecimal = true;
      } else if (_isOperator(char)) {
        if (number.isNotEmpty) {
          tokens.add(number);
          number = '';
          hasDecimal = false;
        }
        tokens.add(char);
      } else if (char == ' ') {
        if (number.isNotEmpty) {
          tokens.add(number);
          number = '';
          hasDecimal = false;
        }
        continue;
      }
    }

    if (number.isNotEmpty) {
      tokens.add(number);
    }

    return tokens;
  }

  bool _isOperator(String token) {
    return ['+', '-', '*', '/', '(', ')'].contains(token);
  }

  String _formatResult(double result) {
    if (result.abs() > 1e10 || (result.abs() < 1e-10 && result != 0)) {
      return result.toStringAsExponential(10);
    }

    if (result == result.toInt()) {
      return result.toInt().toString();
    }

    return result
        .toStringAsFixed(10)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  // Önbelleği temizle
  void clearCache() {
    _cache.clear();
  }
}
