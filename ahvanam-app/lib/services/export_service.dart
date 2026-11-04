import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Captures rendered cards and exports them:
///  * PNG 1080 × 1920 for WhatsApp / Status (share sheet)
///  * Save to the phone gallery (album "Ahvanam")
///  * Print-ready PDF, one card per 4.5 × 8 inch page at ~320 dpi
/// No video/FFmpeg here — video export comes later via the platform encoder.
class ExportService {
  ExportService._();

  /// 360 × 640 design size × 3 = 1080 × 1920 PNG.
  static const sharePixelRatio = 3.0;

  /// × 4 = 1440 × 2560 → ~320 dpi on a 4.5 × 8 inch print.
  static const printPixelRatio = 4.0;

  static Future<Uint8List> captureBytes(GlobalKey boundaryKey, {double pixelRatio = sharePixelRatio}) async {
    final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  static Future<File> _writeTemp(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<List<File>> capturePngs(List<GlobalKey> keys, String baseName) async {
    return [
      for (var i = 0; i < keys.length; i++)
        await _writeTemp(await captureBytes(keys[i]), '${baseName}_${i + 1}.png'),
    ];
  }

  static Future<void> sharePngs(List<File> files, String caption) async {
    await SharePlus.instance.share(ShareParams(
      files: [for (final f in files) XFile(f.path, mimeType: 'image/png')],
      text: caption,
    ));
  }

  /// Returns false if the user denied photo access.
  static Future<bool> saveToGallery(List<File> files) async {
    if (!await Gal.hasAccess(toAlbum: true)) {
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) return false;
    }
    for (final f in files) {
      await Gal.putImage(f.path, album: 'Ahvanam');
    }
    return true;
  }

  static Future<File> buildPdf(List<GlobalKey> keys, String baseName) async {
    // 9:16 page: 4.5 × 8 inches.
    const format = PdfPageFormat(4.5 * PdfPageFormat.inch, 8 * PdfPageFormat.inch);
    final doc = pw.Document(title: baseName, author: 'Ahvanam');
    for (final key in keys) {
      final bytes = await captureBytes(key, pixelRatio: printPixelRatio);
      final image = pw.MemoryImage(bytes);
      doc.addPage(pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(image, fit: pw.BoxFit.cover),
      ));
    }
    return _writeTemp(await doc.save(), '$baseName.pdf');
  }

  static Future<void> sharePdf(File pdf, String caption) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile(pdf.path, mimeType: 'application/pdf')],
      text: caption,
    ));
  }
}
