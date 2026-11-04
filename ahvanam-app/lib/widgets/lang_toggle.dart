import 'package:flutter/material.dart';

import '../i18n/app_lang.dart';
import '../services/user_prefs.dart';

/// Small "EN | తె" switch for the app bar, next to the light/dark button.
class LangToggleButton extends StatelessWidget {
  const LangToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final te = LangScope.isTe(context);
    Widget part(String label, bool on) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: on ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: on ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        );
    return Tooltip(
      message: te ? 'Switch to English' : 'తెలుగులోకి మార్చండి',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          final next = te ? AppLang.en : AppLang.te;
          AppLangController.lang.value = next;
          UserPrefs.saveAppLang(next);
        },
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [part('EN', !te), part('తె', te)]),
        ),
      ),
    );
  }
}
