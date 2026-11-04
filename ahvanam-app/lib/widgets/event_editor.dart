import 'package:flutter/material.dart';

import '../models/ceremony.dart';
import '../models/event_item.dart';
import '../wording/dates.dart';
import '../wording/transliterator.dart';
import 'telugu_backspace.dart';

/// Bottom sheet to add or edit one function (Haldi, Sangeet, Reception …).
/// Returns the edited [EventItem], or null if cancelled.
Future<EventItem?> showEventEditor(
  BuildContext context, {
  EventItem? initial,
  DateTime? defaultDate,
  required bool telugu,
  Tradition tradition = Tradition.hindu,
}) {
  return showModalBottomSheet<EventItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _EventEditor(
      presets: presetsFor(tradition),
      initial: initial?.copy() ?? EventItem(presetId: presetsFor(tradition).first.id, date: defaultDate),
      telugu: telugu,
    ),
  );
}

class _EventEditor extends StatefulWidget {
  const _EventEditor({required this.initial, required this.telugu, required this.presets});
  final EventItem initial;
  final bool telugu;
  final List<EventPreset> presets;

  @override
  State<_EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<_EventEditor> {
  late final EventItem e = widget.initial;
  late final _customEn = TextEditingController(text: e.customEn);
  late final _customTe = TextEditingController(text: e.customTe);
  late final _venue = TextEditingController(text: e.venue);
  late final _venueTe = TextEditingController(text: e.venueTe);
  late final _map = TextEditingController(text: e.mapLink);
  bool _customTeEdited = false;
  bool _venueTeEdited = false;

  @override
  void dispose() {
    for (final c in [_customEn, _customTe, _venue, _venueTe, _map]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = e.date != null && (!e.isCustom || e.customEn.trim().isNotEmpty);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text('Function · కార్యక్రమం', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in widget.presets)
                ChoiceChip(
                  label: Text(p.id == 'custom' ? p.en : '${p.te} · ${p.en}'),
                  selected: e.presetId == p.id,
                  onSelected: (_) => setState(() => e.presetId = p.id),
                ),
            ],
          ),
          if (e.isCustom) ...[
            const SizedBox(height: 12),
            TextField(
              inputFormatters: const [TeluguBackspaceFormatter()],
              controller: _customEn,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Function name *'),
              onChanged: (v) => setState(() {
                e.customEn = v;
                if (!_customTeEdited) {
                  e.customTe = Transliterator.toTelugu(v);
                  _customTe.text = e.customTe;
                }
              }),
            ),
            if (widget.telugu) ...[
              const SizedBox(height: 10),
              TextField(
                inputFormatters: const [TeluguBackspaceFormatter()],
                controller: _customTe,
                decoration: const InputDecoration(labelText: 'తెలుగులో పేరు'),
                onChanged: (v) => setState(() {
                  e.customTe = v;
                  _customTeEdited = true;
                }),
              ),
            ],
          ],
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(e.date == null ? 'Pick date *' : InviteDates.enDate(e.date!)),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: e.date ?? now.add(const Duration(days: 30)),
                firstDate: DateTime(now.year, now.month, now.day),
                lastDate: now.add(const Duration(days: 365 * 3)),
              );
              if (picked != null) setState(() => e.date = picked);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(e.time == null ? 'Time (optional)' : InviteDates.enTime(e.time!)),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: e.time ?? const TimeOfDay(hour: 18, minute: 0),
              );
              if (picked != null) setState(() => e.time = picked);
            },
          ),
          TextField(
            inputFormatters: const [TeluguBackspaceFormatter()],
            controller: _venue,
            minLines: 1,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Venue (leave empty if same as main venue)',
            ),
            onChanged: (v) {
              e.venue = v;
              if (!_venueTeEdited) {
                e.venueTe = Transliterator.toTeluguPlace(v);
                _venueTe.text = e.venueTe;
              }
            },
          ),
          if (widget.telugu) ...[
            const SizedBox(height: 10),
            TextField(
              inputFormatters: const [TeluguBackspaceFormatter()],
              controller: _venueTe,
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'వేదిక తెలుగులో (auto-filled)'),
              onChanged: (v) {
                e.venueTe = v;
                _venueTeEdited = true;
              },
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            inputFormatters: const [TeluguBackspaceFormatter()],
            controller: _map,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'Google Maps link (optional)'),
            onChanged: (v) => e.mapLink = v,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: valid ? () => Navigator.of(context).pop(e) : null,
            child: const Text('Save function'),
          ),
        ],
      ),
    );
  }
}
