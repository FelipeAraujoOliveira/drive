import 'package:flutter/material.dart';
import 'google_drive_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'splashScreen.dart';
import 'package:flutter/scheduler.dart';

class DocumentsScreen extends StatefulWidget {
  final String folderId;

  DocumentsScreen({required this.folderId});

  @override
  _DocumentsScreenState createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<drive.File>? _files;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      if (authenticatedDriveService != null) {
        print("Carregando arquivos da pasta com ID: ${widget.folderId}");
        final files = await authenticatedDriveService!.listFiles(widget.folderId);
        setState(() {
          _files = files;
        });
      } else {
        print("authenticatedDriveService é nulo na DocumentsScreen");
      }
    } catch (error) {
      print("Erro ao carregar arquivos: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos'),
      ),
      body: _files == null
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DocumentsScreen(folderId: file.id!),
                        ),
                      );
                    } else {
                      _downloadFile(file.id!, file.name!);
                    }
                  },
                  child: GridTile(
                    child: Icon(
                      file.mimeType == 'application/vnd.google-apps.folder'
                          ? Icons.folder
                          : Icons.insert_drive_file,
                    ),
                    footer: Center(
                      child: Text(
                        file.name ?? 'Sem nome',
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

  Future<void> _downloadFile(String fileId, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final savePath = File('${directory.path}/$fileName');
    try {
      await authenticatedDriveService!.downloadFile(fileId, savePath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded to $savePath')),
      );
    } catch (error) {
      print("Erro ao baixar arquivo: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $error')),
      );
    }
  }
}