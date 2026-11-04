import 'package:flutter/material.dart';

import '../ads/banner_slot.dart';
import '../i18n/app_lang.dart';
import 'reel_editor_screen.dart';
import 'reel_project.dart';

/// Saved video invitations ("Drafts"), newest first.
class ReelDraftsScreen extends StatefulWidget {
  const ReelDraftsScreen({super.key, this.currentId});

  /// The reel open in the editor (opened from there), if any.
  final String? currentId;

  @override
  State<ReelDraftsScreen> createState() => _ReelDraftsScreenState();
}

class _ReelDraftsScreenState extends State<ReelDraftsScreen> {
  late Future<List<ReelProject>> _list = ReelStore.list();
  List<ReelProject> _items = const [];

  /// Ids picked for deleting (long-press starts picking).
  final _picked = <String>{};
  bool get _picking => _picked.isNotEmpty;

  String _when(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '${two(t.day)}-${two(t.month)}-${t.year} · $h:${two(t.minute)} ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Deletes [drafts] after one confirmation.
  Future<void> _delete(List<ReelProject> drafts) async {
    if (drafts.isEmpty) return;
    final one = drafts.length == 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(one
            ? c.tr('Delete this video draft?', 'ఈ వీడియో డ్రాఫ్ట్ తొలగించాలా?')
            : c.tr('Delete ${drafts.length} video drafts?', '${drafts.length} వీడియో డ్రాఫ్ట్‌లు తొలగించాలా?')),
        content: Text(c.tr('Photos and videos added only to them are removed from the app (not from your gallery).',
            'వీటికి మాత్రమే జోడించిన ఫోటోలు, వీడియోలు యాప్ నుండి తొలగించబడతాయి (గ్యాలరీ నుండి కాదు).')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(c.tr('Cancel', 'వద్దు'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(c.tr('Delete', 'తొలగించు'))),
        ],
      ),
    );
    if (ok != true) return;
    for (final d in drafts) {
      await ReelStore.delete(d);
    }
    if (!mounted) return;
    setState(() {
      _picked.clear();
      _list = ReelStore.list();
    });
  }

  void _toggle(ReelProject p) {
    if (p.id == widget.currentId) return; // the open one can't be deleted
    setState(() {
      if (!_picked.remove(p.id)) _picked.add(p.id);
    });
  }

  void _open(ReelProject p) {
    if (_picking) {
      _toggle(p);
      return;
    }
    // Opened from the editor: hand the choice back; it swaps the open reel.
    if (widget.currentId != null) {
      Navigator.of(context).pop(p.id == widget.currentId ? null : p);
      return;
    }
    openReelProject(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectable = [for (final p in _items) if (p.id != widget.currentId) p];
    final allPicked = selectable.isNotEmpty && selectable.every((p) => _picked.contains(p.id));
    return PopScope(
      canPop: !_picking,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_picked.clear);
      },
      child: Scaffold(
        appBar: _picking
            ? AppBar(
                leading: IconButton(
                  tooltip: context.tr('Cancel', 'వద్దు'),
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(_picked.clear),
                ),
                title: Text(context.tr('${_picked.length} selected', '${_picked.length} ఎంచుకున్నారు')),
                actions: [
                  IconButton(
                    tooltip: allPicked ? context.tr('Select none', 'ఏదీ వద్దు') : context.tr('Select all', 'అన్నీ ఎంచుకోండి'),
                    icon: Icon(allPicked ? Icons.deselect : Icons.select_all),
                    onPressed: () => setState(() {
                      if (allPicked) {
                        _picked.clear();
                      } else {
                        _picked.addAll(selectable.map((p) => p.id));
                      }
                    }),
                  ),
                  IconButton(
                    tooltip: context.tr('Delete', 'తొలగించు'),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete([for (final p in _items) if (_picked.contains(p.id)) p]),
                  ),
                  const SizedBox(width: 4),
                ],
              )
            : AppBar(title: Text(context.tr('My videos', 'నా వీడియోలు'))),
        body: FutureBuilder<List<ReelProject>>(
          future: _list,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final list = snap.data!;
            _items = list;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(Icons.movie_creation_outlined, size: 56, color: scheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('No video drafts yet.\nFill the details of any function and tap Video.',
                              'ఇంకా వీడియో డ్రాఫ్ట్‌లు లేవు.\nఏదైనా వేడుక వివరాలు నింపి "వీడియో" నొక్కండి.'),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else if (!_picking)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(context.tr('Long-press to select several and delete them together.',
                        'ఒకేసారి ఎక్కువ తొలగించడానికి నొక్కి పట్టండి.'),
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  ),
                for (final p in list)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: _picked.contains(p.id) ? scheme.primaryContainer : null,
                    child: ListTile(
                      onTap: () => _open(p),
                      onLongPress: () => _toggle(p),
                      leading: _picking
                          ? Checkbox(
                              value: _picked.contains(p.id),
                              onChanged: p.id == widget.currentId ? null : (_) => _toggle(p),
                            )
                          : CircleAvatar(
                              backgroundColor: scheme.primaryContainer,
                              child: Icon(p.custom ? Icons.video_camera_back_outlined : p.ceremony.icon,
                                  color: scheme.onPrimaryContainer),
                            ),
                      title: Text(p.custom
                          ? context.tr('Custom video', 'నా వీడియో')
                          : context.tr(p.ceremony.en, p.ceremony.te)),
                      subtitle: Text(
                        '${p.clips.length} ${p.clips.length == 1 ? context.tr('clip', 'క్లిప్') : context.tr('clips', 'క్లిప్‌లు')}'
                        ' · ${p.total.toStringAsFixed(0)} s\n${_when(p.saved)}'
                        '${p.id == widget.currentId ? ' · ${context.tr('open now', 'ఇప్పుడు తెరిచి ఉంది')}' : ''}',
                      ),
                      isThreeLine: true,
                      trailing: _picking
                          ? null
                          : IconButton(
                              tooltip: context.tr('Delete', 'తొలగించు'),
                              icon: const Icon(Icons.delete_outline),
                              onPressed: p.id == widget.currentId ? null : () => _delete([p]),
                            ),
                    ),
                  ),
                const BannerSlot(),
              ],
            );
          },
        ),
      ),
    );
  }
}
