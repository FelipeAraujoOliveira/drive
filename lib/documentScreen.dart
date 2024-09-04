import 'package:flutter/material.dart';
import 'google_drive_service.dart';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<void> _loadItems() async {
    try {
      final googleDriveService = GoogleDriveService();
      await googleDriveService.signIn();
      final items = await googleDriveService.listFilesAndFolders(widget.folderId);
      setState(() {
        _items = items;
      });
    } catch (error) {
      print("Erro ao carregar itens: $error");
    }
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
                    Navigator.of(modalContext).pop();
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
            SizedBox(height: 8),
            Text(
              'Tamanho: ${file.size != null ? (int.tryParse(file.size!)! / 1024).toStringAsFixed(2) : 'Desconhecido'} KB',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Data de Envio: ${file.createdTime != null ? file.createdTime!.toLocal().toString() : 'Desconhecido'}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(modalContext).pop();

                  final directory = await getApplicationDocumentsDirectory();
                  final savePath = File('${directory.path}/${file.name}');
                  bool downloadSuccess = false;

                  try {
                    final googleDriveService = GoogleDriveService();
                    await googleDriveService.signIn();
                    await googleDriveService.downloadFile(file.id!, savePath);
                    downloadSuccess = true;
                  } catch (error) {
                    print("Erro ao baixar arquivo: $error");
                  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos'),
        actions: [
          IconButton(
            icon: Icon(Icons.upload_file),
            onPressed: _uploadFile,
          ),
        ],
      ),
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
    );
  }
}
