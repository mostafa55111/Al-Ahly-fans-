import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// معالجة شعارات PNG ونسخها إلى `assets/images/`.
///
/// **الإعداد:** ضع في `tool/brand_sources/`:
/// - `ahly_source.png`
/// - `zamalek_source.png`
/// - `fan_source.png`
///
/// **التشغيل** من جذر المشروع:
/// `dart run tool/process_brand_logos.dart`
///
/// اختياري: مسار مجلد المصدر كوسيط، مثلاً:
/// `dart run tool/process_brand_logos.dart C:\path\to\pngs`
///
/// يُحدَّث `ahly_logo.png` و`fan_technology_logo.png` هنا، و`zamalek_logo.png` ونسخة
/// شعار FAN في المجلد الشقيق `../zamalekawy` إن وُجد.
void main(List<String> args) {
  final cwd = Directory.current.path;
  final incoming = args.isNotEmpty
      ? (p.isAbsolute(args[0]) ? args[0] : p.join(cwd, args[0]))
      : p.join(cwd, 'tool', 'brand_sources');

  final ahly = p.join(incoming, 'ahly_source.png');
  final zamalek = p.join(incoming, 'zamalek_source.png');
  final fan = p.join(incoming, 'fan_source.png');

  for (final f in [ahly, zamalek, fan]) {
    if (!File(f).existsSync()) {
      stderr.writeln(
        '❌ ملف مفقود: $f\n'
        '   أنشئ المجلد tool/brand_sources وضع: ahly_source.png, zamalek_source.png, fan_source.png',
      );
      exitCode = 1;
      return;
    }
  }

  _processAndCopy(ahly, [
    p.join(cwd, 'assets', 'images', 'ahly_logo.png'),
  ]);

  final siblingZam = p.join(cwd, '..', 'zamalekawy', 'assets', 'images', 'zamalek_logo.png');
  if (Directory(p.dirname(siblingZam)).existsSync()) {
    _processAndCopy(zamalek, [siblingZam]);
  } else {
    stderr.writeln('⚠ تُخطى zamalek_logo.png: لا يوجد ../zamalekawy/assets/images');
  }

  final fanOuts = <String>[p.join(cwd, 'assets', 'images', 'fan_technology_logo.png')];
  final siblingFan = p.join(cwd, '..', 'zamalekawy', 'assets', 'images', 'fan_technology_logo.png');
  if (Directory(p.dirname(siblingFan)).existsSync()) {
    fanOuts.add(siblingFan);
  }
  _processAndCopy(
    fan,
    fanOuts,
    stripDarkEdge: false,
  );
}

void _processAndCopy(
  String sourcePath,
  List<String> outputs, {
  bool stripDarkEdge = true,
}) {
  if (outputs.isEmpty) return;

  final file = File(sourcePath);
  if (!file.existsSync()) {
    stderr.writeln('❌ ملف المصدر غير موجود: $sourcePath');
    return;
  }

  final raw = file.readAsBytesSync();
  final decoded = img.decodeImage(raw);
  if (decoded == null) {
    stderr.writeln('❌ فشل فك ترميز الصورة: $sourcePath');
    return;
  }

  var mid = _trimWhiteFrame(decoded.convert(numChannels: 4));
  if (stripDarkEdge) {
    mid = _stripEdgeConnectedDark(mid);
  }
  final trimmed = _cropOpaqueBounds(mid);

  final pngBytes = img.encodePng(trimmed);
  for (final out in outputs) {
    File(out).writeAsBytesSync(pngBytes);
    stdout.writeln('✅ $out (${trimmed.width}x${trimmed.height})');
  }
}

img.Image _trimWhiteFrame(img.Image rgba) {
  final w = rgba.width;
  final h = rgba.height;

  bool nearWhiteFrame(int r, int g, int b) {
    final mx = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final mn = r < g ? (r < b ? r : b) : (g < b ? g : b);
    final chroma = mx - mn;
    final lum = 0.299 * r + 0.587 * g + 0.114 * b;
    if (lum >= 248 && chroma <= 18) return true;
    if (r > 232 && g > 232 && b > 232 && chroma <= 22) return true;
    return false;
  }

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final px = rgba.getPixel(x, y);
      final r = px.r.toInt();
      final g = px.g.toInt();
      final b = px.b.toInt();
      if (nearWhiteFrame(r, g, b)) {
        rgba.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }

  return rgba;
}

/// إزالة أسود/رمادي قاتم متصل بالحافة (مثل الإطار الخارجي للأيقونة على خلفية داكنة).
img.Image _stripEdgeConnectedDark(img.Image rgba) {
  final w = rgba.width;
  final h = rgba.height;
  if (w < 2 || h < 2) return rgba;

  bool isBg(int r, int g, int b, int a) {
    if (a < 12) return true;
    final mx = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final mn = r < g ? (r < b ? r : b) : (g < b ? g : b);
    final lum = 0.299 * r + 0.587 * g + 0.114 * b;
    return lum <= 34 && (mx - mn) <= 45;
  }

  final queued = List.generate(h, (_) => List<bool>.filled(w, false));
  final q = <(int, int)>[];

  void offer(int x, int y) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    if (queued[y][x]) return;
    final px = rgba.getPixel(x, y);
    final r = px.r.toInt(), g = px.g.toInt(), b = px.b.toInt();
    if (!isBg(r, g, b, px.a.toInt())) return;
    queued[y][x] = true;
    q.add((x, y));
  }

  for (var x = 0; x < w; x++) {
    offer(x, 0);
    offer(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    offer(0, y);
    offer(w - 1, y);
  }

  while (q.isNotEmpty) {
    final (cx, cy) = q.removeLast();
    rgba.setPixelRgba(cx, cy, 0, 0, 0, 0);
    for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final nx = cx + dx, ny = cy + dy;
      if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
      if (queued[ny][nx]) continue;
      final npx = rgba.getPixel(nx, ny);
      final r = npx.r.toInt(), g = npx.g.toInt(), b = npx.b.toInt();
      if (!isBg(r, g, b, npx.a.toInt())) continue;
      queued[ny][nx] = true;
      q.add((nx, ny));
    }
  }

  return rgba;
}

/// اقتصاص لحدود المحتوى غير الشفاف.
img.Image _cropOpaqueBounds(img.Image rgba) {
  var minX = rgba.width;
  var minY = rgba.height;
  var maxX = -1;
  var maxY = -1;
  for (var y = 0; y < rgba.height; y++) {
    for (var x = 0; x < rgba.width; x++) {
      if (rgba.getPixel(x, y).a.toInt() > 8) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (maxX < minX || maxY < minY) return rgba;
  return img.copyCrop(
    rgba,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
}
