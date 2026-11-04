import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../config.dart';
import '../templates/remote_template.dart';

/// Illustrated designs from two sources, merged:
///  * **bundled** — a starter set shipped inside the app (assets/templates/),
///    so the Illustrated tab works on first launch, even offline;
///  * **online** — the catalog at [templateCatalogUrl], fetched on launch and
///    on "Refresh", so new designs appear without an app update.
/// Everything is cached on the phone. dart:io only — no extra packages, no API keys.
class TemplateCatalog extends ChangeNotifier {
  TemplateCatalog._();
  static final instance = TemplateCatalog._();

  static const _bundleRoot = 'assets/templates/';

  List<RemoteTemplate> templates = const [];
  DateTime? lastUpdated;
  bool refreshing = false;
  String? error;

  List<RemoteTemplate> _bundled = const [];
  List<RemoteTemplate> _online = const [];
  Directory? _dir;
  Set<String> _seen = {};
  final _inFlight = <String, Future<File>>{};

  Uri get _catalogUri => Uri.parse(templateCatalogUrl);

  /// False until lib/config.dart points at your real catalog.
  bool get isConnected => templateCatalogUrl.isNotEmpty && !templateCatalogUrl.contains('YOUR_GITHUB_USER');

  /// Load bundled + cached designs, then check online in the background.
  Future<void> init() async {
    final support = await getApplicationSupportDirectory();
    _dir = Directory('${support.path}/templates');
    await _dir!.create(recursive: true);
    try {
      _bundled = _parse(await rootBundle.loadString('${_bundleRoot}catalog.json')).$1;
    } catch (e) {
      debugPrint('No bundled templates: $e');
    }
    try {
      final cached = File('${_dir!.path}/catalog.json');
      if (await cached.exists()) {
        final (list, updated) = _parse(await cached.readAsString());
        _online = list;
        lastUpdated = updated;
      }
      final seen = File('${_dir!.path}/seen.json');
      if (await seen.exists()) _seen = {...(jsonDecode(await seen.readAsString()) as List).cast<String>()};
    } catch (_) {/* corrupt cache: ignore, refresh will fix it */}
    _merge();
    notifyListeners();
    unawaited(refresh());
  }

  Future<void> refresh() async {
    if (refreshing || _dir == null) return;
    if (!isConnected) {
      // Developer reminder only; users of a release build never see this.
      error = kDebugMode
          ? 'Dev note: online designs not connected yet. Set the catalog link in lib/config.dart.'
          : null;
      notifyListeners();
      return;
    }
    refreshing = true;
    error = null;
    notifyListeners();
    try {
      final body = utf8.decode(await _get(_catalogUri));
      final (list, updated) = _parse(body); // throws on invalid JSON before we overwrite the cache
      _online = list;
      lastUpdated = updated;
      await File('${_dir!.path}/catalog.json').writeAsString(body);
      _merge();
    } catch (e) {
      error = 'Could not check for new designs. Check internet and tap refresh.';
      debugPrint('Template catalog refresh failed: $e');
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  (List<RemoteTemplate>, DateTime?) _parse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final list = (json['templates'] as List? ?? const [])
        .map(RemoteTemplate.tryParse)
        .whereType<RemoteTemplate>()
        .toList();
    return (list, DateTime.tryParse(json['updated'] as String? ?? ''));
  }

  /// Online entries win over bundled ones with the same id (lets you update
  /// a starter design without an app release). Newest first.
  void _merge() {
    final onlineIds = {for (final t in _online) t.id};
    final list = [..._online, for (final t in _bundled) if (!onlineIds.contains(t.id)) t];
    list.sort((a, b) => (b.added ?? DateTime(2000)).compareTo(a.added ?? DateTime(2000)));
    templates = list;
  }

  bool _isBundled(RemoteTemplate t) =>
      !_online.any((o) => o.id == t.id) && _bundled.any((b) => b.id == t.id);

  List<RemoteTemplate> forCeremony(String ceremonyId) => [for (final t in templates) if (t.fits(ceremonyId)) t];

  bool isNew(RemoteTemplate t) => !_seen.contains(t.id);

  Future<void> markSeen(Iterable<RemoteTemplate> list) async {
    final before = _seen.length;
    _seen.addAll(list.map((t) => t.id));
    if (_seen.length == before || _dir == null) return;
    await File('${_dir!.path}/seen.json').writeAsString(jsonEncode(_seen.toList()));
  }

  Future<File> thumb(RemoteTemplate t) => _cached(t, t.thumb, '${t.id}_v${t.version}_thumb');
  Future<File> art(RemoteTemplate t) => _cached(t, t.art, '${t.id}_v${t.version}_art');

  Future<File> _cached(RemoteTemplate t, String path, String name) {
    final ext = path.contains('.') ? path.substring(path.lastIndexOf('.')) : '';
    final bundled = _isBundled(t);
    final file = File('${_dir!.path}/${bundled ? 'b_' : ''}$name$ext');
    return _inFlight.putIfAbsent(file.path, () async {
      try {
        if (await file.exists() && await file.length() > 0) return file;
        final Uint8List bytes;
        if (bundled) {
          final data = await rootBundle.load('$_bundleRoot$path');
          bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        } else {
          bytes = await _get(Uri.parse(templateAssetBase).resolve(path)); // CDN copy of the repo folder
        }
        await file.writeAsBytes(bytes, flush: true);
        return file;
      } finally {
        unawaited(Future(() => _inFlight.remove(file.path)));
      }
    });
  }

  static Future<Uint8List> _get(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final res = await (await client.getUrl(uri)).close();
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}', uri: uri);
      return await consolidateHttpClientResponseBytes(res);
    } finally {
      client.close();
    }
  }
}
