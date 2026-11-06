import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Prefixing excel to avoid 'Border' naming conflicts
import 'package:excel/excel.dart' as excel_lib; 
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class StockDashboard extends StatefulWidget {
  const StockDashboard({super.key});

  @override
  State<StockDashboard> createState() => _StockDashboardState();
}

class _StockDashboardState extends State<StockDashboard> {
  final String hospitalUid = FirebaseAuth.instance.currentUser!.uid;
  final List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final int pricePerUnit = 1100;

  // --- LOGIC: LOG TRANSACTION ---
  Future<void> _logTransaction({
    required String type,
    required String bloodGroup,
    required int units,
    required int revenue,
    String? note,
  }) async {
    await FirebaseFirestore.instance.collection('transactions').add({
      'hospitalUid': hospitalUid,
      'type': type,
      'bloodGroup': bloodGroup,
      'units': units,
      'revenue': revenue,
      'note': note ?? "",
      'timestamp': DateTime.now(),
    });
  }

  // --- LOGIC: UPDATE STOCK ---
  Future<void> _updateStock(String group, int change) async {
    DocumentReference stockRef = FirebaseFirestore.instance.collection('blood_inventory').doc(hospitalUid);
    int revenue = (change < 0) ? (change.abs() * pricePerUnit) : 0;

    await stockRef.set({group: FieldValue.increment(change)}, SetOptions(merge: true));
    
    await _logTransaction(
      type: change > 0 ? 'ADD' : 'GIVE',
      bloodGroup: group,
      units: change.abs(),
      revenue: revenue,
    );
  }

  // --- LOGIC: EXCHANGE BLOOD ---
  Future<void> _exchangeBlood(String giveGroup, String takeGroup, int units) async {
    DocumentReference stockRef = FirebaseFirestore.instance.collection('blood_inventory').doc(hospitalUid);
    
    await stockRef.update({
      giveGroup: FieldValue.increment(-units),
      takeGroup: FieldValue.increment(units),
    });

    await _logTransaction(
      type: 'EXCHANGE',
      bloodGroup: "$giveGroup to $takeGroup",
      units: units,
      revenue: 0,
      note: "Swapped $giveGroup for $takeGroup",
    );
  }

  // --- LOGIC: GENERATE EXCEL REPORT (FIXED FOR VERSION 4.0+) ---
  Future<void> _generateExcelReport() async {
    var excel = excel_lib.Excel.createExcel();
    excel_lib.Sheet sheetObject = excel['Blood Bank Report'];
    excel.delete('Sheet1');

    // FIX: Using TextCellValue for Headers
    sheetObject.appendRow([
      excel_lib.TextCellValue('Date'),
      excel_lib.TextCellValue('Action Type'),
      excel_lib.TextCellValue('Blood Group'),
      excel_lib.TextCellValue('Units'),
      excel_lib.TextCellValue('Revenue (INR)'),
      excel_lib.TextCellValue('Notes'),
    ]);

    QuerySnapshot snap = await FirebaseFirestore.instance
        .collection('transactions')
        .where('hospitalUid', isEqualTo: hospitalUid)
        .orderBy('timestamp', descending: true)
        .get();

    int totalRevenue = 0;

    for (var doc in snap.docs) {
      var d = doc.data() as Map<String, dynamic>;
      DateTime date = (d['timestamp'] as Timestamp).toDate();
      int rev = (d['revenue'] as num).toInt();
      totalRevenue += rev;

      // FIX: Using specific CellValue types for each data point
      sheetObject.appendRow([
        excel_lib.TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(date)),
        excel_lib.TextCellValue(d['type'].toString()),
        excel_lib.TextCellValue(d['bloodGroup'].toString()),
        excel_lib.IntCellValue((d['units'] as num).toInt()),
        excel_lib.IntCellValue(rev),
        excel_lib.TextCellValue(d['note'].toString()),
      ]);
    }

    // Add Total Row
    sheetObject.appendRow([
      excel_lib.TextCellValue(''),
      excel_lib.TextCellValue(''),
      excel_lib.TextCellValue(''),
      excel_lib.TextCellValue('TOTAL REVENUE:'),
      excel_lib.IntCellValue(totalRevenue),
      excel_lib.TextCellValue(''),
    ]);

    // Save and Share File
    final directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/Blood_Report.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    await Share.shareXFiles([XFile(filePath)], text: 'Blood Bank Revenue Report');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory & Revenue"),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _generateExcelReport,
            icon: const Icon(Icons.file_download),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('blood_inventory').doc(hospitalUid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: ElevatedButton(onPressed: () => _updateStock('O+', 0), child: const Text("Initialize Stock")));
          }

          var stock = snapshot.data!.data() as Map<String, dynamic>;
          return Column(
            children: [
              _buildRevenueBanner(),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.8, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: bloodGroups.length,
                  itemBuilder: (context, index) {
                    String g = bloodGroups[index];
                    return _card(g, (stock[g] ?? 0).toInt());
                  },
                ),
              ),
              _buildControls(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRevenueBanner() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transactions').where('hospitalUid', isEqualTo: hospitalUid).snapshots(),
      builder: (context, snap) {
        int total = 0;
        if (snap.hasData) {
          for (var doc in snap.data!.docs) {
            total += (doc['revenue'] as num).toInt();
          }
        }
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(15),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.green[700], borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              const Text("TOTAL REVENUE GENERATED", style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text("₹$total", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  Widget _card(String g, int c) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade100)),
    child: Center(child: Text("$g: $c Units", style: const TextStyle(fontWeight: FontWeight.bold))),
  );

  Widget _buildControls() => Container(
    padding: const EdgeInsets.all(20),
    color: Colors.grey[100],
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(onPressed: () => _showPopup(true), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("ADD")),
        ElevatedButton(onPressed: () => _showPopup(false), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text("GIVE")),
        ElevatedButton(onPressed: _showExchange, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), child: const Text("EXCHANGE")),
      ],
    ),
  );

  void _showPopup(bool add) {
    String? selected; final qty = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text(add ? "Add Stock" : "Give Blood (₹1100/unit)"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(items: bloodGroups.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => selected = v),
        TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Quantity")),
      ]),
      actions: [ElevatedButton(onPressed: () { _updateStock(selected!, int.parse(qty.text) * (add ? 1 : -1)); Navigator.pop(c); }, child: const Text("CONFIRM"))],
    ));
  }

  void _showExchange() {
    String? g; String? t; final qty = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Exchange (Free)"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(items: bloodGroups.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => g = v, hint: const Text("Give")),
        DropdownButtonFormField<String>(items: bloodGroups.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => t = v, hint: const Text("Take")),
        TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Quantity")),
      ]),
      actions: [ElevatedButton(onPressed: () { _exchangeBlood(g!, t!, int.parse(qty.text)); Navigator.pop(c); }, child: const Text("EXCHANGE"))],
    ));
  }
}