import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'google_drive_service.dart';
import 'home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<GoogleDriveService>(create: (_) => GoogleDriveService()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: HomeScreen(),
    );
  }
}
