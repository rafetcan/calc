import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/services/theme_service.dart';
import '../services/history_service.dart';
import '../models/calculation_history.dart';
import 'history_view.dart';
import '../../feedback/services/feedback_service.dart';
import '../../feedback/services/rating_prompt_service.dart';
import '../../feedback/views/feedback_dialog.dart';
import '../../support/views/support_dialog.dart';
import '../../support/services/ad_service.dart';
import '../../support/services/support_state_service.dart';
import '../../../core/di/locator.dart';

class CalculatorView extends StatefulWidget {
  const CalculatorView({super.key});

  @override
  State<CalculatorView> createState() => _CalculatorViewState();
}

class _CalculatorViewState extends State<CalculatorView> {
  /// Overflow menüdeki yıldız (geri bildirim) satırını göstermek için `true` yap.
  static const bool _showFeedbackMenuItem = false;

  /// Sadece gösterge metnini günceller; tüm `Scaffold`/`AppBar`/tuş ızgarasını
  /// her basışta yeniden kurmaz — giriş gecikmesini ve kare düşmesini azaltır.
  final ValueNotifier<String> _displayNotifier = ValueNotifier<String>('0');

  String _expression = '';
  bool _shouldResetDisplay = false;
  bool _isSupportDialogOpen = false;

  bool _isOperatorOrParen(String value) =>
      value == '+' || value == '-' || value == '*' || value == '/' ||
      value == '(' || value == ')';
  bool _isNumberOrDot(String value) =>
      RegExp(r'^[0-9.]$').hasMatch(value);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowVersionRatingPrompt();
    });
  }

  @override
  void dispose() {
    _displayNotifier.dispose();
    super.dispose();
  }

  /// Her sürüm için en fazla bir kez; aynı sürümde en az [minLaunchesBeforePrompt]
  /// açılıştan sonra ve kısa gecikmeyle (hemen açılışta sorma).
  Future<void> _maybeShowVersionRatingPrompt() async {
    if (!mounted || kIsWeb) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;
      if (!mounted) return;

      final ratingPrompt = context.read<RatingPromptService>();
      ratingPrompt.recordLaunchForVersion(version);
      if (!mounted) return;

      if (!ratingPrompt.shouldShowNow(version)) return;
      if (!mounted) return;

      // Ana ekran bir süre görünsün; soğuk açılışta diyalog absürt olmasın
      await Future<void>.delayed(const Duration(seconds: 4));
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => FeedbackDialog(
          feedbackService: ctx.read<FeedbackService>(),
        ),
      );

      if (mounted) {
        await ratingPrompt.markShownForVersion(version);
      }
    } catch (_) {
      // PackageInfo veya dialog hatası — bir sonraki açılışta tekrar dene
    }
  }

  void _onButtonPressed(String value) {
    if (value == 'C') {
      _expression = '';
      _shouldResetDisplay = false;
      _displayNotifier.value = '0';
      return;
    }
    if (_shouldResetDisplay) {
      // = sonrası: C/⌫ dışında sonuç üzerinden devam
      if (value == '⌫') {
        _expression = '';
        _shouldResetDisplay = false;
        _displayNotifier.value = '0';
      } else if (_isOperatorOrParen(value)) {
        // Operatör veya parantez: sonuca ekle (örn: 8 + 5 = 13, sonra + → 13+)
        _expression += value;
        _shouldResetDisplay = false;
        _displayNotifier.value = _formatExpression(_expression);
      } else if (_isNumberOrDot(value)) {
        // Rakam veya nokta: yeni sayı ile başla
        _expression = value;
        _shouldResetDisplay = false;
        _displayNotifier.value = _formatExpression(_expression);
      }
      return;
    }

    if (value == '=') {
      final exprBeforeEval = _expression;
      try {
        final double result = _evaluateExpression(_expression);
        final String resultStr = _formatResultForExpression(result);
        _displayNotifier.value = _formatNumber(result);
        _expression = resultStr;
        _shouldResetDisplay = true;

        final historyItem = CalculationHistory(
          expression: exprBeforeEval,
          result: resultStr,
          timestamp: DateTime.now(),
        );
        // SharedPreferences I/O ve notifyListeners setState döngüsünde olmasın;
        // bir sonraki karede çalıştır — ekran güncellemesi önce çizilsin.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<HistoryService>().addToHistory(historyItem);
        });
      } catch (_) {
        _expression = '';
        _shouldResetDisplay = true;
        _displayNotifier.value = 'calculator.error'.tr();
      }
      return;
    }

    if (value == '⌫') {
      if (_expression.isNotEmpty) {
        _expression = _expression.substring(0, _expression.length - 1);
        _displayNotifier.value = _expression.isEmpty
            ? '0'
            : _formatExpression(_expression);
      } else {
        _displayNotifier.value = '0';
      }
      return;
    }

    _expression += value;
    _displayNotifier.value = _formatExpression(_expression);
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
        throw Exception('calculator.error.missing_parenthesis'.tr());
      }

      // Parantez içindeki ifadeyi çöz
      String subExpr = expression.substring(start + 1, end);
      if (subExpr.isEmpty) {
        throw Exception('calculator.error.empty_parenthesis'.tr());
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
            icon: const Icon(Icons.history),
            tooltip: 'History'.tr(),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryView(
                    historyService: context.read<HistoryService>(),
                  ),
                ),
              );
              if (!mounted) return;
              if (result != null && result is CalculationHistory) {
                _expression = result.expression;
                _shouldResetDisplay = false;
                _displayNotifier.value = _formatExpression(result.expression);
              }
            },
          ),
          Builder(
            builder: (context) {
              final hasSupported = context.read<SupportStateService>().hasSupported;
              return IconButton(
                icon: Icon(
                  Icons.favorite,
                  color: (_isSupportDialogOpen || hasSupported)
                      ? Colors.red
                      : Colors.black,
                ),
                tooltip: 'app.support'.tr(),
                onPressed: () async {
                  setState(() => _isSupportDialogOpen = true);
                  await showDialog(
                    context: context,
                    builder: (context) => SupportDialog(
                      adService: getIt.get<AdService>(),
                      onSupportSuccess: () => setState(() {}),
                    ),
                  );
                  if (mounted) setState(() => _isSupportDialogOpen = false);
                },
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            tooltip: 'app.settings'.tr(),
            onSelected: (value) {
              if (value == 'theme') {
                context.read<ThemeService>().toggleTheme();
              } else if (value == 'report_error') {
                showDialog<void>(
                  context: context,
                  builder: (context) => FeedbackDialog(
                    feedbackService: context.read<FeedbackService>(),
                    directMessageForm: true,
                    submissionType: 'bug',
                  ),
                );
              } else if (value == 'feedback') {
                showDialog(
                  context: context,
                  builder: (context) => FeedbackDialog(
                    feedbackService: context.read<FeedbackService>(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'theme',
                child: Consumer<ThemeService>(
                  builder: (context, themeService, _) => Row(
                    children: [
                      Icon(
                        themeService.isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                      ),
                      const SizedBox(width: 12),
                      Text(themeService.isDarkMode
                          ? 'Light Theme'.tr()
                          : 'Dark Theme'.tr()),
                    ],
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'report_error',
                child: Row(
                  children: [
                    Icon(
                      Icons.bug_report_outlined,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Text('feedback.type.bug'.tr()),
                  ],
                ),
              ),
              if (_showFeedbackMenuItem)
                PopupMenuItem<String>(
                  value: 'feedback',
                  child: Row(
                    children: [
                      const Icon(Icons.star_border),
                      const SizedBox(width: 12),
                      Text('feedback.title'.tr()),
                    ],
                  ),
                ),
            ],
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
                    ValueListenableBuilder<String>(
                      valueListenable: _displayNotifier,
                      builder: (context, display, _) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Text(
                            display,
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        );
                      },
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

  bool _isNumberButton(String text) {
    return RegExp(r'^[0-9.]$').hasMatch(text);
  }

  Widget _buildButton(
    String text, {
    bool isOperator = false,
    bool isEquals = false,
  }) {
    final isNumber = _isNumberButton(text);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: isEquals
              ? colorScheme.primary
              : isOperator
                  ? colorScheme.secondaryContainer
                  : isNumber
                      ? (isDark
                          ? colorScheme.surfaceContainerHigh
                          : colorScheme.surface)
                      : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          elevation: isNumber ? 2 : 0,
          shadowColor: isNumber
              ? (isDark ? Colors.black54 : Colors.black.withOpacity(0.08))
              : Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _onButtonPressed(text),
            splashColor: isNumber
                ? colorScheme.primary.withOpacity(0.12)
                : null,
            highlightColor: isNumber
                ? colorScheme.primary.withOpacity(0.06)
                : null,
            child: SizedBox.expand(
              child: Container(
                alignment: Alignment.center,
                decoration: isNumber
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? colorScheme.outline.withOpacity(0.2)
                              : colorScheme.outline.withOpacity(0.08),
                          width: 1,
                        ),
                      )
                    : null,
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: isNumber ? 26 : 28,
                    fontWeight: isNumber ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: isNumber ? 0.5 : 0,
                    color: isEquals
                        ? colorScheme.onPrimary
                        : isOperator
                            ? colorScheme.onSecondaryContainer
                            : colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
