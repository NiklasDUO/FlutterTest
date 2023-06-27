import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../utilities/DatabaseHelper.dart';
import '../classes/record.dart';

class QRCodeScannerPage extends StatefulWidget {
  const QRCodeScannerPage({Key? key}) : super(key: key);

  @override
  _QRCodeScannerPageState createState() => _QRCodeScannerPageState();
}

class _QRCodeScannerPageState extends State<QRCodeScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  final DatabaseHelper databaseHelper = DatabaseHelper.instance; // Create an instance of DatabaseHelper
  List<Record> scannedCards = [];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: scannedCards.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(scannedCards[index].qrData),
                    subtitle: Text(scannedCards[index].comment),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              // Dispose the QR code scanner
              controller?.dispose();

              // Close the bottom sheet
              Navigator.pop(context);
            },
            child: Text('Close'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openQRCodeScanner(context);
        },
        child: Icon(Icons.qr_code),
      ),
    );
  }

  void _openQRCodeScanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 400,
          padding: EdgeInsets.all(16.0),
          child: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
          ),
        );
      },
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
      controller.scannedDataStream.listen((scanData) async {
        // Handle the QR code scan result
        String qrCode = scanData.code ?? '';

        // Add the scanned data to the SQLite database
        await databaseHelper.insertRecord(
          Record(
            qrData: qrCode,
            comment: 'Comment', // Replace with the desired comment
            timestamp: DateTime.now(),
          ),
        );

        // Update the scanned cards list
        setState(() {
          scannedCards.add(
            Record(
              qrData: qrCode,
              comment: 'Comment', // Replace with the desired comment
              timestamp: DateTime.now(),
            ),
          );
        });
      });
    });
  }
}
