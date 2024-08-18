import 'package:flutter/material.dart';
import 'google_drive_service.dart';
import 'main.dart';
import 'google_drive_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class LoginScreen extends StatelessWidget {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  final GoogleDriveService _googleDriveService = GoogleDriveService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await _googleSignIn.signIn();
              await _handleAfterLogin(context);
            } catch (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Login failed: $error')),
              );
            }
          },
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }

  Future<void> _handleAfterLogin(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final String? userName = await _getUserName(context, nameController);

    if (userName != null && userName.isNotEmpty) {
      await _googleDriveService.signIn(); // Garantindo que o serviço está autenticado
      final folderId = await _googleDriveService.createFolder(userName);
      await _googleDriveService.shareFolderWithUser(
          folderId, "euamoobem@gmail.com");

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainScreen(folderId: folderId)),
      );
    }
  }

  Future<String?> _getUserName(
      BuildContext context, TextEditingController controller) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Digite seu nome'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Nome"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
