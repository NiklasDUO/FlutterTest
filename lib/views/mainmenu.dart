import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../utilities/DatabaseHelper.dart';
import '../classes/record.dart';
import 'package:open_file/open_file.dart';

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
      body: Center(
        child: ListView.builder(
          itemCount: scannedCards.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: ListTile(
                leading: GestureDetector(
                  child:
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      radius: 24.0,
                      child: Text(
                        scannedCards[index].quantity.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                  onTap: (){
                    _openNumberModal(context, scannedCards[index]);
                  },
                ),
                title: Align(
                  alignment: Alignment.centerRight,
                  child:
                    Text(
                      DateFormat.d().add_M().add_y().add_Hm().format(scannedCards[index].timestamp),
                      style: TextStyle(fontSize: 12.0)
                    ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child:Text(
                      scannedCards[index].macAddress ?? 'N/A',
                      style: TextStyle(fontSize: 12.0,fontWeight: FontWeight.bold),
                    ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child:Text(
                        scannedCards[index].comment,
                        style: TextStyle(fontSize: 14.0),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  _showEditDialog(context, scannedCards[index]);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
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
        quantity: await databaseHelper.getPreviousQuantity() + 1,
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

                setState(() {});
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
    await databaseHelper.deleteRecord(record.id);
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
    sheet.appendRow(['QR Data', 'Comment', 'Timestamp','Room Number']);

    // Add data rows
    for (final record in scannedCards) {
      sheet.appendRow([record.qrData, record.comment, record.timestamp.toString(),record.quantity]);
    }

    // Get the downloads directory path
    final downloadsDirectory = await getDownloadPath();
    if (downloadsDirectory != null) {
      // Save the Excel file
      final filePath = '${downloadsDirectory}/scanned_cards.xlsx';
      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsBytes(excel.encode() as List<int>);

      // Show a snackbar with the file path
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to Excel: $filePath')),
      );

      // Build the dialog bar with the file path and open button
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('File saved at:'),
            content: Text(filePath),
            actions: [
              TextButton(
                onPressed: () {
                  // Open the saved Excel file
                  OpenFile.open(filePath);
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Open'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to access the Downloads directory')),
      );
    }
  }
  void _openNumberModal(BuildContext context, Record record) {
    int selectedQuantity = record.quantity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Modify Quantity',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        selectedQuantity = int.tryParse(value) ?? 0;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                    ),
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () async {
                      // Update the quantity in the record
                      setState(() {
                        record.quantity = selectedQuantity;
                      });

                      await databaseHelper.updateRecord(record);
                      Navigator.of(context).pop(selectedQuantity);
                    },
                    child: Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((value) {
      if (value != null) {
        // Update the value in the circle
        setState(() {
          record.quantity = value;
        });
      }
    });
  }
  Future<String?> getDownloadPath() async {
    Directory? directory;
    try {
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = Directory('/storage/emulated/0/Download');
        // Put file in global download folder, if for an unknown reason it didn't exist, we fallback
        // ignore: avoid_slow_async_io
        if (!await directory.exists()) directory = await getExternalStorageDirectory();
      }
    } catch (err, stack) {
      print('Error while getting downloads directory: $err\n$stack');
    }
    return directory?.path;
  }
}
