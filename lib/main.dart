import 'package:flutter/material.dart';
import 'google_drive_service.dart';
import 'uploadScreen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'splashScreen.dart';
import 'documentScreen.dart';
import 'loginScreen.dart'; // Certifique-se de importar a tela de login

// Inicialize authenticatedDriveService na própria inicialização do aplicativo
GoogleDriveService authenticatedDriveService = GoogleDriveService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialize authenticatedDriveService
  authenticatedDriveService = GoogleDriveService();
  await authenticatedDriveService.signIn();

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

class MainScreen extends StatefulWidget {
  final String? folderId;

  MainScreen({this.folderId});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<Widget>? _screens;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  Future<void> _initializeScreens() async {
    final folderId = widget.folderId ?? "root";
    setState(() {
      _screens = [
        HomeScreen(),
        DocumentsScreen(folderId: folderId),
        UploadScreen(authenticatedDriveService, folderId),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Ação para o botão de usuário
            },
          ),
        ],
      ),
      body: _screens == null
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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