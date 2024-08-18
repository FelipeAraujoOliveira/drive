import 'package:flutter/material.dart';
import 'main.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'google_drive_service.dart';
import 'loginScreen.dart';

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

  final String emailParaCompartilhar = "euamoobem@gmail.com"; // Defina o e-mail aqui

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        print("Usuário autenticado: ${account.email}");

        authenticatedDriveService = GoogleDriveService();
        await authenticatedDriveService!.signIn();

        // Solicitar o nome da empresa e criar a pasta correspondente
        final nomeEmpresa = await _solicitarNomeEmpresa(context);
        if (nomeEmpresa != null && nomeEmpresa.isNotEmpty) {
          final folderId = await authenticatedDriveService!.createFolder(nomeEmpresa);
          print("Pasta criada com ID: $folderId");

          // Compartilhar a pasta com o e-mail especificado
          await authenticatedDriveService!.shareFolderWithUser(folderId, emailParaCompartilhar);
          print("Pasta compartilhada com: $emailParaCompartilhar");

          // Navegar para a tela principal com a pasta correta
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MainScreen(folderId: folderId)),
          );
        } else {
          print("Nome da empresa inválido ou cancelado pelo usuário.");
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