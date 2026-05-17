import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/app_config.dart';

/// ============================================================
///  خدمة ImageKit الموحدة
///  جميع عمليات رفع وحذف الصور تمر عبر هذه الخدمة فقط.
/// ============================================================
class ImageKitService {
  ImageKitService._();

  static final _uploadUrl =
      Uri.parse('https://upload.imagekit.io/api/v1/files/upload');

  static String get _basicAuth =>
      'Basic ' +
      base64Encode(utf8.encode('${AppConfig.imagekitPrivateKey}:'));

  /// رفع صورة إلى ImageKit.
  /// يعيد Map يحتوي على 'url' و 'fileId'، أو null عند الفشل.
  static Future<Map<String, String>?> uploadImage(XFile image) async {
    try {
      final request = http.MultipartRequest('POST', _uploadUrl);
      request.headers['Authorization'] = _basicAuth;
      request.fields['publicKey'] = AppConfig.imagekitPublicKey;
      request.fields['fileName'] = image.name;

      final bytes = await image.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: image.name),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        debugPrint('ImageKit Upload OK — fileId: ${json['fileId']}');
        return {
          'url': json['url'] as String,
          'fileId': json['fileId'] as String,
        };
      } else {
        debugPrint('ImageKit Upload Error [${response.statusCode}]: $body');
        return null;
      }
    } catch (e) {
      debugPrint('ImageKit Upload Exception: $e');
      return null;
    }
  }

  /// حذف صورة من ImageKit بواسطة fileId.
  /// يعيد true عند النجاح، false عند الفشل.
  static Future<bool> deleteImage(String fileId) async {
    try {
      final url = Uri.parse('https://api.imagekit.io/v1/files/$fileId');
      final response = await http.delete(
        url,
        headers: {'Authorization': _basicAuth},
      );

      if (response.statusCode == 204) {
        debugPrint('ImageKit Delete OK — fileId: $fileId');
        return true;
      } else {
        debugPrint(
            'ImageKit Delete Error [${response.statusCode}]: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('ImageKit Delete Exception: $e');
      return false;
    }
  }
}
