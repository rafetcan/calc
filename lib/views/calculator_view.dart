import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../viewmodels/calculator_viewmodel.dart';
import '../providers/theme_provider.dart';
import '../views/feedback_dialog.dart';

class CalculatorView extends StatelessWidget {
  const CalculatorView({super.key});

  void _showHistory(BuildContext context) {
    final viewModel = context.read<CalculatorViewModel>();
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Geçmiş',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        viewModel.clearHistory();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: Consumer<CalculatorViewModel>(
                    builder:
                        (context, viewModel, _) => ListView.builder(
                          itemCount: viewModel.history.length,
                          itemBuilder:
                              (context, index) => ListTile(
                                title: Text(
                                  viewModel.history[viewModel.history.length -
                                      1 -
                                      index],
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                        ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const FeedbackDialog());
  }

  Widget _buildButton(
    BuildContext context,
    String text, {
    Color? textColor,
    Color? backgroundColor,
  }) {
    final viewModel = context.read<CalculatorViewModel>();
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                backgroundColor ??
                (Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]
                    : Colors.grey[200]),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(20),
          ),
          onPressed: () => viewModel.onButtonPressed(text),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 24,
              color:
                  textColor ??
                  (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.history,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              ),
                              onPressed: () => _showHistory(context),
                            ),
                            Consumer<ThemeProvider>(
                              builder:
                                  (context, themeProvider, _) => IconButton(
                                    icon: Icon(
                                      themeProvider.isDarkMode
                                          ? Icons.light_mode
                                          : Icons.dark_mode,
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                    onPressed:
                                        () => themeProvider.toggleTheme(),
                                  ),
                            ),
                            Consumer<CalculatorViewModel>(
                              builder:
                                  (context, viewModel, _) => IconButton(
                                    icon: Icon(
                                      viewModel.isScreenLocked
                                          ? Icons.screen_lock_portrait
                                          : Icons.screen_lock_portrait_outlined,
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                    onPressed:
                                        () => viewModel.toggleScreenLock(),
                                  ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.feedback,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              ),
                              onPressed: () => _showFeedbackDialog(context),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: constraints.maxHeight * 0.3,
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.bottomRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Consumer<CalculatorViewModel>(
                              builder:
                                  (context, viewModel, _) => Text(
                                    viewModel.expression,
                                    style: const TextStyle(fontSize: 48),
                                  ),
                            ),
                            Consumer<CalculatorViewModel>(
                              builder:
                                  (context, viewModel, _) => Text(
                                    viewModel.result,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildButton(
                                  context,
                                  'C',
                                  textColor: Colors.red,
                                ),
                                _buildButton(context, '( )'),
                                _buildButton(context, '%'),
                                _buildButton(
                                  context,
                                  '÷',
                                  textColor: Colors.green,
                                ),
                                _buildButton(
                                  context,
                                  '⌫',
                                  textColor: Colors.red,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _buildButton(context, '7'),
                                _buildButton(context, '8'),
                                _buildButton(context, '9'),
                                _buildButton(
                                  context,
                                  '×',
                                  textColor: Colors.green,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _buildButton(context, '4'),
                                _buildButton(context, '5'),
                                _buildButton(context, '6'),
                                _buildButton(
                                  context,
                                  '-',
                                  textColor: Colors.green,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _buildButton(context, '1'),
                                _buildButton(context, '2'),
                                _buildButton(context, '3'),
                                _buildButton(
                                  context,
                                  '+',
                                  textColor: Colors.green,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _buildButton(
                                  context,
                                  '+/-',
                                  textColor: Colors.red,
                                ),
                                _buildButton(context, '.'),
                                _buildButton(context, '0'),
                                _buildButton(
                                  context,
                                  '=',
                                  backgroundColor: Colors.green,
                                  textColor: Colors.white,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        child: Consumer<CalculatorViewModel>(
                          builder: (context, viewModel, _) {
                            final bannerAd = viewModel.bannerAd;
                            if (bannerAd == null) return const SizedBox();
                            return Container(
                              alignment: Alignment.center,
                              width: bannerAd.size.width.toDouble(),
                              height: bannerAd.size.height.toDouble(),
                              child: AdWidget(ad: bannerAd),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
