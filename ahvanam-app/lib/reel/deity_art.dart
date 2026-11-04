import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../config.dart';
import '../models/ceremony.dart';

/// Pictures of gods for the video opening, downloaded once from the online
/// design folder and kept on the phone. Null when there is none (offline or
/// not uploaded yet) — the video then shows a drawn symbol instead.
class DeityArt {
  DeityArt._();

  static final _asked = <Deity, Future<File?>>{};

  static Future<File?> fileFor(Deity d) {
    if (d == Deity.none) return Future.value(null);
    return _asked.putIfAbsent(d, () => _load(d));
  }

  static Future<File?> _load(Deity d) async {
    try {
      final support = await getApplicationSupportDirectory();
      final dir = Directory('${support.path}/deities');
      await dir.create(recursive: true);
      final file = File('${dir.path}/${d.name}.png');
      if (await file.exists() && await file.length() > 0) return file;
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      try {
        final res = await (await client.getUrl(Uri.parse('$deityAssetBase${d.name}.png'))).close();
        if (res.statusCode != 200) {
          await res.drain<void>();
          _asked.remove(d); // try again next time
          return null;
        }
        final bytes = await consolidateHttpClientResponseBytes(res);
        await file.writeAsBytes(bytes, flush: true);
        return file;
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('DeityArt: $e');
      _asked.remove(d);
      return null;
    }
  }
}
