import 'dart:async';

import 'package:flutter/material.dart';

import 'ads/ads.dart';
import 'i18n/app_lang.dart';

import 'screens/category_screen.dart';
import 'screens/home_screen.dart';
import 'services/template_catalog.dart';
import 'services/user_prefs.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Tradition chosen on an earlier launch → skip the picker.
  await UserPrefs.load();
  unawaited(Ads.init());
  // Loads cached designs, then checks online for new ones in the background.
  TemplateCatalog.instance.init();
  runApp(const AhvanamApp());
}

class AhvanamApp extends StatelessWidget {
  const AhvanamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) => MaterialApp(
        title: 'Ahvanam: Invitation Maker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        // App language (English / Telugu) for every screen below.
        builder: (context, child) => LangScope(notifier: AppLangController.lang, child: child!),
        home: UserPrefs.tradition == null
            ? const HomeScreen()
            : CategoryScreen(tradition: UserPrefs.tradition!),
      ),
    );
  }
}
