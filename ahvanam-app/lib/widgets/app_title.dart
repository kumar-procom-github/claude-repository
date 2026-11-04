import 'package:flutter/material.dart';

import '../i18n/app_lang.dart';
import 'lang_toggle.dart';
import 'theme_toggle.dart';

/// "Ahvanam / Invitation Maker" (or ఆహ్వానం / ఆహ్వాన పత్రికల తయారీ)
/// for the first screens' app bars.
class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('Ahvanam', 'ఆహ్వానం'), style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(context.tr('Invitation Maker', 'ఆహ్వాన పత్రికల తయారీ'), style: const TextStyle(fontSize: 12)),
        ],
      );
}

/// Language switch + light/dark button, for app bars before the details form.
const appBarToggles = <Widget>[LangToggleButton(), SizedBox(width: 2), ThemeToggleButton(), SizedBox(width: 4)];
