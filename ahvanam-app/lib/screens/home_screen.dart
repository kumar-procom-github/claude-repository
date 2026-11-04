import 'package:flutter/material.dart';

import '../ads/banner_slot.dart';
import '../models/ceremony.dart';
import '../i18n/app_lang.dart';
import '../widgets/app_title.dart';
import '../services/user_prefs.dart';
import 'category_screen.dart';

/// Step 1: choose the community — Hindu, Muslim or Christian.
/// Shown on first launch only; the choice is saved and the app opens
/// straight to its ceremonies afterwards. Reached again from the
/// "Change" button on the category screen.
/// Everything after this (ceremonies, header lines, functions, designs)
/// follows the choice.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _accent = {
    Tradition.hindu: Color(0xFFC0571A),
    Tradition.muslim: Color(0xFF1E7A4A),
    Tradition.christian: Color(0xFF2E5A9E),
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const AppTitle(),
        actions: appBarToggles,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(context.tr('Choose your tradition', 'మీ సంప్రదాయాన్ని ఎంచుకోండి'), style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
              context.tr("We'll remember this. You can change it any time.",
                  'ఇది గుర్తుంచుకుంటాం. ఎప్పుడైనా మార్చుకోవచ్చు.'),
              style: text.bodySmall),
          const SizedBox(height: 16),
          for (final t in Tradition.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () async {
                    await UserPrefs.saveTradition(t);
                    if (!context.mounted) return;
                    // Make the chosen tradition the app's new start screen.
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => CategoryScreen(tradition: t)),
                      (_) => false,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: _accent[t]!.withAlpha(28),
                          child: Icon(t.icon, size: 30, color: _accent[t]),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr(t.en, t.te),
                                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(context.tr(t.examples, t.examplesTe), style: text.bodySmall),
                            ],
                          ),
                        ),
                        Icon(UserPrefs.tradition == t ? Icons.check_circle : Icons.chevron_right,
                            color: UserPrefs.tradition == t ? _accent[t] : null),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const BannerSlot(padding: EdgeInsets.only(top: 4)),
        ],
      ),
    );
  }
}
