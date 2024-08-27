import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _selectedDirectory;

  @override
  void initState() {
    super.initState();
    _loadDirectoryPreference();
  }

  Future<void> _loadDirectoryPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDirectory = prefs.getString('downloadDirectory');
    });
  }

  Future<void> _chooseDirectory() async {
    String? directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath != null) {
      setState(() {
        _selectedDirectory = directoryPath;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('downloadDirectory', directoryPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenha o themeProvider usando o Provider
  

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Diretório de Download'),
            subtitle: Text(_selectedDirectory ?? 'Escolher diretório'),
            onTap: _chooseDirectory,
          ),
        ],
      ),
    );
  }
}
