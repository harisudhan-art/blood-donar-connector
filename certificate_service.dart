import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class CertificateService {
  static Future<void> generateCertificate({
    required String donorName,
    required String bloodType,
    required DateTime date,
  }) async {
    final pdf = pw.Document();
    final formattedDate = DateFormat('MMMM dd, yyyy').format(date);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(30),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.red900, width: 5),
            ),
            child: pw.Container(
              border: pw.Border.all(color: PdfColors.red900, width: 1),
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text("CERTIFICATE",
                      style: pw.TextStyle(
                          fontSize: 40,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red900)),
                  pw.Text("OF APPRECIATION",
                      style: const pw.TextStyle(fontSize: 20, letterSpacing: 2)),
                  pw.SizedBox(height: 30),
                  pw.Text("PROUDLY PRESENTED TO",
                      style: const pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 10),
                  pw.Text(donorName.toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 35,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black)),
                  pw.Container(
                    width: 400,
                    child: pw.Divider(color: PdfColors.grey, thickness: 1),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    "For the heroic act of donating Blood Type $bloodType. Your contribution has helped save lives and serves as an inspiration to our community.",
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(children: [
                        pw.Text(formattedDate,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Container(
                            width: 150, child: pw.Divider(thickness: 1)),
                        pw.Text("Date of Donation"),
                      ]),
                      pw.Column(children: [
                        pw.Text("BLOOD CONNECT",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.red900)),
                        pw.Container(
                            width: 150, child: pw.Divider(thickness: 1)),
                        pw.Text("Certified Portal"),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // Show Print/Download Preview
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }
}