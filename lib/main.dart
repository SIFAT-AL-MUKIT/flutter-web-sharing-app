import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF090D16),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const NFileApp());
}

class NFileApp extends StatelessWidget {
  const NFileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          surface: Color(0xFF111827),
          onSurface: Color(0xFFF3F4F6),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF090D16),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1E2A3A),
          contentTextStyle: const TextStyle(color: Color(0xFFF3F4F6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
