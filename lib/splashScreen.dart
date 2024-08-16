import 'package:flutter/material.dart';
import 'main.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'google_drive_service.dart';

// Variável global para armazenar o estado de autenticação e o serviço autenticado
GoogleDriveService? authenticatedDriveService;

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        authenticatedDriveService = GoogleDriveService();
        await authenticatedDriveService!.signIn();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
