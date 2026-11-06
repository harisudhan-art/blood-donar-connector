import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'post_request_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _generateTempId() => (Random().nextInt(900000) + 100000).toString();

  // --- LOGIC: THE "GIVE" ACTION ---
  Future<void> _processDonation(BuildContext context, String reqId, Map<String, dynamic> reqData) async {
    final String myUid = FirebaseAuth.instance.currentUser!.uid;
    
    try {
      DocumentSnapshot myDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      if (!myDoc.exists) return;
      Map<String, dynamic> myData = myDoc.data() as Map<String, dynamic>;

      String myBlood = myData['bloodType'] ?? "";
      Timestamp? lastDone = myData.containsKey('lastDonationDate') ? myData['lastDonationDate'] : null;

      // 1. Check Blood Type Match
      if (myBlood != reqData['bloodType']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Mismatch! You are $myBlood, they need ${reqData['bloodType']}"))
        );
        return;
      }

      // 2. Check Cooldown (90 days)
      if (lastDone != null) {
        DateTime next = lastDone.toDate().add(const Duration(days: 90));
        if (DateTime.now().isBefore(next)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Safety rule: Next donation after ${DateFormat('yyyy-MM-dd').format(next)}"))
          );
          return;
        }
      }

      // 3. Generate Code and Save to 'donations' collection
      String code = _generateTempId();
      await FirebaseFirestore.instance.collection('donations').add({
        'tempId': code,
        'donorUid': myUid,
        'donorName': myData['name'] ?? "Anonymous",
        'requestDocId': reqId,
        'hospital': reqData['hospital'] ?? "Unknown Hospital",
        'status': 'Pending Verification',
        'timestamp': DateTime.now(),
      });

      // 4. Update the Request to show this donor has accepted
      await FirebaseFirestore.instance.collection('requests').doc(reqId).update({
        'acceptors': FieldValue.arrayUnion([myUid])
      });

      // 5. Show Success Popup
      if (context.mounted) {
        showDialog(
          context: context, 
          builder: (c) => AlertDialog(
            title: const Text("Code Issued!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            content: Text("Your verification code is $code. It is now saved in your 'CODES' tab at the top."),
            actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
          )
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // <--- MUST BE 3
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Blood Connect"),
          backgroundColor: const Color(0xFFD32F2F),
          foregroundColor: Colors.white,
          actions: [
            IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen())), icon: const Icon(Icons.person)),
            IconButton(onPressed: () => FirebaseAuth.instance.signOut().then((_) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginScreen()))), icon: const Icon(Icons.logout)),
          ],
          bottom: const TabBar(
            labelColor: Colors.white, 
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "DONORS"), 
              Tab(text: "REQUESTS"),
              Tab(text: "CODES"), // <--- THE NEW TAB
            ]
          ),
        ),
        body: TabBarView(
          children: [
            _buildDonorList(), 
            _buildRequestList(),
            _buildCodeList(), // <--- THE NEW VIEW
          ]
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const PostRequestScreen())),
          backgroundColor: const Color(0xFFD32F2F),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  // --- TAB 1: DONOR LIST ---
  Widget _buildDonorList() => StreamBuilder(
    stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'donor').snapshots(),
    builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      return ListView(
        padding: const EdgeInsets.all(10),
        children: snap.data!.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return ListTile(
            leading: CircleAvatar(child: Text(data['bloodType'] ?? "?")),
            title: Text(data['name'] ?? "Anonymous"),
            subtitle: Text("Lives Saved: ${data['livesSaved'] ?? 0}"),
          );
        }).toList()
      );
    },
  );

  // --- TAB 2: REQUEST LIST ---
  Widget _buildRequestList() => StreamBuilder(
    stream: FirebaseFirestore.instance.collection('requests').orderBy('timestamp', descending: true).snapshots(),
    builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      return ListView(
        padding: const EdgeInsets.all(10),
        children: snap.data!.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          List acc = data['acceptors'] ?? [];
          bool iAccepted = acc.contains(FirebaseAuth.instance.currentUser?.uid);
          int req = data['unitsRequired'] ?? 1;
          int got = data['unitsFulfilled'] ?? 0;
          bool isFull = got >= req;

          return Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: isFull ? Colors.green : Colors.red, child: Text(data['bloodType'] ?? "?", style: const TextStyle(color: Colors.white))),
              title: Text(data['hospital'] ?? "Hospital"),
              subtitle: Text("Progress: $got / $req collected"),
              trailing: ElevatedButton(
                onPressed: (iAccepted || isFull) ? null : () => _processDonation(context, doc.id, data),
                style: ElevatedButton.styleFrom(backgroundColor: isFull ? Colors.grey : Colors.green),
                child: Text(iAccepted ? "CODE ISSUED" : (isFull ? "FULL" : "GIVE"), style: const TextStyle(color: Colors.white)),
              ),
            ),
          );
        }).toList()
      );
    },
  );

  // --- TAB 3: NOTIFICATIONS (Active Codes) ---
  Widget _buildCodeList() {
    String myUid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .where('donorUid', isEqualTo: myUid)
          .where('status', isEqualTo: 'Pending Verification')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        
        if (snap.data!.docs.isEmpty) {
          return const Center(child: Text("No active codes. Click 'GIVE' on a request to get one."));
        }

        return ListView(
          padding: const EdgeInsets.all(10),
          children: snap.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return Card(
              color: Colors.red[50],
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.qr_code, size: 40, color: Colors.red),
                title: Text("Code for ${data['hospital']}"),
                subtitle: const Text("Present to staff upon arrival"),
                trailing: Text(
                  data['tempId'], 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}