import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'viewmodels/calculator_viewmodel.dart';
import 'views/calculator_view.dart';
import 'providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences'ı başlat
  final prefs = await SharedPreferences.getInstance();

  // Sadece Firebase başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(CalculatorApp(prefs: prefs));
}

class CalculatorApp extends StatelessWidget {
  final SharedPreferences prefs;

  const CalculatorApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalculatorViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
      ],
      child: Consumer<ThemeProvider>(
        builder:
            (context, themeProvider, _) => MaterialApp(
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'), // English
                Locale('tr'), // Turkish
              ],
              theme: ThemeData.light().copyWith(
                scaffoldBackgroundColor: Colors.white,
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
              darkTheme: ThemeData.dark().copyWith(
                scaffoldBackgroundColor: Colors.black,
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[900],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              themeMode:
                  themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              home: const CalculatorView(),
            ),
      ),
    );
  }
}
