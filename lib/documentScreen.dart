import 'package:flutter/material.dart';
import 'google_drive_service.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class DocumentsScreen extends StatefulWidget {
  final String folderId;

  DocumentsScreen({required this.folderId});

  @override
  _DocumentsScreenState createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<drive.File>? _items;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final googleDriveService = GoogleDriveService();
      await googleDriveService.signIn();
      final items = await googleDriveService.listFilesAndFolders(widget.folderId);
      
      // Verifica se o widget ainda está montado antes de chamar setState
      if (mounted) {
        setState(() {
          _items = items;
        });
      }
    } catch (error) {
      // Verifica se o widget ainda está montado antes de chamar setState
      if (mounted) {
        print("Erro ao carregar itens: $error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _items == null
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 4.0,
                crossAxisSpacing: 4.0,
              ),
              itemCount: _items!.length,
              itemBuilder: (context, index) {
                final item = _items![index];
                return GestureDetector(
                  onTap: () {
                    if (item.mimeType == 'application/vnd.google-apps.folder') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DocumentsScreen(folderId: item.id!),
                        ),
                      );
                    } else {
                      _showFileDetailsModal(context, item);
                    }
                  },
                  child: GridTile(
                    child: Icon(
                      item.mimeType == 'application/vnd.google-apps.folder'
                          ? Icons.folder
                          : Icons.insert_drive_file,
                      size: 50,
                    ),
                    footer: Center(
                      child: Text(
                        item.name ?? 'Sem nome',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadFile,
        child: Icon(Icons.upload_file),
      ),
    );
  }

  void _showFileDetailsModal(BuildContext context, drive.File file) {
    // Sua implementação do modal de detalhes do arquivo
  }

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      try {
        final googleDriveService = GoogleDriveService();
        await googleDriveService.signIn();
        await googleDriveService.uploadFile(file, widget.folderId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload bem-sucedido!')),
        );
        _loadItems(); // Recarrega os itens para mostrar o arquivo recém-enviado
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer upload: $error')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum arquivo selecionado.')),
      );
    }
  }
}
