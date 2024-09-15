import 'package:google_sign_in/google_sign_in.dart';
import 'google_drive_service.dart';
import 'package:googleapis/drive/v3.dart' as drive;


class LoginService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(scopes: [drive.DriveApi.driveScope]);

  Future<void> handleLogin() async {
    final GoogleDriveService driveService = GoogleDriveService();
    await driveService.signIn();
  }

  Future<void> handleLogout() async {
    final GoogleDriveService driveService = GoogleDriveService();
    await driveService.signOut();
  }
}
