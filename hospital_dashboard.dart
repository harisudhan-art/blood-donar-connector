import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_request_screen.dart';
import 'verify_donor_screen.dart';
import 'manage_requests_screen.dart';
import 'create_camp_screen.dart';
import 'stock_dashboard.dart'; // <--- NEW IMPORT ADDED HERE
import 'login_screen.dart';

class HospitalDashboard extends StatelessWidget {
  const HospitalDashboard({super.key});

  void _signOut(BuildContext context) {
    FirebaseAuth.instance.signOut().then((value) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hospital Admin"),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: () => _signOut(context), icon: const Icon(Icons.logout)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Management Console",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Manage your blood stock, requests, and verification.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),

          // 1. Stock Inventory (Purple) - NEWLY ADDED
          _card(
            context, 
            "Blood Stock Inventory", 
            Icons.inventory_2, 
            Colors.purple, 
            const StockDashboard()
          ),
          const SizedBox(height: 20),

          // 2. Verify Donor (Green)
          _card(
            context, 
            "Verify Arrived Donor", 
            Icons.verified_user, 
            Colors.green, 
            const VerifyDonorScreen()
          ),
          const SizedBox(height: 20),

          // 3. Raise Request (Red)
          _card(
            context, 
            "Raise Urgent Request", 
            Icons.add_alert, 
            Colors.red, 
            const PostRequestScreen()
          ),
          const SizedBox(height: 20),

          // 4. Organize Camp (Orange)
          _card(
            context, 
            "Organize Donation Camp", 
            Icons.campaign, 
            Colors.orange, 
            const CreateCampScreen()
          ),
          const SizedBox(height: 20),

          // 5. Manage Requests (Blue)
          _card(
            context, 
            "Manage My Requests", 
            Icons.list_alt, 
            Colors.blue, 
            const ManageRequestsScreen()
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGET: ACTION CARD ---
  Widget _card(BuildContext context, String title, IconData icon, Color color, Widget destination) {
    return InkWell(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => destination)
      ),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title, 
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: color
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}