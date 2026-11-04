import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A photo, video or song the user picked (copied into the app's folder).
class PickedMedia {
  const PickedMedia({
    required this.path,
    required this.name,
    required this.type,
    this.durationMs = 0,
    this.width = 0,
    this.height = 0,
  });

  final String path;
  final String name;

  /// 'photo', 'video' or 'audio'.
  final String type;
  final int durationMs;
  final int width;
  final int height;

  bool get isVideo => type == 'video';

  static PickedMedia? fromMap(Object? o) {
    if (o is! Map) return null;
    final path = o['path'];
    if (path is! String) return null;
    return PickedMedia(
      path: path,
      name: (o['name'] as String?) ?? 'file',
      type: (o['type'] as String?) ?? 'photo',
      durationMs: (o['durationMs'] as num?)?.toInt() ?? 0,
      width: (o['width'] as num?)?.toInt() ?? 0,
      height: (o['height'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A video clip playing into a Flutter [Texture] (editor preview).
class ClipPlayer {
  ClipPlayer._(this.textureId, this.width, this.height, this.rotation, this.durationMs);

  final int textureId;

  /// Size of the video's frames as stored (before [rotation]).
  final int width;
  final int height;

  /// Degrees the picture must still be turned on screen (0 if the texture
  /// already shows it upright).
  final int rotation;
  final int durationMs;
  bool playing = false;
  bool disposed = false;

  static const _ch = MethodChannel('ahvanam/player');

  static Future<ClipPlayer> create(String path) async {
    final r = (await _ch.invokeMapMethod<String, dynamic>('create', {'path': path}))!;
    return ClipPlayer._(
      (r['id'] as num).toInt(),
      (r['width'] as num).toInt(),
      (r['height'] as num).toInt(),
      (r['rotation'] as num?)?.toInt() ?? 0,
      (r['durationMs'] as num).toInt(),
    );
  }

  Map<String, Object> get _id => {'id': textureId};

  Future<void> play({double speed = 1}) async {
    if (disposed) return;
    playing = true;
    await _ch.invokeMethod('speed', {..._id, 'speed': speed});
    await _ch.invokeMethod('play', _id);
  }

  Future<void> pause() async {
    if (disposed || !playing) return;
    playing = false;
    await _ch.invokeMethod('pause', _id);
  }

  Future<void> seek(int ms) async {
    if (disposed) return;
    await _ch.invokeMethod('seek', {..._id, 'ms': ms});
  }

  Future<int> position() async {
    if (disposed) return 0;
    return await _ch.invokeMethod<int>('position', _id) ?? 0;
  }

  Future<void> dispose() async {
    if (disposed) return;
    disposed = true;
    await _ch.invokeMethod('dispose', _id);
  }

  static Future<void> disposeAll() => _ch.invokeMethod('disposeAll');
}

/// One exact frame of a video as RGBA pixels.
class VideoFrameData {
  const VideoFrameData(this.width, this.height, this.rgba);
  final int width;
  final int height;
  final Uint8List rgba;
}

/// Thin Dart side of the Android code in MainActivity.kt, VideoEncoder.kt
/// and ReelMedia.kt. Uses Android's built-in encoders and system pickers:
/// no extra packages, no paid APIs and no storage permission.
class NativeMedia {
  NativeMedia._();

  static const _video = MethodChannel('ahvanam/video');
  static const _media = MethodChannel('ahvanam/media');
  static const _frames = MethodChannel('ahvanam/frames');

  /// Video export is implemented for Android.
  static bool get videoSupported => !kIsWeb && Platform.isAndroid;

  // ---- video encoder ----------------------------------------------------------

  static Future<void> startVideo({
    required String path,
    required int width,
    required int height,
    int fps = 24,
    int bitRate = 5000000,
  }) =>
      _video.invokeMethod('start', {
        'path': path,
        'width': width,
        'height': height,
        'fps': fps,
        'bitRate': bitRate,
      });

  /// One frame as raw RGBA bytes (width × height × 4).
  static Future<void> addFrame(Uint8List rgba) => _video.invokeMethod('frame', {'rgba': rgba});

  /// Writes the MP4 (with the song, if any) and returns its path.
  static Future<String> finishVideo({
    String? audioPath,
    int audioStartMs = 0,
    double volume = 1,
    int fadeOutMs = 2000,
  }) async {
    final path = await _video.invokeMethod<String>('finish', {
      'audioPath': audioPath,
      'audioStartMs': audioStartMs,
      'volume': volume,
      'fadeOutMs': fadeOutMs,
    });
    return path!;
  }

  static Future<void> cancelVideo() => _video.invokeMethod('cancel');

  // ---- pickers ------------------------------------------------------------------

  /// A song from the phone (system file picker). Returns its local copy.
  static Future<PickedMedia?> pickAudio() async =>
      PickedMedia.fromMap(await _media.invokeMethod<Object?>('pickAudio'));

  /// Photos and videos from the phone (system photo picker, several at once).
  static Future<List<PickedMedia>> pickMedia() async {
    final r = await _media.invokeMethod<List<Object?>>('pickMedia');
    return [
      for (final o in r ?? const <Object?>[])
        if (PickedMedia.fromMap(o) case final m?) m,
    ];
  }

  // ---- music preview ------------------------------------------------------------

  /// Plays [path] (looping) from [startMs]; returns the song length in ms.
  static Future<int> play(String path, {int startMs = 0, double volume = 1}) async =>
      await _media.invokeMethod<int>('play', {'path': path, 'startMs': startMs, 'volume': volume}) ?? 0;

  static Future<void> setVolume(double volume) => _media.invokeMethod('volume', {'volume': volume});

  static Future<void> stop() => _media.invokeMethod('stop');

  /// Song length in ms (0 if unknown).
  static Future<int> durationMs(String path) async =>
      await _media.invokeMethod<int>('duration', {'path': path}) ?? 0;

  // ---- video frames -------------------------------------------------------------

  /// The frame of [path] at [ms], at most [maxSide] pixels on its long side.
  static Future<VideoFrameData> frameAt(String path, int ms, {int maxSide = 1280}) async {
    final r = (await _frames.invokeMapMethod<String, dynamic>('frameAt', {
      'path': path,
      'ms': ms,
      'maxSide': maxSide,
    }))!;
    return VideoFrameData(
      (r['width'] as num).toInt(),
      (r['height'] as num).toInt(),
      r['rgba'] as Uint8List,
    );
  }

  /// Where the face is in a photo: centre (x, y) and face width, all as
  /// fractions of the photo. Null when no face is found.
  static Future<({double x, double y, double size})?> findFace(String path) async {
    try {
      final r = await _frames.invokeMapMethod<String, dynamic>('face', {'path': path});
      if (r == null) return null;
      return (
        x: (r['x'] as num).toDouble(),
        y: (r['y'] as num).toDouble(),
        size: (r['size'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> closeFrames() => _frames.invokeMethod('close');
}
