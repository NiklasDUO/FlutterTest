import 'package:bottom_bar_matu/bottom_bar_matu.dart';
import 'package:flutter/material.dart';
import 'package:mainflutter/views/SettingsPage.dart';

import 'views/mainmenu.dart';
import 'views/AboutPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'QR 2 TAB'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PageController controller = PageController();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomBarBubble(
        items: [
          BottomBarItem(
            iconData: Icons.qr_code_scanner,
            // label: 'Home',
          ),
          BottomBarItem(
            iconData: Icons.settings,
            // label: 'Chat',
          ),
          BottomBarItem(
            iconData: Icons.info,
            // label: 'Notification',
          ),
        ],
        onSelect: (index) {
          controller.animateToPage(
            index,
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
          );
        },
      ),
      body: PageView(
        controller: controller,
        children: const <Widget>[
          QRCodeScannerPage(),
          SettingsPage(),
          AboutPage(),
        ],
      ),
    );
  }
}