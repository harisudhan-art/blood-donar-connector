import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart'; // Import the login screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // After 3 seconds, jump to the Login Screen
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop, color: Color(0xFFD32F2F), size: 100),
            SizedBox(height: 20),
            Text(
              "BLOOD CONNECT",
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFFD32F2F),
                letterSpacing: 2
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(color: Color(0xFFD32F2F)),
          ],
        ),
      ),
    );
  }
}