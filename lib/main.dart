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

    // Verifica se authenticatedDriveService foi inicializado
    if (authenticatedDriveService == null) {
      throw Exception("authenticatedDriveService não foi inicializado corretamente.");
    }

    setState(() {
      _screens = [
        HomeScreen(),
        DocumentsScreen(folderId: folderId),
        UploadScreen(authenticatedDriveService!, folderId), // Usa o operador `!` para garantir que não é nulo
      ];
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await authenticatedDriveService?.signOut(); // Sign out from Google
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Open the drawer when the user icon is pressed
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Configurações'),
              onTap: () {
                // Navegue para a tela de configurações se necessário
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Configurações ainda não implementadas.')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await _logout(); // Chama a função de logout
              },
            ),
          ],
        ),
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
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Tela Home'),
    );
  }
}