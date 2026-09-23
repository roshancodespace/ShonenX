import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

Future<List<Map<String, dynamic>>> extractMkvTracksJson(
  String url, {
  int chunkSize = 2 * 1024 * 1024,
}) async {
  Uint8List data;
  if (url.startsWith('http://') || url.startsWith('https://')) {
    // 1. Check EBML signature fast (4 bytes)
    final headResponse = await http.get(
      Uri.parse(url),
      headers: {'Range': 'bytes=0-3'},
    );
    if (headResponse.statusCode != 200 && headResponse.statusCode != 206) {
      throw Exception(
        'Failed to fetch file signature. Status: ${headResponse.statusCode}',
      );
    }
    final headData = headResponse.bodyBytes;
    if (headData.length < 4 ||
        headData[0] != 0x1A ||
        headData[1] != 0x45 ||
        headData[2] != 0xDF ||
        headData[3] != 0xA3) {
      return []; // Not an MKV file
    }

    // 2. Fetch full chunk
    final response = await http.get(
      Uri.parse(url),
      headers: {'Range': 'bytes=0-$chunkSize'},
    );

    if (response.statusCode != 200 && response.statusCode != 206) {
      throw Exception('Failed to fetch file. Status: ${response.statusCode}');
    }
    data = response.bodyBytes;
  } else {
    // Local file
    final file = File(url.replaceFirst('file://', ''));
    if (!await file.exists()) {
      throw Exception('Local file not found: $url');
    }
    final raf = await file.open(mode: FileMode.read);

    // 1. Check EBML signature
    final headData = await raf.read(4);
    if (headData.length < 4 ||
        headData[0] != 0x1A ||
        headData[1] != 0x45 ||
        headData[2] != 0xDF ||
        headData[3] != 0xA3) {
      await raf.close();
      return [];
    }
    await raf.setPosition(0);

    // 2. Read full chunk
    final length = await raf.length();
    final toRead = length > chunkSize ? chunkSize : length;
    data = await raf.read(toRead);
    await raf.close();
  }
  List<Map<String, dynamic>> tracks = [];
  int offset = 0;

  const int idSegment = 0x18538067;
  const int idTracks = 0x1654AE6B;
  const int idTrackEntry = 0xAE;
  const int idCluster = 0x1F43B675;

  // Helper using Dart Records (no models!)
  ({int value, int length}) readVInt(int offset, {bool dropMarker = true}) {
    if (offset >= data.length) return (value: -1, length: 0);

    int firstByte = data[offset];
    int mask = 0x80;
    int length = 1;

    while ((firstByte & mask) == 0 && length < 8) {
      mask >>= 1;
      length++;
    }

    if (length > 8 || length == 0) return (value: -1, length: 0);

    int value = dropMarker ? (firstByte & ~mask) : firstByte;
    for (int i = 1; i < length; i++) {
      if (offset + i >= data.length) return (value: -1, length: 0);
      value = (value << 8) | data[offset + i];
    }
    return (value: value, length: length);
  }

  int readInt(int offset, int size) {
    int value = 0;
    for (int i = 0; i < size; i++) {
      value = (value << 8) | data[offset + i];
    }
    return value;
  }

  String readString(int offset, int size) {
    var strData = data.sublist(offset, offset + size);
    while (strData.isNotEmpty && strData.last == 0) {
      strData = strData.sublist(0, strData.length - 1);
    }
    return utf8.decode(strData, allowMalformed: true);
  }

  while (offset < data.length) {
    var elementId = readVInt(offset, dropMarker: false);
    if (elementId.length == 0) break;
    offset += elementId.length;

    var elementSize = readVInt(offset, dropMarker: true);
    if (elementSize.length == 0) break;
    offset += elementSize.length;

    if (elementId.value == idCluster) break;

    if (elementId.value == idSegment || elementId.value == idTracks) {
      continue; // Step inside
    }

    if (elementId.value == idTrackEntry) {
      int trackEnd = offset + elementSize.value;

      // Building the plain map object
      Map<String, dynamic> track = {
        'language': 'eng',
        'name': '',
        'codecId': '',
      };

      int trackOffset = offset;
      while (trackOffset < trackEnd) {
        var propId = readVInt(trackOffset, dropMarker: false);
        trackOffset += propId.length;
        var propSize = readVInt(trackOffset, dropMarker: true);
        trackOffset += propSize.length;

        if (propId.value == 0xD7) {
          track['trackNumber'] = readInt(trackOffset, propSize.value);
        } else if (propId.value == 0x83) {
          int rawType = readInt(trackOffset, propSize.value);
          if (rawType == 2) track['type'] = 'Audio';
          if (rawType == 17) track['type'] = 'Subtitle';
        } else if (propId.value == 0x86) {
          track['codecId'] = readString(trackOffset, propSize.value);
        } else if (propId.value == 0x22B59C) {
          track['language'] = readString(trackOffset, propSize.value);
        } else if (propId.value == 0x536E) {
          track['name'] = readString(trackOffset, propSize.value);
        }

        trackOffset += propSize.value;
      }

      if (track['type'] == 'Audio' || track['type'] == 'Subtitle') {
        tracks.add(track);
      }

      offset = trackEnd;
      continue;
    }

    offset += elementSize.value;
  }

  return tracks;
}
