// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:async';
import 'dart:io';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../views/MobileScannerOverlay.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utilities/DatabaseHelper.dart';
import '../classes/record.dart';
import 'package:share/share.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utilities/notifiedsettings.dart';
class QRCodeScannerPage extends StatefulWidget {
  const QRCodeScannerPage({Key? key}) : super(key: key);

  @override
  _QRCodeScannerPageState createState() => _QRCodeScannerPageState();
}

class _QRCodeScannerPageState extends State<QRCodeScannerPage> {


  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  //MIGRATION
  MobileScannerController cameraController = MobileScannerController();
  late SharedPreferences prefs;
  late NotifiedSettings notifiedSettings;

  //AD
  late BannerAd _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerAdLoaded = false;

  final AudioPlayer audioPlayer = AudioPlayer();
  final DatabaseHelper databaseHelper = DatabaseHelper.instance;
  List<Record> scannedCards = [];
  List<Record> backupDatabase = [];


  //TODO: Change ID after approval
  final adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';
  final videoUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/1033173712';


  @override
  void dispose() {
    cameraController.dispose();
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadScannedCards();
    loadAd();
  }

  Future<void> _loadScannedCards() async {
    final List<Record> records = await databaseHelper.getRecords();
    prefs = await SharedPreferences.getInstance();
    notifiedSettings = NotifiedSettings();
    notifiedSettings.initialize();
    setState(() {
      scannedCards = records.reversed.toList();
    });
  }

  final RegExp macAddressRegex = RegExp(
    r'([0-9A-Fa-f]{2}(?::|-)?){5}[0-9A-Fa-f]{2}',
  );

