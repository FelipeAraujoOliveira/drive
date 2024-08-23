import 'dart:async';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class GoogleDriveService {
  final GoogleSignIn _googleSignIn =
      GoogleSignIn.standard(scopes: [drive.DriveApi.driveScope]);
  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;
  http.Client? _httpClient;

  //login
  Future<void> signIn() async {
  try {
    _currentUser = await _googleSignIn.signIn();
    if (_currentUser == null) {
      throw Exception('Login cancelado pelo usuário.');
    }

    final authHeaders = await _currentUser!.authHeaders;
    _httpClient = IOClient();
    final authenticatedClient = GoogleHttpClient(authHeaders, _httpClient!);
    _driveApi = drive.DriveApi(authenticatedClient);

    print("Usuário autenticado: ${_currentUser?.email}");
    print("Drive API inicializado com sucesso.");
  } catch (error) {
    print("Erro durante a autenticação: $error");
    throw Exception('Falha no login: $error');
  }
}



  //logout
  Future<void> signOut() async {
  try {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
    _httpClient?.close();
    _httpClient = null; // Certifique-se de que o httpClient seja completamente redefinido
    print("Usuário deslogado com sucesso.");
  } catch (error) {
    print("Erro durante o logout: $error");
  }
}



  //obter usuario atual
  GoogleSignInAccount? getCurrentUser() {
    print("Usuário atual: ${_currentUser?.email}");
    return _currentUser;
  }

  // Verificar se uma pasta existe
  Future<bool> doesFolderExist(String folderId) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated');
    }

    try {
      final file = await _driveApi!.files.get(folderId, $fields: 'id') as drive.File;
      return file.id != null;
    } catch (e) {
      // Se houver um erro, a pasta provavelmente não existe ou o ID está incorreto
      print('Erro ao verificar a existência da pasta: $e');
      return false;
    }
  }

  //definir id da pasta
  Future<String> getFolderId(String folderName,
      {String? parentFolderId}) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated');
    }

    final query =
        "'${parentFolderId ?? 'root'}' in parents and name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    final fileList = await _driveApi!.files.list(q: query);
    final folder =
        fileList.files?.firstWhere((file) => file.name == folderName);
    if (folder == null) {
      throw Exception('Folder not found');
    }
    return folder.id!;
  }

  //listar arquivos
  Future<List<drive.File>> listFiles(String folderId) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated');
    }

    final query = "'$folderId' in parents and trashed = false";
    final fileList = await _driveApi!.files.list(q: query);
    return fileList.files ?? [];
  }

  //carregar arquivo
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

  //baixar arquivo
  Future<void> downloadFile(String fileId, File saveFile) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated');
    }

    if (!await isFolder(fileId)) {
      final media = await _driveApi!.files.get(fileId,
          downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

      final List<int> bytes = await _readStream(media.stream);
      await saveFile.writeAsBytes(bytes);
    }
  }

  //verificar se é uma pasta
  Future<bool> isFolder(String fileId) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated');
    }
    try {
      final file =
          await _driveApi!.files.get(fileId, $fields: 'mimeType') as drive.File;

      return file.mimeType == 'application/vnd.google-apps.folder';
    } catch (e) {
      print('Erro ao verificar o tipo do arquivo: $e');
      return false;
    }
  }

  Future<String> createFolder(String folderName) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated');
    }

    final folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final folderCreation = await _driveApi!.files.create(folder);
    return folderCreation.id!;
  }

  Future<void> shareFolderWithUser(String folderId, String userEmail) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated');
    }

    final permission = drive.Permission()
      ..type = "user"
      ..role = "writer"
      ..emailAddress = userEmail;

    await _driveApi!.permissions.create(
      permission,
      folderId,
      sendNotificationEmail: false,
    );
  }
}

Future<List<int>> _readStream(Stream<List<int>> stream) async {
  final List<int> bytes = [];
  await for (final List<int> chunk in stream) {
    bytes.addAll(chunk);
  }
  return bytes;
}

class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client;

  GoogleHttpClient(this._headers, this._client);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
