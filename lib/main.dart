import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'notification_service.dart';
import 'theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  final themeController = ThemeController();
  await themeController.load();
  runApp(MyApp(themeController: themeController));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Reminders',
          themeMode: themeController.mode,
          theme: _buildTheme(themeController.seed.color, Brightness.light),
          darkTheme: _buildTheme(themeController.seed.color, Brightness.dark),
          home: AppShell(themeController: themeController),
        );
      },
    );
  }

  /// Material 3's default surfaces (cards, nav bar) lean on a very faint,
  /// elevation-based tint of the seed color, which reads as washed-out gray
  /// no matter which color is picked. Explicitly using the scheme's
  /// "surfaceContainerHigh" tonal step for these surfaces keeps the clean
  /// Material 3 look but makes the chosen color actually visible.
  ThemeData _buildTheme(Color seedColor, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      cardTheme: CardThemeData(color: scheme.surfaceContainerHigh),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        indicatorColor: scheme.primaryContainer,
      ),
    );
  }
}
