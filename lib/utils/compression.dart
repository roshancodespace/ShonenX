import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

Future<String?> compressUint8ListToBase64(Uint8List imageBytes, {int quality = 70}) async {
  // Compress the image in memory (Uint8List)
  final compressedBytes = await FlutterImageCompress.compressWithList(
    imageBytes,
    quality: quality, // Adjust quality (0-100)
    format: CompressFormat.jpeg, // Use JPEG for better compression
  );

  // Convert compressed bytes to Base64 string
  final base64String = base64Encode(compressedBytes);
  return base64String;
}
