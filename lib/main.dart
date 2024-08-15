import 'package:flutter/material.dart';
import 'google_drive_service.dart';
import 'uploadScreen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'splashScreen.dart';
import 'documentScreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Drive App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}

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
      await _googleDriveService
          .signIn(); // Garantindo que o serviço está autenticado
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

class MainScreen extends StatefulWidget {
  final String? folderId;

  MainScreen({this.folderId});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late GoogleDriveService _googleDriveService;
  List<Widget>? _screens;

  @override
  void initState() {
    super.initState();
    _googleDriveService = GoogleDriveService();
    _initializeScreens();
  }

  void _initializeScreens() {
    setState(() {
      _screens = [
        HomeScreen(),
        DocumentsScreen(folderId: widget.folderId!), // Passando o folderId
        UploadScreen(_googleDriveService, widget.folderId!),
      ];
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_screens == null && widget.folderId != null) {
      _initializeScreens();
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Ação para o botão de usuário (a ser implementada)
            },
          ),
        ],
      ),
      body: widget.folderId == null
          ? const Center(child: CircularProgressIndicator())
          : _screens![_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Documentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}


class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Tela Home'),
    );
  }
}
