import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'hospital_dashboard.dart';
import 'api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  
  String? _selectedBlood;
  bool _loading = false;
  bool _isHospital = false; 

  Future<void> _register() async {
    if (_emailController.text.isEmpty || _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Details")));
      return;
    }
    setState(() => _loading = true);
    try {
      UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(), password: _passwordController.text.trim());
      
      await FirebaseFirestore.instance.collection('users').doc(user.user!.uid).set({
        'uid': user.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _isHospital ? 'hospital' : 'donor',
        'bloodType': _isHospital ? null : _selectedBlood,
        'address': _isHospital ? _addressController.text.trim() : null,
        'livesSaved': 0,
        'createdAt': DateTime.now(),
      });

      await ApiService.sendUserDataToBackend(_nameController.text, _emailController.text, _isHospital ? "HOSPITAL" : _selectedBlood!);

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => _isHospital ? const HospitalDashboard() : const HomeScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            SwitchListTile(
              title: Text(_isHospital ? "Register as Hospital" : "Register as Donor"),
              value: _isHospital,
              onChanged: (v) => setState(() => _isHospital = v),
            ),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: _isHospital ? "Hospital Name" : "Full Name")),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
            if (_isHospital) TextField(controller: _addressController, decoration: const InputDecoration(labelText: "Hospital Address")),
            if (!_isHospital) DropdownButtonFormField<String>(
              hint: const Text("Select Blood Type"),
              items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedBlood = v),
            ),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password (6+ chars)")),
            const SizedBox(height: 30),
            _loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _register, child: const Text("REGISTER")),
          ],
        ),
      ),
    );
  }
}