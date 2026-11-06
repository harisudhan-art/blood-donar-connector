import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateCampScreen extends StatefulWidget {
  const CreateCampScreen({super.key});
  @override
  State<CreateCampScreen> createState() => _CreateCampScreenState();
}

class _CreateCampScreenState extends State<CreateCampScreen> {
  final name = TextEditingController();
  final loc = TextEditingController();
  final date = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Donation Camp")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: "Event Name (e.g., Annual Drive)")),
            TextField(controller: loc, decoration: const InputDecoration(labelText: "Location (Full Address)")),
            TextField(controller: date, decoration: const InputDecoration(labelText: "Date & Time")),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('camps').add({
                  'name': name.text, 'location': loc.text, 'date': date.text, 'timestamp': DateTime.now()
                });
                Navigator.pop(context);
              }, 
              child: const Text("PUBLISH CAMP EVENT")
            )
          ],
        ),
      ),
    );
  }
}