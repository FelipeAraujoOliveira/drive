import 'package:flutter/material.dart';
import 'google_drive_service.dart';
import 'package:provider/provider.dart';
import 'upload_history_screen.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final googleDriveService =
                Provider.of<GoogleDriveService>(context, listen: false);
            await googleDriveService.signIn();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => UploadHistoryScreen()),
            );
          },
          child: const Text('Login com Google Drive'),
        ),
      ),
    );
  }
}
