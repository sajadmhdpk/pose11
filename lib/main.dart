import 'package:flutter/material.dart';
import 'services/billing_manager.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BillingManager().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PLATANO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal.shade800,
          secondary: Colors.teal.shade600,
        ),
        scaffoldBackgroundColor: Colors.white,
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
          bodySmall: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
          titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
          titleMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
          titleSmall: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
          labelLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
