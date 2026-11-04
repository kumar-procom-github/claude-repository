import 'package:flutter/material.dart';

import '../ads/banner_slot.dart';
import '../i18n/app_lang.dart';
import '../widgets/app_title.dart';
import '../models/ceremony.dart';
import 'details_screen.dart';

/// Step 2: choose the ceremony within the chosen tradition.
///
/// Greetings are for everyone (a Hindu family wishes a Christian friend a
/// happy Christmas): a filter shows all festivals, or one tradition's plus
/// the common ones, starting with the user's own tradition.
class CeremonyScreen extends StatefulWidget {
  const CeremonyScreen({super.key, required this.tradition, required this.category});
  final Tradition tradition;
  final CeremonyCategory category;

  @override
  State<CeremonyScreen> createState() => _CeremonyScreenState();
}

class _CeremonyScreenState extends State<CeremonyScreen> {
  Tradition get tradition => widget.tradition;
  CeremonyCategory get category => widget.category;
  bool get _greetings => category == CeremonyCategory.greeting;

  /// Greetings filter: null = all festivals.
  late Tradition? _filter = tradition;

  List<Ceremony> get _list {
    if (!_greetings) return ceremoniesFor(tradition, category);
    final all = [for (final c in allCeremonies) if (c.category == CeremonyCategory.greeting) c];
    bool common(Ceremony c) => c.traditions.length == Tradition.values.length;
    final f = _filter;
    if (f != null) {
      // That tradition's own festivals first, then the common ones.
      return [
        ...all.where((c) => !common(c) && c.traditions.contains(f)),
        ...all.where(common),
      ];
    }
    // All: the user's own first, then common, then the others.
    return [
      ...all.where((c) => !common(c) && c.traditions.contains(tradition)),
      ...all.where(common),
      ...all.where((c) => !common(c) && !c.traditions.contains(tradition)),
    ];
  }

  /// A greeting from another tradition opens with that tradition's
  /// designs and header lines (Christmas → chapel, bells, cross …).
  Tradition _traditionFor(Ceremony c) => c.traditions.contains(tradition) ? tradition : c.traditions.first;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final list = _list;
    return Scaffold(
      appBar: AppBar(
        title: Text(_greetings
            ? context.tr(category.en, category.te)
            : context.tr('${tradition.en} · ${category.en}', '${tradition.te} · ${category.te}')),
        actions: appBarToggles,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Text(
                switch (category) {
                  CeremonyCategory.remembrance => context.tr('Which remembrance ceremony?', 'ఏ సంస్మరణ కార్యక్రమం?'),
                  CeremonyCategory.greeting => context.tr('Which occasion?', 'ఏ సందర్భానికి శుభాకాంక్షలు?'),
                  CeremonyCategory.celebration => context.tr('What are you celebrating?', 'మీ వేడుక ఏమిటి?'),
                },
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          if (_greetings)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: Text(context.tr('All festivals', 'అన్ని పండుగలు')),
                      selected: _filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                    // The user's own tradition first.
                    for (final t in [tradition, ...Tradition.values.where((x) => x != tradition)])
                      ChoiceChip(
                        avatar: Icon(t.icon, size: 18),
                        label: Text(context.tr(t.en, t.te)),
                        selected: _filter == t,
                        onSelected: (_) => setState(() => _filter = t),
                      ),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                for (final c in list)
                  Card(
                    color: scheme.surfaceContainerHighest,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      // Card starts in the app's language; last saved details come back.
                      onTap: () => openDetails(context, c, _traditionFor(c)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(c.icon, size: 34, color: scheme.primary),
                            const SizedBox(height: 8),
                            Text(context.tr(c.en, c.te),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverToBoxAdapter(child: BannerSlot(padding: EdgeInsets.zero)),
          ),
        ],
      ),
    );
  }
}
