import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io'; // Importar a classe File para manipulação de arquivos locais

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(scopes: [drive.DriveApi.driveScope]);
  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;
  http.Client? _httpClient;

  // Função para verificar se o usuário está autenticado
  bool get isAuthenticated => _currentUser != null;

  Future<void> signIn() async {
    _currentUser = await _googleSignIn.signIn();
    if (_currentUser != null) {
      final authHeaders = await _currentUser!.authHeaders;
      _httpClient = IOClient();
      final authenticatedClient = GoogleHttpClient(authHeaders, _httpClient!);
      _driveApi = drive.DriveApi(authenticatedClient);
    } else {
      throw Exception('Usuário não autenticado.');
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
    final fileList = await _driveApi!.files.list(
        q: query, $fields: "files(id, name, mimeType, size, createdTime)");
    return fileList.files ?? [];
  }

  Future<void> uploadFile(File file, String folderId) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated');
    }

    final media = drive.Media(file.openRead(), file.lengthSync());
    final driveFile = drive.File();
    driveFile.name = file.path.split('/').last;
    driveFile.parents = [folderId];

    await _driveApi!.files.create(driveFile, uploadMedia: media);
  }

  Future<String> getFolderName(String folderId) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated');
    }

    final folder = await _driveApi!.files.get(folderId, $fields: 'name') as drive.File;
    return folder.name ?? 'Sem Nome';
  }

  Future<Map<String, List<drive.File>>> getRecentUploadsByFolder() async {
    if (_driveApi == null) {
      throw Exception('Not authenticated');
    }

    final String query = "trashed = false";
    final fileList = await _driveApi!.files.list(
      q: query,
      orderBy: 'modifiedTime desc',
      $fields: "files(id, name, mimeType, parents, modifiedTime)",
    );

    Map<String, List<drive.File>> uploadsByFolder = {};

    if (fileList.files != null) {
      for (var file in fileList.files!) {
        if (file.parents != null && file.parents!.isNotEmpty) {
          String parentId = file.parents!.first;
          if (!uploadsByFolder.containsKey(parentId)) {
            uploadsByFolder[parentId] = [];
          }
          uploadsByFolder[parentId]!.add(file);
        }
      }
    }

    return uploadsByFolder;
  }

  Future<void> downloadFile(String fileId, File saveFile) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated');
    }

    try {
      final drive.File driveFile = await _driveApi!.files.get(fileId, $fields: 'mimeType') as drive.File;

      if (driveFile.mimeType != null && driveFile.mimeType!.startsWith('application/vnd.google-apps')) {
        String exportMimeType;
        if (driveFile.mimeType == 'application/vnd.google-apps.document') {
          exportMimeType = 'application/pdf';
        } else if (driveFile.mimeType == 'application/vnd.google-apps.spreadsheet') {
          exportMimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        } else if (driveFile.mimeType == 'application/vnd.google-apps.presentation') {
          exportMimeType = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
        } else {
          throw Exception('Tipo de arquivo do Google não suportado');
        }

        final media = await _driveApi!.files.export(fileId, exportMimeType, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media?;

        if (media != null) {
          final Stream<List<int>> mediaStream = media.stream;
          final fileSink = saveFile.openWrite();
          await mediaStream.pipe(fileSink);
          await fileSink.close();
        } else {
          throw Exception('Falha ao exportar arquivo.');
        }
      } else {
        final media = await _driveApi!.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media?;

        if (media != null) {
          final Stream<List<int>> mediaStream = media.stream;
          final fileSink = saveFile.openWrite();
          await mediaStream.pipe(fileSink);
          await fileSink.close();
        } else {
          throw Exception('Falha ao baixar arquivo.');
        }
      }
    } catch (error) {
      throw Exception('Erro ao baixar arquivo: $error');
    }
  }
}

class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client;

  GoogleHttpClient(this._headers, this._client);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _client.send(request..headers.addAll(_headers));
}
