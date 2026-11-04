import 'package:flutter/material.dart';

import '../services/user_prefs.dart';
import '../theme/app_theme.dart';

/// Sun / moon button for the app bar. Switches between light and dark
/// and remembers the choice.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'Light mode' : 'Dark mode',
      onPressed: () {
        final next = isDark ? ThemeMode.light : ThemeMode.dark;
        ThemeController.mode.value = next;
        UserPrefs.saveThemeMode(next);
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (c, a) => RotationTransition(turns: a, child: FadeTransition(opacity: a, child: c)),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey(isDark),
        ),
      ),
    );
  }
}
