import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../utilities/DatabaseHelper.dart';
import '../classes/record.dart';
import 'package:intl/intl.dart';

class QRCodeScannerPage extends StatefulWidget {
  const QRCodeScannerPage({Key? key}) : super(key: key);

  @override
  _QRCodeScannerPageState createState() => _QRCodeScannerPageState();
}

class _QRCodeScannerPageState extends State<QRCodeScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  final DatabaseHelper databaseHelper = DatabaseHelper.instance;
  List<Record> scannedCards = [];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    _loadScannedCards();
  }

  Future<void> _loadScannedCards() async {
    final List<Record> records = await databaseHelper.getRecords();
    setState(() {
      scannedCards = records;
    });
  }



  final RegExp macAddressRegex = RegExp(
    r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadScannedCards,
        child: ListView.builder(
          itemCount: scannedCards.length,
          itemBuilder: (context, index) {
            final record = scannedCards[index];
            return Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.horizontal,
              background: Container(
                color: Colors.red,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                    SizedBox(width: 16.0),
                  ],
                ),
              ),
              onDismissed: (direction) {
                _deleteRecord(record);
              },
              child: GestureDetector(
                onTap: () {
                  _showEditDialog(context, record);
                },
                child: Card(
                  child: ListTile(
                    title: Text(DateFormat.d().add_MMM().add_y().add_H().add_m().format(record.timestamp)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.comment),
                        Text(record.macAddress ?? 'N/A')
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              _showClearConfirmationDialog(context);
            },
            child: Icon(Icons.delete_forever),
          ),
          SizedBox(height: 16.0),
          FloatingActionButton(
            onPressed: () {
              _openQRCodeScanner(context);
            },
            child: Icon(Icons.qr_code),
          ),
          SizedBox(height: 16.0),
          FloatingActionButton(
            onPressed: _exportToExcel,
            child: Icon(Icons.arrow_forward),
          ),
        ],
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
          child: Column(
            children: [
              Expanded(
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (scanData.code == null) {
        return;
      }
      String qrCode = scanData.code ?? '';

      Record newRecord = Record(
        qrData: qrCode.replaceAll('\n', ' '),
        comment: ' ',
        timestamp: DateTime.now(),
        macAddress: macAddressRegex.firstMatch(qrCode)?.group(0),
      );

      await databaseHelper.insertRecord(newRecord);

      setState(() {
        scannedCards.add(newRecord);
      });

      controller.dispose();
      Navigator.pop(context);
    });
  }

  void _showEditDialog(BuildContext context, Record record) async {
    final TextEditingController qrDataController = TextEditingController(text: record.qrData);
    final TextEditingController commentController = TextEditingController(text: record.comment);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qrDataController,
                decoration: InputDecoration(labelText: 'QR Data'),
              ),
              TextField(
                controller: commentController,
                decoration: InputDecoration(labelText: 'Comment'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Update the record in the database
                record.qrData = qrDataController.text;
                record.comment = commentController.text;
                await databaseHelper.updateRecord(record);

                setState(() { });
                Navigator.pop(context);
              },
              child: Text('Submit'),
            ),
            TextButton(
              onPressed: () async {
                _deleteRecord(record);
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }




  void _deleteRecord(Record record) async {
    await databaseHelper.deleteRecord(record.id as int);

    setState(() {
      scannedCards.remove(record);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Record deleted')),
    );

    _loadScannedCards();
  }


  void _showClearConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear Database'),
          content: Text('Are you sure you want to clear the database? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await databaseHelper.clearDatabase();
                _loadScannedCards();
                Navigator.pop(context);
              },
              child: Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _exportToExcel() async {
    // Create Excel workbook and sheet
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Add headers
    sheet.appendRow(['QR Data', 'Comment', 'Timestamp']);

    // Add data rows
    for (final record in scannedCards) {
      sheet.appendRow([record.qrData, record.comment, record.timestamp.toString()]);
    }

    // Get the Downloads directory
    final downloadsDirectory = await getDownloadsDirectory();
    if (downloadsDirectory != null) {
      // Save the Excel file
      final filePath = '${downloadsDirectory.path}/scanned_cards.xlsx';
      print(filePath);
      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsBytes(await excel.encode() as List<int>);

      // Show a snackbar with the file path
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to Excel: $filePath')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to access the Downloads directory')),
      );
    }
  }
}
