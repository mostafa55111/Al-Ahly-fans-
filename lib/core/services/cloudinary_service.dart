import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class CloudinaryService {
  final String cloudName = 'dubc6k1iy';
  final String uploadPreset = 'ahly_fans_preset';
  final String apiKey = 'YOUR_API_KEY'; // Replace with your actual API key
  final String apiSecret = 'YOUR_API_SECRET'; // Replace with your actual API secret

  Future<String> uploadVideo(File file) async {
    try {
      // Test internet connection first
      try {
        await InternetAddress.lookup('google.com');
        debugPrint("Internet OK");
      } catch (e) {
        debugPrint("No Internet: $e");
        throw Exception("No internet connection: $e");
      }

      // Credentials Check
      debugPrint("Cloudinary Config - cloud_name: $cloudName, upload_preset: $uploadPreset");

      // Try upload preset first
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/video/upload",
      );

      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint("UPLOAD ERROR: Connection timed out after 30 seconds.");
          throw Exception("Cloudinary connection timed out.");
        },
      );
      final res = await http.Response.fromStream(response);

      debugPrint("Upload response: ${res.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['secure_url'];
      } else {
        debugPrint("Upload preset failed, trying signed upload...");
        return await _uploadVideoSigned(file);
      }
    } catch (e) {
      debugPrint("Upload preset failed: $e, trying signed upload...");
      return await _uploadVideoSigned(file);
    }
  }

  /// رفع صورة/GIF للـ Cloudinary — يرجع `secure_url`.
  /// ═══════════════════════════════════════════════════════════════
  /// يُستخدم في مرفقات التعليقات (image/gif).
  /// - `resourceType` يحدّد نوع المورد (image أو video).
  Future<String> uploadImage(File file, {String resourceType = 'image'}) async {
    try {
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload",
      );
      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception("Cloudinary image upload timed out.");
        },
      );
      final res = await http.Response.fromStream(response);
      debugPrint("Image upload response: ${res.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['secure_url'] ?? '';
      }
      throw Exception("Image upload failed: ${res.statusCode}");
    } catch (e) {
      debugPrint("Image upload error: $e");
      rethrow;
    }
  }

  Future<String> _uploadVideoSigned(File file) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final signature = _generateSignature(timestamp);

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/video/upload",
    );

    final request = http.MultipartRequest("POST", url)
      ..fields['api_key'] = apiKey
      ..fields['timestamp'] = timestamp
      ..fields['signature'] = signature
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final res = await http.Response.fromStream(response);

    debugPrint("Signed upload response: ${res.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['secure_url'];
    } else {
      throw Exception("Upload failed");
    }
  }

  String _generateSignature(String timestamp) {
    final stringToSign = 'timestamp=$timestamp';
    final bytes = utf8.encode(stringToSign);
    final keyBytes = utf8.encode(apiSecret);
    final hmacSha1 = Hmac(sha256, keyBytes);
    final digest = hmacSha1.convert(bytes);
    return digest.toString();
  }
}
