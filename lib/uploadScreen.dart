import 'package:flutter/material.dart';
import 'google_drive_service.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class UploadScreen extends StatelessWidget {
  final GoogleDriveService _googleDriveService;
  final String _folderId;

  UploadScreen(this._googleDriveService, this._folderId);

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
              File file = File(result.files.single.path!);
              await _googleDriveService.uploadFile(file, _folderId);
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