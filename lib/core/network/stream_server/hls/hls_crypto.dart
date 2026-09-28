import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

class HlsCrypto {
  static IV parseIv(String ivStr) {
    if (ivStr.startsWith('0x') || ivStr.startsWith('0X')) {
      final hex = ivStr.substring(2);
      final paddedHex = hex.padLeft(32, '0'); // 16 bytes = 32 hex chars
      final bytes = <int>[];
      for (int i = 0; i < paddedHex.length; i += 2) {
        bytes.add(int.parse(paddedHex.substring(i, i + 2), radix: 16));
      }
      return IV(Uint8List.fromList(bytes));
    } else {
      // It's the media sequence number
      final seq = int.parse(ivStr);
      final bytes = ByteData(16);
      // Media sequence is a 64-bit integer at the end of the 128-bit IV
      bytes.setUint64(8, seq, Endian.big);
      return IV(bytes.buffer.asUint8List());
    }
  }

  static List<int> decrypt(
    List<int> encryptedBytes,
    List<int> keyBytes,
    IV iv,
  ) {
    final key = Key(Uint8List.fromList(keyBytes));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));

    final decrypted = encrypter.decryptBytes(
      Encrypted(Uint8List.fromList(encryptedBytes)),
      iv: iv,
    );
    return decrypted;
  }
}
