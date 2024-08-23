import 'package:flutter/material.dart';
import 'google_drive_service.dart';
import 'main.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splashScreen.dart';

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
  try {
    await _googleDriveService.signIn(); // Autenticação e inicialização da API

    String? folderId = await _getSavedFolderId();

    if (folderId != null && await _googleDriveService.doesFolderExist(folderId)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainScreen(folderId: folderId)),
      );
      print("Pasta existente recuperada com sucesso: $folderId");
    } else {
      final TextEditingController nameController = TextEditingController();
      final String? userName = await _getUserName(context, nameController);

      if (userName != null && userName.isNotEmpty) {
        folderId = await _googleDriveService.createFolder(userName);
        await _saveFolderId(folderId);
        await _googleDriveService.shareFolderWithUser(folderId, "euamoobem@gmail.com");

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainScreen(folderId: folderId)),
        );
        print("Nova pasta criada e compartilhada com sucesso: $folderId");
      }
    }
  } catch (error) {
    print("Erro durante o processo de login e inicialização: $error");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao processar o login: $error')),
    );
  }
}


  
  Future<String?> _getSavedFolderId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('drive_folder_id');
  }

  Future<void> _saveFolderId(String folderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('drive_folder_id', folderId);
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
