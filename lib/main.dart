import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'google_drive_service.dart';
import 'documentScreen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<GoogleDriveService>(create: (_) => GoogleDriveService()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final googleDriveService = Provider.of<GoogleDriveService>(context, listen: false);
            await googleDriveService.signIn();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => DocumentsScreen()),
            );
          },
          child: const Text('Login com Google Drive'),
        ),
      ),
    );
  }
}
