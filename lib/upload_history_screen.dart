import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'google_drive_service.dart'; // Assumindo que seu serviço de Google Drive já está implementado
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'splashScreen.dart'; // Importa a tela SplashScreen

class UploadHistoryScreen extends StatefulWidget {
  @override
  _UploadHistoryScreenState createState() => _UploadHistoryScreenState();
}

class _UploadHistoryScreenState extends State<UploadHistoryScreen> {
  Map<String, List<drive.File>> _cachedUploads = {}; // Cache dos uploads para evitar recarga
  Map<String, String> _folderNames = {}; // Nomes das pastas
  bool _isLoading = true; // Estado de carregamento
  bool _hasLoadedOnce = false; // Verifica se os arquivos foram carregados uma vez

  @override
  void initState() {
    super.initState();
    if (!_hasLoadedOnce) {
      _loadFilteredUploads(); // Carrega os dados apenas se nunca foi feito
    }
  }

  // Função para carregar apenas pastas que começam com "$"
  Future<void> _loadFilteredUploads() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final googleDriveService = Provider.of<GoogleDriveService>(context, listen: false);
      await googleDriveService.signIn(); // Certifica que a autenticação foi feita
      final allFolders = await googleDriveService.getRecentUploadsByFolder();

      // Filtra as pastas que começam com "$"
      Map<String, List<drive.File>> filteredFolders = {};
      for (String folderId in allFolders.keys) {
        final folderName = await googleDriveService.getFolderName(folderId);

        if (folderName.startsWith('\$')) {
          filteredFolders[folderId] = allFolders[folderId]!; // Adiciona apenas pastas que começam com "$"
          _folderNames[folderId] = folderName; // Armazena o nome da pasta
        }
      }

      setState(() {
        _cachedUploads = filteredFolders;
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    } catch (error) {
      print("Erro ao carregar histórico: $error");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função de logout
  Future<void> _logout() async {
    final googleDriveService = Provider.of<GoogleDriveService>(context, listen: false);
    await googleDriveService.signOut(); // Desconecta do Google Drive
    // Redireciona para a SplashScreen após o logout
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()), // SplashScreen como destino
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Desconectado com sucesso!')),
    );
  }

  // Função de upload de arquivo para a pasta selecionada
  Future<void> _uploadFile(String folderId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      try {
        final googleDriveService = Provider.of<GoogleDriveService>(context, listen: false);
        await googleDriveService.uploadFile(file, folderId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload bem-sucedido!')),
        );
        _loadFilteredUploads(); // Recarrega os itens para mostrar o arquivo recém-enviado
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

  // Função para exibir o modal de download
  Future<void> _showDownloadDialog(BuildContext context, drive.File file) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Baixar Arquivo'),
          content: Text('Você deseja baixar o arquivo "${file.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o modal
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o modal
                _downloadFile(file); // Chama a função de download
              },
              child: const Text('Baixar'),
            ),
          ],
        );
      },
    );
  }

  // Função para baixar o arquivo
  Future<void> _downloadFile(drive.File file) async {
    try {
      final googleDriveService = Provider.of<GoogleDriveService>(context, listen: false);
      final savePath = await FilePicker.platform.getDirectoryPath(); // Pede ao usuário para escolher a pasta de destino
      if (savePath != null) {
        File saveFile = File('$savePath/${file.name}');
        await googleDriveService.downloadFile(file.id!, saveFile);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download de "${file.name}" concluído!')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao baixar arquivo: $error')),
      );
    }
  }

  // Exibe o ícone baseado no tipo de arquivo
  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('application/vnd.google-apps.folder')) {
      return Icons.folder;
    } else if (mimeType.startsWith('image/')) {
      return Icons.image;
    } else if (mimeType.startsWith('application/pdf')) {
      return Icons.picture_as_pdf;
    } else if (mimeType.startsWith('application/msword') ||
        mimeType.startsWith('application/vnd.openxmlformats-officedocument.wordprocessingml')) {
      return Icons.article;
    } else {
      return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Uploads'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout, // Função de logout ao pressionar o botão
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Exibe a espiral de carregamento
          : _cachedUploads.isEmpty
              ? const Center(child: Text('Nenhum upload recente encontrado.'))
              : ListView.builder(
                  itemCount: _cachedUploads.keys.length,
                  itemBuilder: (context, index) {
                    String folderId = _cachedUploads.keys.elementAt(index);
                    List<drive.File> files = _cachedUploads[folderId]!;

                    // Verifica se o nome da pasta já foi carregado
                    String folderName = _folderNames[folderId] ?? 'Carregando...';

                    return ExpansionTile(
                      title: Text('$folderName'),
                      children: [
                        ...files.map((file) {
                          return ListTile(
                            leading: Icon(_getFileIcon(file.mimeType ?? '')),
                            title: Text(file.name ?? 'Sem Nome'),
                            subtitle: Text('Modificado em: ${file.modifiedTime}'),
                            onTap: () {
                              _showDownloadDialog(context, file); // Exibe o modal com a opção de download
                            },
                          );
                        }).toList(),
                        ListTile(
                          title: ElevatedButton.icon(
                            onPressed: () => _uploadFile(folderId), // Chama o upload para esta pasta
                            icon: const Icon(Icons.upload_file),
                            label: Text('Fazer Upload para "$folderName"'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
