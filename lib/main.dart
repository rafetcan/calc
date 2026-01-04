import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/services/theme_service.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/calculator/viewmodels/calculator_viewmodel.dart';
import 'features/calculator/views/calculator_view.dart';
import 'features/calculator/services/history_service.dart';
import 'features/calculator/views/history_view.dart';
import 'features/feedback/services/feedback_service.dart';
import 'features/feedback/views/feedback_dialog.dart';
import 'core/di/locator.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setupLocator();
  await EasyLocalization.ensureInitialized();
  await FirebaseService.initialize();

  final prefs = await SharedPreferences.getInstance();
  final historyService = HistoryService(prefs);

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<HistoryService>.value(
            value: historyService,
          ),
          Provider<FeedbackService>(
            create: (_) => FeedbackService(),
          ),
          ChangeNotifierProvider<ThemeService>(
            create: (_) => ThemeService(prefs),
          ),
          ChangeNotifierProvider<CalculatorViewModel>(
            create: (context) => CalculatorViewModel(
              context.read<HistoryService>(),
            ),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const MethodChannel _channel =
      MethodChannel('com.akidesoft.calc/deeplink');

  @override
  void initState() {
    super.initState();
    _getInitialRoute();
  }

  Future<void> _getInitialRoute() async {
    try {
      final String? route = await _channel.invokeMethod('getInitialRoute');
      if (route != null && mounted) {
        // Wait for the first frame to ensure context is available
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _navigateToRoute(route);
          }
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'app.title'.tr(),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          home: const CalculatorView(),
        );
      },
    );
  }

  void _navigateToRoute(String route) {
    if (!mounted) return;
    final context = this.context;

    switch (route) {
      case 'calc://history':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryView(
              historyService: context.read<HistoryService>(),
            ),
          ),
        );
        break;
      case 'calc://feedback':
        showDialog(
          context: context,
          builder: (context) => FeedbackDialog(
            feedbackService: context.read<FeedbackService>(),
          ),
        );
        break;
      case 'calc://calculator':
      default:
        // Already on calculator view
        break;
    }
  }
}
