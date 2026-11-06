import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifyDonorScreen extends StatefulWidget {
  const VerifyDonorScreen({super.key});
  @override
  State<VerifyDonorScreen> createState() => _VerifyDonorScreenState();
}

class _VerifyDonorScreenState extends State<VerifyDonorScreen> {
  final _codeController = TextEditingController();

  Future<void> _verifyAndComplete(String status) async {
    String code = _codeController.text.trim();

    // 1. Find the donation with this Temp ID
    QuerySnapshot snap = await FirebaseFirestore.instance
        .collection('donations')
        .where('tempId', isEqualTo: code)
        .where('status', isEqualTo: 'Pending Verification')
        .get();

    if (snap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid or expired code!")));
      return;
    }

    var donationDoc = snap.docs.first;
    String donorUid = donationDoc['donorUid'];
    String requestDocId = donationDoc['requestDocId'];

    if (status == 'Donated') {
      // 2. Update Request Progress
      await FirebaseFirestore.instance.collection('requests').doc(requestDocId).update({
        'unitsFulfilled': FieldValue.increment(1),
      });

      // 3. Reward Donor and Start Cooldown
      await FirebaseFirestore.instance.collection('users').doc(donorUid).update({
        'livesSaved': FieldValue.increment(1),
        'lastDonationDate': DateTime.now(),
      });
    }

    // 4. Close the donation record
    await donationDoc.reference.update({'status': status});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Donor marked as $status")));
      _codeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Donor Arrival"), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Text("Enter the 6-digit code provided by the donor:", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController, 
              decoration: const InputDecoration(hintText: "Enter Code", border: OutlineInputBorder()), 
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 10),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _verifyAndComplete('Donated'), 
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green), 
                  child: const Text("CONFIRM DONATION", style: TextStyle(color: Colors.white))
                ),
                ElevatedButton(
                  onPressed: () => _verifyAndComplete('No Show'), 
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red), 
                  child: const Text("NO SHOW", style: TextStyle(color: Colors.white))
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}