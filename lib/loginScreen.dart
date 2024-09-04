import 'package:google_sign_in/google_sign_in.dart';
import 'google_drive_service.dart';
import 'package:googleapis/drive/v3.dart' as drive;


class LoginService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(scopes: [drive.DriveApi.driveScope]);

  Future<void> handleLogin() async {
    final GoogleDriveService driveService = GoogleDriveService();
    await driveService.signIn();

    // Redirecionar para a tela de documentos ou realizar outras ações pós-login
  }

  Future<void> handleLogout() async {
    final GoogleDriveService driveService = GoogleDriveService();
    await driveService.signOut();

    // Realizar outras ações pós-logout, se necessário
  }
}
