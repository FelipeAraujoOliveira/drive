import 'package:flutter/material.dart';
import 'google_drive_service.dart';
import 'Documentscreen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    final GoogleDriveService driveService = GoogleDriveService();
    await driveService.signIn();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => DocumentsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
