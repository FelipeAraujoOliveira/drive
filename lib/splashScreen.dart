import 'package:flutter/material.dart';
import 'main.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'google_drive_service.dart';
import 'loginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

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

  final String emailParaCompartilhar =
      "euamoobem@gmail.com"; // Defina o e-mail aqui

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        print("Login silencioso bem-sucedido: ${account.email}");
      } else {
        print("Nenhum usuário logado.");
      }

      if (account != null) {
        authenticatedDriveService = GoogleDriveService();
        await authenticatedDriveService!.signIn();

        // Recuperar o ID da pasta salva
        String? folderId_recuperado = await getSavedFolderId();

        if (folderId_recuperado != null &&
            await doesFolderExist(account, folderId_recuperado)) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) =>
                    MainScreen(folderId: folderId_recuperado)),
          );
        } else {
          print('não recuperou');
          final nomeEmpresa = await _solicitarNomeEmpresa(context);
          if (nomeEmpresa != null && nomeEmpresa.isNotEmpty) {
            final folderId = await createFolder(nomeEmpresa);
            if (folderId != null) {
              print("Pasta criada com ID: $folderId");
              await authenticatedDriveService!
                  .shareFolderWithUser(folderId, emailParaCompartilhar);
              print("Pasta compartilhada com: $emailParaCompartilhar");

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) => MainScreen(folderId: folderId)),
              );
            } else {
              print("Erro ao criar a pasta.");
            }
          } else {
            print("Nome da empresa inválido ou cancelado pelo usuário.");
          }
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (error) {
      print("Erro durante a inicialização: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao iniciar o aplicativo: $error')),
      );
    }
  }

  Future<bool> doesFolderExist(
      GoogleSignInAccount? account, String folderId) async {
    if (account == null) return false;

    final authHeaders = await account.authHeaders;
    final httpClient = authenticatedClient(
      http.Client(),
      AccessCredentials(
        AccessToken(
          'Bearer',
          authHeaders['Authorization']!.split(" ").last,
          DateTime.now()
              .toUtc()
              .add(Duration(hours: 1)), // Certifique-se de que o DateTime é UTC
        ),
        null,
        ['https://www.googleapis.com/auth/drive.file'],
      ),
    );

    final driveApi = drive.DriveApi(httpClient);
    try {
      drive.File file =
          await driveApi.files.get(folderId, $fields: "id") as drive.File;
      return file.id != null;
    } catch (e) {
      // Se houver um erro, a pasta provavelmente não existe
      return false;
    }
  }

  Future<void> saveFolderId(String folderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('drive_folder_id', folderId);
  }

  Future<String?> createFolder(nomeEmpresa) async {
    final folderId = await authenticatedDriveService!.createFolder(nomeEmpresa);
    saveFolderId(folderId);
    return folderId;
  }

  Future<String?> getSavedFolderId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('drive_folder_id');
  }

  Future<String?> _solicitarNomeEmpresa(BuildContext context) async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Digite o nome da empresa'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Nome da empresa"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
