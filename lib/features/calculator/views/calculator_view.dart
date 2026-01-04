import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/services/theme_service.dart';
import '../viewmodels/calculator_viewmodel.dart';
import '../services/history_service.dart';
import 'history_view.dart';
import '../../feedback/services/feedback_service.dart';
import '../../feedback/views/feedback_dialog.dart';

class CalculatorView extends StatelessWidget {
  const CalculatorView({super.key});

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
      body: const SafeArea(
        child: Column(
          children: [
            CalculatorDisplay(),
            Spacer(),
            CalculatorKeypad(),
          ],
        ),
      ),
    );
  }
}

class CalculatorDisplay extends StatelessWidget {
  const CalculatorDisplay({super.key});

  Future<void> _handleCopy(BuildContext context, String text) async {
    if (text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.copy'.tr()),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _handlePaste(BuildContext context) async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null && context.mounted) {
      final viewModel = context.read<CalculatorViewModel>();
      await viewModel.pasteText(clipboardData!.text);
    }
  }

  void _showContextMenu(BuildContext context, String displayText, Offset tapPosition) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPosition.dx,
        tapPosition.dy,
        overlay.size.width - tapPosition.dx,
        overlay.size.height - tapPosition.dy,
      ),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              const Icon(Icons.copy),
              const SizedBox(width: 8),
              Text('common.copy'.tr()),
            ],
          ),
          onTap: () {
            // showMenu kapanırken context geçersiz olabilir, bu yüzden Future.microtask kullanıyoruz
            Future.microtask(() {
              if (context.mounted) {
                _handleCopy(context, displayText);
              }
            });
          },
        ),
        PopupMenuItem(
          child: Row(
            children: [
              const Icon(Icons.paste),
              const SizedBox(width: 8),
              Text('common.paste'.tr()),
            ],
          ),
          onTap: () {
            // showMenu kapanırken context geçersiz olabilir, bu yüzden Future.microtask kullanıyoruz
            Future.microtask(() {
              if (context.mounted) {
                _handlePaste(context);
              }
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorViewModel>(
      builder: (context, viewModel, _) {
        final displayText = viewModel.displayText;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onLongPressStart: (details) {
                  _showContextMenu(context, displayText, details.globalPosition);
                },
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    displayText,
                    style: const TextStyle(fontSize: 48),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              if (viewModel.result.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (viewModel.isCalculating)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: GestureDetector(
                        onLongPress: () async {
                          final resultText = viewModel.hasError
                              ? viewModel.lastError
                              : viewModel.result;
                          await _handleCopy(context, resultText);
                        },
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SelectableText(
                            viewModel.hasError
                                ? viewModel.lastError
                                : '= ${viewModel.result}',
                            style: TextStyle(
                              fontSize: 24,
                              color: viewModel.hasError
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class CalculatorKeypad extends StatelessWidget {
  const CalculatorKeypad({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildKeypadRow(['C', '()', '%', '÷']),
          _buildKeypadRow(['7', '8', '9', '×']),
          _buildKeypadRow(['4', '5', '6', '-']),
          _buildKeypadRow(['1', '2', '3', '+']),
          _buildKeypadRow(['⌫', '0', '.', '=']),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> buttons) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: buttons.map((button) => CalculatorButton(button)).toList(),
      ),
    );
  }
}

class CalculatorButton extends StatelessWidget {
  final String text;

  const CalculatorButton(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final isOperator = ['+', '-', '×', '÷', '='].contains(text);
    final isFunction = ['C', '()', '%', '⌫'].contains(text);

    Color backgroundColor = isOperator
        ? Colors.green
        : isFunction
            ? Colors.grey.withAlpha(77)
            : Colors.grey.withAlpha(26);

    Color textColor = isOperator
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleButtonPress(context),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 28,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleButtonPress(BuildContext context) {
    final viewModel = context.read<CalculatorViewModel>();
    switch (text) {
      case 'C':
        viewModel.clear();
        break;
      case '⌫':
        viewModel.backspace();
        break;
      case '=':
        viewModel.calculate();
        break;
      default:
        viewModel.onButtonPressed(text);
        break;
    }
  }
}
