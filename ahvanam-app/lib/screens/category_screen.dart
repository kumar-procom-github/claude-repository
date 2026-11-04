import 'package:flutter/material.dart';

import '../ads/banner_slot.dart';
import '../models/ceremony.dart';
import '../i18n/app_lang.dart';
import '../reel/reel_drafts_screen.dart';
import '../reel/reel_editor_screen.dart';
import '../widgets/app_title.dart';
import 'ceremony_screen.dart';
import 'home_screen.dart';

/// Step 2: Celebrations or Remembrance, within the chosen tradition.
/// This is the app's start screen once a tradition has been saved.
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.tradition});
  final Tradition tradition;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      // Same app header as the first page — this is the start screen now.
      appBar: AppBar(
        title: const AppTitle(),
        actions: appBarToggles,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Current tradition, with a way back to the picker.
          Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(tradition.icon, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(context.tr(tradition.en, tradition.te),
                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  ),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: Text(context.tr('Change', 'మార్చు')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(context.tr('What would you like to make?', 'ఏం తయారు చేద్దాం?'), style: text.titleLarge),
          const SizedBox(height: 16),
          for (final c in CeremonyCategory.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                clipBehavior: Clip.antiAlias,
                color: c == CeremonyCategory.remembrance ? scheme.surfaceContainerHigh : null,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CeremonyScreen(tradition: tradition, category: c)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: scheme.primary.withAlpha(24),
                          child: Icon(c.icon, size: 30, color: scheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr(c.en, c.te),
                                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(c.examplesFor(tradition, te: LangScope.isTe(context)), style: text.bodySmall),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Plain video editor: just the user's photos and videos.
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              clipBehavior: Clip.antiAlias,
              color: const Color(0xFFFF6B4A).withAlpha(30),
              child: InkWell(
                onTap: () => openCustomReel(context),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0x33FF6B4A),
                        child: Icon(Icons.video_camera_back_outlined, size: 30, color: Color(0xFFFF6B4A)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('Video editor', 'వీడియో ఎడిటర్'),
                                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                                context.tr('Your own photos & videos, like a reel — no invitation needed',
                                    'మీ ఫోటోలు & వీడియోలతో రీల్ — ఆహ్వానం అవసరం లేదు'),
                                style: text.bodySmall),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Saved video invitations.
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReelDraftsScreen()),
              ),
              icon: const Icon(Icons.video_library_outlined),
              label: Text(context.tr('My videos (drafts)', 'నా వీడియోలు (డ్రాఫ్ట్‌లు)')),
            ),
          ),
          const BannerSlot(padding: EdgeInsets.only(top: 4)),
        ],
      ),
    );
  }
}
