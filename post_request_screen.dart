import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostRequestScreen extends StatefulWidget {
  const PostRequestScreen({super.key});

  @override
  State<PostRequestScreen> createState() => _PostRequestScreenState();
}

class _PostRequestScreenState extends State<PostRequestScreen> {
  final hController = TextEditingController();
  final cController = TextEditingController();
  String? bType;
  int _unitsNeeded = 1; // Default to 1 unit
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHospitalData();
  }

  Future<void> _loadHospitalData() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        setState(() {
          hController.text = userDoc['name'] ?? "Unknown Hospital";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Raise Multple Unit Request")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Blood Type", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => bType = v,
                ),
                const SizedBox(height: 20),

                const Text("Units Required (Bags)", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<int>(
                  initialValue: _unitsNeeded,
                  items: [1, 2, 3, 4, 5, 10].map((int value) {
                    return DropdownMenuItem<int>(value: value, child: Text("$value Units"));
                  }).toList(),
                  onChanged: (v) => setState(() => _unitsNeeded = v!),
                ),
                const SizedBox(height: 20),

                const Text("Hospital Name", style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(controller: hController, readOnly: true, decoration: const InputDecoration(border: OutlineInputBorder(), fillColor: Color(0xFFF5F5F5), filled: true)),
                const SizedBox(height: 20),

                const Text("Contact Phone", style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(controller: cController, keyboardType: TextInputType.phone, decoration: const InputDecoration(border: OutlineInputBorder())),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900], foregroundColor: Colors.white),
                    onPressed: () async {
                      if (bType == null || cController.text.isEmpty) return;

                      await FirebaseFirestore.instance.collection('requests').add({
                        'hospitalUid': FirebaseAuth.instance.currentUser!.uid,
                        'bloodType': bType,
                        'hospital': hController.text,
                        'contact': cController.text,
                        'unitsRequired': _unitsNeeded,
                        'unitsFulfilled': 0, // Start at 0
                        'acceptors': [], // List of donor UIDs who accepted
                        'status': 'Pending',
                        'timestamp': DateTime.now()
                      });
                      Navigator.pop(context);
                    }, 
                    child: const Text("POST REQUEST"),
                  ),
                )
              ],
            ),
          ),
    );
  }
}