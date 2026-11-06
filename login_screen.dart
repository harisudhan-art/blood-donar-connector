import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'hospital_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  bool isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => isLoading = true);
    try {
      UserCredential userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(), password: passController.text.trim());

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).get();
      
      String role = 'donor';
      if (userDoc.exists) {
        role = (userDoc.data() as Map<String, dynamic>).containsKey('role') ? userDoc['role'] : 'donor';
      }

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => role == 'hospital' ? const HospitalDashboard() : const HomeScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.water_drop, color: Color(0xFFD32F2F), size: 80),
            const Text("Blood Connect", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: passController, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())),
            const SizedBox(height: 30),
            isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _handleLogin, child: const Text("LOGIN")),
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())), child: const Text("Create Account"))
          ],
        ),
      ),
    );
  }
}