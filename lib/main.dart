import 'package:final_fiverr_1_project/screens/HomeScreen.dart';
import 'package:final_fiverr_1_project/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {

  
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: "https://bwlcbcyyewuwueysjtgg.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ3bGNiY3l5ZXd1d3VleXNqdGdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIwMzU3NTAsImV4cCI6MjA1NzYxMTc1MH0.BRIfzt_GM_KeyhmqaEQzpWCPozbuBqIoMylJGo_ZgXo",
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final supabase = Supabase.instance.client;
    final prefs = await SharedPreferences.getInstance();
    final sessionExpiration = prefs.getInt('session_expiration') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Check if there's a valid session and it hasn't expired
    if (supabase.auth.currentSession != null && currentTime < sessionExpiration) {
      return const HomeScreen();
    } else {
      // Clear session if expired
      if (currentTime >= sessionExpiration) {
        await supabase.auth.signOut();
        await prefs.remove('session_expiration');
      }
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Guitar Practice App',
      theme: ThemeData(
        textTheme: GoogleFonts.robotoTextTheme(),
        //fontFamily: 'CustomFont',
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data ?? const LoginScreen();
        },
      ),
    );
  }
}