  @override
  Widget build(BuildContext context) {
    DateFormat format = DateFormat("dd.MM.yyyy HH:mm");
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('QR 2 TAB'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_outlined),
            color: Colors.white,
            onPressed: () {
              _openQRCodeScanner(context);
              cameraController = MobileScannerController();
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            color: Colors.white,
            onPressed: () {
              _showNewDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            color: Colors.white,
            onPressed: () {
              _exportToExcel();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            color: Colors.white,
            onPressed: () {
              _showClearConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: scannedCards.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    child: ListTile(
                      leading: GestureDetector(
                        child: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          radius: 24.0,
                          child: Text(
                            scannedCards[index].quantity.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                        onTap: () {
                          _openNumberModal(context, scannedCards[index]);
                        },
                      ),
                      title: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          format.format(scannedCards[index].timestamp),
                          style: const TextStyle(fontSize: 12.0),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              scannedCards[index].macAddress ?? 'N/A',
                              style: const TextStyle(
                                  fontSize: 12.0, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              scannedCards[index].comment,
                              style: const TextStyle(fontSize: 14.0),
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
            if (_bannerAd != null && _isBannerAdLoaded)
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: SizedBox(
                    width: _bannerAd.size.width.toDouble(),
                    height: _bannerAd.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void loadAd() {
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          // Dispose the ad here to free resources.
          ad.dispose();
        },
      ),
    )..load();
    InterstitialAd.load(
        adUnitId: videoUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            debugPrint('$ad loaded.');
            // Keep a reference to the ad so you can show it later.
            _interstitialAd = ad;
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ));
  }

  void _openQRCodeScanner(BuildContext context) {
    bool zoomed = prefs.getBool('zoom') as bool;
    String multiText = "Multi";
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 800,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ValueListenableBuilder(valueListenable: notifiedSettings.multiscan,
                    builder: (context,value,child) {
                      return ElevatedButton(
                        style: notifiedSettings.multiscan.value ?? true
                            ? ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              Theme
                                  .of(context)
                                  .primaryColor),
                          foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                        )
                            : ButtonStyle(
                            backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                            foregroundColor:
                            MaterialStateProperty.all<Color>(
                                Theme
                                    .of(context)
                                    .primaryColor)),
                        onPressed: () {
                          notifiedSettings.multiscan.value = !notifiedSettings.multiscan.value;
                          if (!notifiedSettings.multiscan.value) { multiText = "Single"; }
                          else { multiText = "Multi"; }
                        },
                        child: Text(multiText),
                      );
                    }
                  ),
                  const SizedBox(width: 10),
                  ValueListenableBuilder(valueListenable: cameraController.torchState,
                    builder:  (context,value,child) {
                    bool boolean = false;
                    if (cameraController.torchState.value == TorchState.on) {
                      boolean = true;
                    }
                    print(cameraController.torchState.value);
                     return ElevatedButton(
                        style: boolean
                            ? ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              Theme
                                  .of(context)
                                  .primaryColor),
                          foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                        )
                            : ButtonStyle(
                            backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                            foregroundColor:
                            MaterialStateProperty.all<Color>(
                                Theme
                                    .of(context)
                                    .primaryColor)),
                        onPressed: () {
                          cameraController.toggleTorch();
                        },
                        child: const Icon(Icons.flashlight_on),
                      );
                    }
                  ),
                  const SizedBox(width: 10),
                  ValueListenableBuilder(valueListenable: notifiedSettings.soundEnabled,
                      builder:  (context,value,child) {
                        return ElevatedButton(
                          style: notifiedSettings.soundEnabled.value
                              ? ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Theme
                                    .of(context)
                                    .primaryColor),
                            foregroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                          )
                              : ButtonStyle(
                              backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.white),
                              foregroundColor:
                              MaterialStateProperty.all<Color>(
                                  Theme
                                      .of(context)
                                      .primaryColor)),
                          onPressed: () {
                            notifiedSettings.soundEnabled.value = !notifiedSettings.soundEnabled.value;
                          },
                          child: const Icon(Icons.music_note),
                        );
                      }
                  ),
                  const SizedBox(width: 10),
                  ValueListenableBuilder(valueListenable: notifiedSettings.vibrateEnabled,
                      builder:  (context,value,child) {
                        return SizedBox(
                          child: ElevatedButton(
                            style: notifiedSettings.vibrateEnabled.value
                                ? ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Theme
                                      .of(context)
                                      .primaryColor),
                              foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.white),
                            )
                                : ButtonStyle(
                                backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                                foregroundColor:
                                MaterialStateProperty.all<Color>(
                                    Theme
                                        .of(context)
                                        .primaryColor)),
                            onPressed: () {
                              notifiedSettings.vibrateEnabled.value = !notifiedSettings.vibrateEnabled.value;
                            },
                            child: const Icon(Icons.vibration),
                          ),
                        );
                      }
                  ),
                  const SizedBox(width: 5),
                ],
              ),
              const SizedBox(height: 10.0),
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () {
                    zoomed = !zoomed;
                    prefs.setBool('zoom', zoomed);
                    if (zoomed) {
                      cameraController.setZoomScale(0.5);
                    }
                    else {
                      cameraController.setZoomScale(0);
                    }
                  },
                  child: MobileScanner(
                    controller: cameraController,
                    // create overlay with container widget with four corner cutout
                    overlay: const QRScannerOverlay(
                      overlayColour: Colors.transparent,
                    ),
                    onDetect: (detect) async{
                      List<Barcode> barcodes = detect.barcodes;
                      String rawData = barcodes[0].rawValue ?? "None";
                      String mac = macAddressRegex.firstMatch(rawData)?.group(0) ?? 'N/A';
                      if (!mac.contains(':') && mac != 'N/A') {
                        mac = mac.replaceAllMapped(RegExp(r".{2}"), (Match m) => "${m.group(0)}:");
                        mac = mac.substring(0, mac.length - 1);
                      }
                      Record record = Record(
                        qrData: rawData,
                        comment: '',
                        macAddress: mac,
                        timestamp: DateTime.now(),
                        quantity: (await databaseHelper.getPreviousQuantity()) +1,
                      );
                      // check if record already exists
                        databaseHelper.exist(record).then((value) async {
                        if (!value || !notifiedSettings.dupesCheck.value) {
                          await databaseHelper.insertRecord(record);
                          if (prefs.getBool(
                              'SoundEnabled') as bool) {
                            audioPlayer.play(
                              AssetSource('beep.mp3'));
                          }
                          if (prefs.getBool(
                              'VibroEnabled') as bool) {
                            HapticFeedback
                              .mediumImpact();
                          }
                          if (notifiedSettings.multiscan.value == true) {
                            cameraController.stop();
                            Timer timer = Timer(
                                const Duration(seconds: 1), () {
                              cameraController.start();
                            });
                          }
                          else {
                            _loadScannedCards();
                            Navigator.pop(context);
                            cameraController.dispose();
                          }
                        }
                        else {
                          if (prefs.getBool(
                              'SoundEnabled') as bool) {
                            audioPlayer.play(
                              AssetSource('error.wav'));
                          }
                          cameraController.stop();
                          Timer timer = Timer(const Duration(seconds: 1), () {
                            cameraController.start();
                          });
                        }
                      });
                      _loadScannedCards();
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Record record) async {
    final TextEditingController qrDataController =
    TextEditingController(text: record.qrData);
    final TextEditingController commentController =
    TextEditingController(text: record.comment);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qrDataController,
                minLines: 1,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'QR Data',
                ),
              ),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Comment',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                _deleteRecord(record);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                record.qrData = qrDataController.text;
                record.comment = commentController.text;
                record.macAddress =
                    macAddressRegex.firstMatch(qrDataController.text)?.group(0) ??
                        'N/A';
                await databaseHelper.updateRecord(record);

                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Submit'),
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
      const SnackBar(content: Text('Record deleted')),
    );

    _loadScannedCards();
  }

  void _showClearConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Database'),
          content: const Text('Are you sure you want to clear the database?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _clearAndShowBottomSheet(context);
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAndShowBottomSheet(BuildContext context) async {
    backupDatabase = await databaseHelper.getRecords();
    await databaseHelper.clearDatabase();
    _loadScannedCards();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularCountDownTimer(
                  width: 100,
                  height: 100,
                  duration: 5,
                  isReverse: true,
                  fillColor: Theme.of(context).primaryColor,
                  ringColor: Colors.white,
                  autoStart: true,
                  onComplete: () => {Navigator.pop(context)},
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                    onPressed: backupDB, child: const Text('Cancel'))
              ],
            ),
          ),
        );
      },
    );
  }

  void backupDB() async {
    databaseHelper.writeLines(backupDatabase);
    Navigator.pop(context);
    _loadScannedCards();
  }

  void _exportToExcel() async {
    if (await Permission.manageExternalStorage.isDenied) {
      Permission.manageExternalStorage.request();
      return;
    }
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow(['QR Data', 'Comment', 'Timestamp', 'Identifier', "Mac Address"]);
    for (final record in scannedCards) {
      sheet.appendRow([
        record.qrData,
        record.comment,
        record.timestamp.toString(),
        record.quantity,
        record.macAddress
      ]);
    }
    final downloadsDirectory = await getDownloadPath();
    if (downloadsDirectory != null) {
      final filePath =
          '$downloadsDirectory/scanned_cards ${DateFormat.yMMMEd().format(DateTime.now())}.xlsx';
      final file = File(filePath);
      try {
        await file.create(recursive: true);
        await file.writeAsBytes(excel.encode() as List<int>);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Export Successful'),
              content: const Text('Choose an option:'),
              actions: [
                TextButton(
                  onPressed: () {
                    _interstitialAd?.show();
                    _shareFile(filePath);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Share'),
                ),
                TextButton(
                  onPressed: () {
                    _interstitialAd?.show();
                    _saveFile(filePath);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving the file: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to access the Downloads directory')),
      );

    }
  }

  Future<void> _shareFile(String filePath) async {
    try {
      await Share.shareFiles([filePath], text: 'Sharing Excel file');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing the file: $e')),
      );
    }
  }

  Future<void> _saveFile(String filePath) async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        final destinationPath = '$result/scanned_cards.xlsx';
        final file = File(filePath);
        await file.copy(destinationPath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File saved at: $destinationPath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No directory selected')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving the file: $e')),
      );
    }
  }

  void _openNumberModal(BuildContext context, Record record) {
    int selectedQuantity = record.quantity;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 200.0,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLength: 6,
                    onChanged: (value) {
                      setState(() {
                        selectedQuantity = int.tryParse(value) ?? 0;
                      });
                    },
                    controller: TextEditingController(text: record.quantity.toString()),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  onPressed: () async {
                    setState(() {
                      record.quantity = selectedQuantity;
                    });
                    await databaseHelper.updateRecord(record);
                    Navigator.of(context).pop(selectedQuantity);
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((value) {
      if (value != null) {
        setState(() {
          record.quantity = value;
        });
      }
    });
  }

  Future<String?> getDownloadPath() async {
    Directory? directory;
    if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) directory = await getExternalStorageDirectory();
    }
    return directory?.path;
  }

  void _showNewDialog(BuildContext context) async {
    final TextEditingController qrDataController = TextEditingController();
    final TextEditingController commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qrDataController,
                minLines: 1,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'QR Data',
                ),
              ),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Comment',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Record record = Record(
                  qrData: qrDataController.text,
                  comment: commentController.text,
                  macAddress:
                  macAddressRegex.firstMatch(qrDataController.text)?.group(0) ??
                      'N/A',
                  timestamp: DateTime.now(),
                  quantity: await databaseHelper.getPreviousQuantity() + 1,
                );
                await databaseHelper.insertRecord(record);

                setState(() {});
                _loadScannedCards();
                Navigator.pop(context);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
    _loadScannedCards();
  }
}
