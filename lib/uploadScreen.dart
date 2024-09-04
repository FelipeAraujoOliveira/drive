import 'package:flutter/material.dart';
import 'google_drive_service.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UploadScreen extends StatelessWidget {
  final GoogleDriveService _googleDriveService;

  UploadScreen(this._googleDriveService);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload de Arquivo'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles();

            if (result != null) {
              File file = File(result.files.single.path!); // Usa o File de dart:io

              // Obter o diretório de upload salvo ou usar um padrão
              SharedPreferences prefs = await SharedPreferences.getInstance();
              String? directoryPath = prefs.getString('uploadDirectory');
              if (directoryPath == null) {
                directoryPath = 'some-default-folder-id'; // Substitua pelo ID da pasta padrão
              }

              await _googleDriveService.uploadFile(file, directoryPath);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upload bem-sucedido!')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nenhum arquivo selecionado.')),
              );
            }
          },
          child: const Text('Escolher arquivo para upload'),
        ),
      ),
    );
  }
}
