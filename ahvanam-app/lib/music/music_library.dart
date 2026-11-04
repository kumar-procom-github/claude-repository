import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../config.dart';

/// One background-music track for video invitations.
class MusicTrack {
  const MusicTrack({
    required this.id,
    required this.title,
    required this.titleTe,
    required this.mood,
    required this.file,
    this.seconds = 0,
    this.bundled = false,
    this.credit = 'Ahvanam Originals',
  });

  final String id;
  final String title;
  final String titleTe;

  /// wedding · festive · devotional · soft · celebration · christian · eid
  final String mood;

  /// Asset path (bundled) or path inside the online library folder.
  final String file;
  final int seconds;
  final bool bundled;
  final String credit;

  static MusicTrack? tryParse(Object? o) {
    if (o is! Map) return null;
    final id = o['id'], file = o['file'];
    if (id is! String || file is! String) return null;
    return MusicTrack(
      id: id,
      title: (o['title'] as String?) ?? id,
      titleTe: (o['titleTe'] as String?) ?? '',
      mood: (o['mood'] as String?) ?? 'celebration',
      file: file,
      seconds: (o['seconds'] as num?)?.toInt() ?? 0,
      credit: (o['credit'] as String?) ?? 'Ahvanam Originals',
    );
  }
}

/// Music for videos from two sources: a couple of tracks bundled in the app
/// (work offline) and an online library on GitHub, downloaded only when the
/// user picks a track. dart:io only — no packages, no API keys.
class MusicLibrary extends ChangeNotifier {
  MusicLibrary._();
  static final instance = MusicLibrary._();

  static const bundledTracks = [
    MusicTrack(
      id: 'mangalam',
      title: 'Mangalam',
      titleTe: 'మంగళం',
      mood: 'wedding',
      file: 'assets/music/mangalam.m4a',
      seconds: 40,
      bundled: true,
    ),
    MusicTrack(
      id: 'utsavam',
      title: 'Utsavam',
      titleTe: 'ఉత్సవం',
      mood: 'celebration',
      file: 'assets/music/utsavam.m4a',
      seconds: 40,
      bundled: true,
    ),
  ];

  List<MusicTrack> online = const [];
  bool loading = false;
  String? error;
  final downloading = <String, double>{}; // id → 0..1
  Directory? _dir;

  List<MusicTrack> get all => [
        ...bundledTracks,
        for (final t in online)
          if (!bundledTracks.any((b) => b.id == t.id)) t,
      ];

  Future<Directory> _folder() async {
    if (_dir != null) return _dir!;
    final support = await getApplicationSupportDirectory();
    _dir = Directory('${support.path}/music');
    await _dir!.create(recursive: true);
    return _dir!;
  }

  /// Cached list first, then the online one.
  Future<void> load() async {
    if (loading) return;
    final dir = await _folder();
    final cache = File('${dir.path}/catalog.json');
    try {
      if (online.isEmpty && await cache.exists()) online = _parse(await cache.readAsString());
    } catch (_) {}
    loading = true;
    error = null;
    notifyListeners();
    try {
      final body = utf8.decode(await _get(Uri.parse(musicCatalogUrl)));
      online = _parse(body);
      await cache.writeAsString(body);
    } catch (e) {
      error = online.isEmpty ? 'Online music needs internet. Built-in tracks still work.' : null;
      debugPrint('Music catalog: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<MusicTrack> _parse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return [
      for (final o in (json['tracks'] as List? ?? const []))
        if (MusicTrack.tryParse(o) case final t?) t,
    ];
  }

  Future<File> _target(MusicTrack t) async {
    final dir = await _folder();
    final ext = t.file.contains('.') ? t.file.substring(t.file.lastIndexOf('.')) : '.m4a';
    return File('${dir.path}/${t.bundled ? 'b_' : ''}${t.id}$ext');
  }

  /// Already on the phone (bundled tracks always are).
  Future<bool> isReady(MusicTrack t) async => t.bundled || (await (await _target(t)).exists());

  /// Local file for [t]: copies bundled assets out, downloads online tracks.
  Future<File> fileFor(MusicTrack t) async {
    final file = await _target(t);
    if (await file.exists() && await file.length() > 0) return file;
    if (t.bundled) {
      final data = await rootBundle.load(t.file);
      await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
      return file;
    }
    downloading[t.id] = 0;
    notifyListeners();
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
      try {
        final res = await (await client.getUrl(Uri.parse(musicAssetBase).resolve(t.file))).close();
        if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
        final total = res.contentLength;
        final tmp = File('${file.path}.part');
        final sink = tmp.openWrite();
        var got = 0;
        await for (final chunk in res) {
          sink.add(chunk);
          got += chunk.length;
          if (total > 0) {
            downloading[t.id] = got / total;
            notifyListeners();
          }
        }
        await sink.close();
        await tmp.rename(file.path);
      } finally {
        client.close();
      }
      return file;
    } finally {
      downloading.remove(t.id);
      notifyListeners();
    }
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
