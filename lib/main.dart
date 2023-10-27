import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:flutter_email_sender/flutter_email_sender.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Signature to PDF',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SignaturePage(),
    );
  }
}

class SignaturePage extends StatefulWidget {
  @override
  _SignaturePageState createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  Future<void> _sendPdfEmail(File pdffile) async {
    // Send the updated PDF via email
    final Email email = Email(
      body: 'Cher Client Voici votre Facture.',
      subject: 'Facture',
      recipients: ['omartaamallah4@gmail.com'],
      attachmentPaths: [pdffile.path],
    );

    try {
      await FlutterEmailSender.send(email);
      print('Email sent successfully');
    } catch (error) {
      print('Failed to send email: $error');
    }
  }

  bool _isSigned = false;
  Future<File> _saveSignatureToPdf() async {
    final pdf = pw.Document();
    final signatureImage = await _controller.toPngBytes();
    // Fetch the PDF from the internet
    

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            width: PdfPageFormat.a4.width,
            height: PdfPageFormat.a4.height,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo and Date
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Date: ',
                        style: pw.TextStyle(fontSize: 16),
                      ),
                      pw.Text(
                        '2023-10-27',
                        style: pw.TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  // Invoice number
                  pw.Text(
                    'Numéro de facture',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 20),
                  // Company information
                  pw.Text(
                    'Nom de entreprise\nAdresse\nCode Postal et Ville\nNuméro de téléphone\nEmail',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 20),
                  // Customer information
                  pw.Text(
                    'Objet: intitulé\n\nNom du client\nAdresse\nCode Postal et Ville\nNuméro de téléphone\nEmail',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 20),
                  // Table
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(children: [
                        pw.Text('Description'),
                        pw.Text('Unité'),
                        pw.Text('Quantité'),
                        pw.Text('Prix Unitaire HT'),
                        pw.Text('TVA'),
                      ]),
                      pw.TableRow(children: [
                        pw.Text('Licence KPulse pour 1 utilisateur'),
                        pw.Text('1'),
                        pw.Text("39.90 euro"),
                        pw.Text('20 %'),
                      ]),
                    ],
                  ),
                  pw.SizedBox(height: 100),
                  pw.Align(
                      alignment: pw.Alignment.bottomRight,
                      child: pw.Column(
                        children: [
                          pw.Text("Signature:"),
                          pw.SizedBox(
                            height: 100,
                            width: 100,
                            child: pw.Image(pw.MemoryImage(signatureImage!)),
                          )
                        ],
                      ))
                ],
              ),
            ),
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final outputFile = File('${output.path}/signature.pdf');
    print("==== ${outputFile.path}");
    await outputFile.writeAsBytes(await pdf.save());

    return outputFile;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Please Sign here'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Signature(
              controller: _controller,
              height: 300,
              backgroundColor: Colors.white,
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _controller.clear();
                    });
                  },
                  child: const Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _saveSignatureToPdf().then((value) {
                      _sendPdfEmail(value);
                    });
                  },
                  child: const Text('Send the bill'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
