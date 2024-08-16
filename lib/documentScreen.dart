import 'package:flutter/material.dart';
import 'google_drive_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'splashScreen.dart';

class DocumentsScreen extends StatefulWidget {
  final String folderId;

  DocumentsScreen({required this.folderId});

  @override
  _DocumentsScreenState createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen>
    with AutomaticKeepAliveClientMixin {
  List<drive.File>? _files;
  String? _currentFolderId;

  @override
  void initState() {
    super.initState();
    _currentFolderId = widget.folderId;
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      if (authenticatedDriveService != null) {
        print("Carregando arquivos na pasta: $_currentFolderId");
        await _listFiles(_currentFolderId!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Not authenticated. Please log in again.')));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load files: $error')));
    }
  }

  Future<void> _listFiles(String folderId) async {
    try {
      final files = await authenticatedDriveService!.listFiles(folderId);
      if (files.isEmpty) {
        print("Nenhum arquivo encontrado na pasta: $folderId");
      } else {
        print("Arquivos encontrados na pasta: $folderId");
        for (var file in files) {
          print("Arquivo: ${file.name}, ID: ${file.id}");
        }
      }
      setState(() {
        _files = files;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to list files: $error')));
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

  Future<void> _downloadFile(String fileId, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final savePath = File('${directory.path}/$fileName');
    try {
      await authenticatedDriveService!.downloadFile(fileId, savePath);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Downloaded to $savePath')));
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Download failed: $error')));
    }
  }

  Future<void> _openFolder(String folderId) async {
    setState(() {
      _currentFolderId = folderId;
      _files = null; // Clear current files to show a loading indicator
    });
    _listFiles(folderId);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessário para AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        leading: _currentFolderId != widget.folderId
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  // Volta para a pasta anterior
                  _openFolder(widget.folderId);
                },
              )
            : null,
      ),
      body: _files == null
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              key: PageStorageKey<String>(_currentFolderId!), // Preserva o estado do GridView
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
            ),
    );
  }

  @override
  bool get wantKeepAlive => true; // Define que o estado deve ser mantido
}
