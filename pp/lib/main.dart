import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmapulse/screens/login_page.dart';

void main() {
  runApp(const PharmaPulseApp());
}

class PharmaPulseApp extends StatelessWidget {
  const PharmaPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharma Pulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Set the default font theme for the entire app
        textTheme: GoogleFonts.montserratTextTheme(Theme.of(context).textTheme),

        // Beige Theme Configuration
        scaffoldBackgroundColor: const Color(0xFFF5F5DC), // Beige background
        // Primary color scheme using brown instead of green
        primarySwatch: _createMaterialColor(const Color(0xFF8D6E63)),
        primaryColor: const Color(0xFF8D6E63), // Primary brown
        // App bar theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF424242),
          elevation: 1,
          shadowColor: Colors.black12,
          titleTextStyle: GoogleFonts.montserrat(
            color: const Color(0xFF424242),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),

        // Bottom navigation bar theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(
            0xFFD4806A,
          ), // Terracotta accent instead of green
          unselectedItemColor: Color(0xFF757575),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),

        // Color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8D6E63),
          primary: const Color(0xFF8D6E63), // Primary brown
          secondary: const Color(0xFFD4806A), // Terracotta accent
          background: const Color(0xFFF5F5DC), // Beige background
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: const Color(0xFF424242),
          onSurface: const Color(0xFF424242),
        ),

        // Drawer theme
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF8D6E63), // Primary brown
        ),

        // Text theme with beige colors
        // (Removed duplicate textTheme parameter to fix compile error)
      ),
      home: const LoginPage(),
    );
  }

  // Helper method to create a MaterialColor from a single color
  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}
