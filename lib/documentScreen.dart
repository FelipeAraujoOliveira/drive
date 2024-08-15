import 'package:flutter/material.dart';
import 'google_drive_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;

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
    _signInAndLoadFiles();
  }

  Future<void> _signInAndLoadFiles() async {
    try {
      await _googleDriveService.signIn();
      setState(() {
        _isSignedIn = true;
      });
      _folderId = await _googleDriveService.getFolderId('pasta');
      _listFiles();
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Sign in failed: $error')));
    }
  }

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
                        if (file.mimeType ==
                            'application/vnd.google-apps.folder') {
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
          : const Center(
              child: Text('Please sign in to access your Google Drive')),
    );
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