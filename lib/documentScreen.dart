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
        final files =
            await authenticatedDriveService!.listFiles(widget.folderId);
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
                          builder: (context) =>
                              DocumentsScreen(folderId: file.id!),
                        ),
                      );
                    } else {
                      _showFileDetailsModal(context, file);
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

  void _showFileDetailsModal(BuildContext context, drive.File file) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext modalContext) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detalhes do Arquivo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(modalContext).pop(); // Usar o context do modal aqui
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Nome: ${file.name}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Tipo: ${file.mimeType ?? 'Desconhecido'}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(modalContext).pop(); // Feche o modal primeiro

                  final directory = await getApplicationDocumentsDirectory();
                  final savePath = File('${directory.path}/${file.name}');
                  bool downloadSuccess = false;

                  try {
                    await authenticatedDriveService!.downloadFile(file.id!, savePath);
                    downloadSuccess = true;
                  } catch (error) {
                    print("Erro ao baixar arquivo: $error");
                  }

                  // Depois que o modal for fechado, mostre o SnackBar
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          downloadSuccess ? 'Download concluído para ${savePath.path}' : 'Falha no download',
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.download),
                label: Text('Fazer Download'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Desconhecido';
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
