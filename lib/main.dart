import 'package:flutter/material.dart';
import 'google_drive_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';

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
    final account = await _googleSignIn.signInSilently();
    if (account != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
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

class LoginScreen extends StatelessWidget {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await _googleSignIn.signIn();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => MainScreen()),
              );
            } catch (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Login failed: $error')));
            }
          },
          child: Text('Sign in with Google'),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    DocumentsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              // Ação para o botão de usuário (a ser implementada)
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
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

class DocumentsScreen extends StatefulWidget {
  @override
  _DocumentsScreenState createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final GoogleDriveService _googleDriveService = GoogleDriveService();
  List<drive.File>? _files;
  bool _isSignedIn = false;
  String? _folderId;

  @override
  void initState() {
    super.initState();
    _signIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
      ),
      body: _isSignedIn
          ? _files == null
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 4.0,
                    crossAxisSpacing: 4.0,
                  ),
                  itemCount: _files!.length,
                  itemBuilder: (context, index) {
                    final file = _files![index];
                    return GestureDetector(
                      onTap: () {
                        if (file.mimeType == 'application/vnd.google-apps.folder') {
                          _openFolder(file.id!);
                        } else {
                          _downloadFile(file.id!, file.name!);
                        }
                      },
                      child: GridTile(
                        child: Icon(_getFileTypeIcon(file)),
                        footer: Center(
                          child: Text(
                            file.name ?? 'Unnamed',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  },
                )
          : const Center(child: Text('Please sign in to access your Google Drive')),
    );
  }

  Future<void> _signIn() async {
    try {
      await _googleDriveService.signIn();
      setState(() {
        _isSignedIn = true;
      });
      _folderId = await _googleDriveService.getFolderId('pasta');
      _listFiles();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $error')));
    }
  }

  Future<void> _signOut() async {
    await _googleDriveService.signOut();
    setState(() {
      _isSignedIn = false;
      _files = null;
      _folderId = null;
    });
  }

  Future<void> _listFiles() async {
    try {
      if (_folderId == null) return;
      final files = await _googleDriveService.listFiles(_folderId!);
      setState(() {
        _files = files;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to list files: $error')));
    }
  }

  // Widget _buildGridView() {
  //   return Container(
  //     color: Colors.white,
  //     child: Padding(
  //       padding: const EdgeInsets.all(8.0),
  //       child: GridView.builder(
  //         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //           crossAxisCount: 4,
  //           crossAxisSpacing: 4.0,
  //           mainAxisSpacing: 4.0,
  //         ),
  //         itemCount: _files?.length ?? 0,
  //         itemBuilder: (context, index) {
  //           final file = _files![index];
  //           final fileTypeIcon = _getFileTypeIcon(file);

  //           return GestureDetector(
  //             onTap: () async {
  //               if (await _googleDriveService.isFolder(file.id!)) {
  //                 await _openFolder(file.id!);
  //               } else {
  //                 await _downloadFile(file.id!, file.name!);
  //               }
  //             },
  //             child: GridTile(
  //               header: Text(file.name ?? 'Unnamed'),
  //               child: Icon(fileTypeIcon, size: 48.0),
  //             ),
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }

  IconData _getFileTypeIcon(drive.File file) {
    if (file.mimeType == 'application/vnd.google-apps.folder') {
      return Icons.folder;
    } else if (file.mimeType?.startsWith('image/') ?? false) {
      return Icons.image;
    } else if (file.mimeType?.startsWith('video/') ?? false) {
      return Icons.videocam;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Future<void> _downloadFile(String fileId, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final savePath = File('${directory.path}/$fileName');
    try {
      await _googleDriveService.downloadFile(fileId, savePath);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Downloaded to $savePath')));
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Download failed: $error')));
    }
  }

  Future<void> _openFolder(String folderId) async {
    setState(() {
      _folderId = folderId;
      _files = null; // Clear current files to show a loading indicator
    });
    _listFiles();
  }
}
