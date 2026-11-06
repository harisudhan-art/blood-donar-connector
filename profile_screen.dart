import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hero Profile")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          var data = snap.data!.data() as Map<String, dynamic>;
          return Column(
            children: [
              const SizedBox(height: 30),
              const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
              const SizedBox(height: 10),
              Text(data['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Divider(),
              ListTile(leading: const Icon(Icons.favorite, color: Colors.red), title: const Text("Lives Saved"), trailing: Text(data['livesSaved'].toString(), style: const TextStyle(fontSize: 20))),
              ListTile(leading: const Icon(Icons.bloodtype, color: Colors.red), title: const Text("Blood Type"), trailing: Text(data['bloodType'] ?? "N/A")),
            ],
          );
        },
      ),
    );
  }
}