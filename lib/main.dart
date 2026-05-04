import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('dark_mode') ?? false;
  
  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  
  const MyApp({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void toggleTheme(bool isDark) async {
    setState(() {
      _isDarkMode = isDark;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naoty',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? _buildDarkTheme() : _buildLightTheme(),
      home: HomeScreen(onThemeChanged: toggleTheme, isDarkMode: _isDarkMode),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Color(0xFF6366F1),
      scaffoldBackgroundColor: Colors.grey[50],
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(0xFF6366F1),
        brightness: Brightness.light,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xFF818CF8),
      scaffoldBackgroundColor: Colors.grey[900],
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(0xFF818CF8),
        brightness: Brightness.dark,
      ),
    );
  }
}