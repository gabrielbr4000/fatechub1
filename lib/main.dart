import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:fatechub2/controllers/theme_controller.dart';
import 'package:fatechub2/view/view_login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final ThemeController _themeController = ThemeController();
Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) => DevicePreview(
        enabled: !kReleaseMode,
        builder: (context) => MyApp(themeController: _themeController),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final ThemeController themeController;
  const MyApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      themeMode: themeController.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B0000)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B0000),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: TelaLogin(themeController: _themeController),
    );
  }
}