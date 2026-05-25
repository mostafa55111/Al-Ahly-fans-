import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// تصدير QR كملف PNG (مشاركة أو حفظ في المعرض).
class QrPngExport {
  QrPngExport._();

  static Future<Uint8List> renderQrPngBytes(
    String data, {
    double size = 512,
  }) async {
    final validation = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
    final code = validation.qrCode;
    if (code == null) {
      throw Exception('تعذر إنشاء رمز QR');
    }
    final painter = QrPainter.withQr(
      qr: code,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
      gapless: true,
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(canvas, Size(size, size));
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bd = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bd == null) throw Exception('تعذر ترميز PNG');
    return bd.buffer.asUint8List();
  }

  /// حفظ في مجلد مؤقت ثم المعرض (إذن Gal).
  static Future<File> saveToTempFile(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$fileName');
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  static Future<void> saveToGallery(Uint8List bytes) async {
    var ok = await Gal.hasAccess();
    if (!ok) ok = await Gal.requestAccess();
    if (!ok) throw Exception('لم يُمنح إذن المعرض');
    final name = 'trip_qr_${DateTime.now().millisecondsSinceEpoch}.png';
    await Gal.putImageBytes(bytes, name: name);
  }
}
