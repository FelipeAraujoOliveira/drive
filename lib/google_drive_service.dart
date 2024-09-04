import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io'; // Import necessário para manipulação de arquivos

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(scopes: [drive.DriveApi.driveScope]);
  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;
  http.Client? _httpClient;

  Future<void> signIn() async {
    _currentUser = await _googleSignIn.signIn();
    if (_currentUser != null) {
      final authHeaders = await _currentUser!.authHeaders;
      _httpClient = IOClient();
      final authenticatedClient = GoogleHttpClient(authHeaders, _httpClient!);
      _driveApi = drive.DriveApi(authenticatedClient);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
    _httpClient?.close();
    _httpClient = null;
  }

  Future<List<drive.File>> listFilesAndFolders(String folderId) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated');
    }

    final query = "'$folderId' in parents and trashed=false";
    final fileList = await _driveApi!.files.list(q: query, $fields: "files(id, name, mimeType, size, createdTime)");
    return fileList.files ?? [];
  }

  Future<void> uploadFile(File file, String folderId) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated');
    }

    final media = drive.Media(file.openRead(), file.lengthSync());
    final driveFile = drive.File();
    driveFile.name = file.path.split('/').last; // Define o nome do arquivo
    driveFile.parents = [folderId]; // Define a pasta onde o arquivo será salvo

    await _driveApi!.files.create(driveFile, uploadMedia: media);
  }

  Future<void> downloadFile(String fileId, File saveFile) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated');
    }

    final media = await _driveApi!.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final List<int> dataStore = [];
    media.stream.listen((data) {
      dataStore.insertAll(dataStore.length, data);
    }, onDone: () {
      saveFile.writeAsBytesSync(dataStore);
    }, onError: (error) {
      throw Exception('Error downloading file: $error');
    });
  }
}

class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client;

  GoogleHttpClient(this._headers, this._client);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _client.send(request..headers.addAll(_headers));
}
