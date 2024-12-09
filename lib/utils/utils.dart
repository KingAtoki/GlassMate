import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart'
    show BitmapFont, ColorRgb8, Image, drawString, fill;

class TextDrawCommand {
  final String text;
  final int x;
  final int y;
  final int fontSize;

  TextDrawCommand({
    required this.text,
    required this.x,
    required this.y,
    required this.fontSize,
  });
}

class Utils {
  Utils._();

  static int getTimestampMs() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  static Uint8List addPrefixToUint8List(List<int> prefix, Uint8List data) {
    var newData = Uint8List(data.length + prefix.length);
    for (var i = 0; i < prefix.length; i++) {
      newData[i] = prefix[i];
    }
    for (var i = prefix.length, j = 0;
        i < prefix.length + data.length;
        i++, j++) {
      newData[i] = data[j];
    }
    return newData;
  }

  /// Convert binary array to hexadecimal string
  static String bytesToHexStr(Uint8List data, [String join = '']) {
    List<String> hexList =
        data.map((byte) => byte.toRadixString(16).padLeft(2, '0')).toList();
    String hexResult = hexList.join(join);
    return hexResult;
  }

  static Future<Uint8List> loadBmpImage(String imageUrl) async {
    try {
      final ByteData data = await rootBundle.load(imageUrl);
      return data.buffer.asUint8List();
    } catch (e) {
      print("Error loading BMP file: $e");
      return Uint8List(0);
    }
  }
}

class BmpGenerator {
  static final Map<int, BitmapFont> _fontCache = {};

  /// Load a font of the given size
  static Future<BitmapFont> _loadFont(int fontSize) async {
    if (_fontCache.containsKey(fontSize)) {
      return _fontCache[fontSize]!;
    }

    try {
      final fontZipFile =
          await rootBundle.load('assets/fonts/Arial_$fontSize.ttf.zip');
      final fontData = fontZipFile.buffer.asUint8List();
      final font = BitmapFont.fromZip(fontData);
      _fontCache[fontSize] = font;
      return font;
    } catch (e) {
      throw Exception("Error loading font of size $fontSize: $e");
    }
  }

  /// Create a monochrome BMP with text
  static Future<Uint8List> createBitmap({
    required int width,
    required int height,
    required List<TextDrawCommand> textCommands,
  }) async {
    final bytesPerLine = ((width + 31) ~/ 32) * 4;
    final imageSize = bytesPerLine * height;
    final fileSize = 62 + imageSize;

    final buffer = ByteData(fileSize);

    // BMP Header (14 bytes)
    _writeBmpHeader(buffer, fileSize);

    // DIB Header (40 bytes)
    _writeDibHeader(buffer, width, height, imageSize);

    // Color table (8 bytes)
    _writeColorTable(buffer);

    // Initialize the BMP to white
    _initializeImage(buffer, fileSize);

    // Draw text
    for (var command in textCommands) {
      final font = await _loadFont(command.fontSize);
      await _drawText(buffer, command, font, width, bytesPerLine, height);
    }

    return buffer.buffer.asUint8List();
  }

  /// Write the BMP header
  static void _writeBmpHeader(ByteData buffer, int fileSize) {
    buffer.setUint16(0, 0x4D42, Endian.little); // 'BM'
    buffer.setUint32(2, fileSize, Endian.little); // File size
    buffer.setUint16(6, 0, Endian.little); // Reserved
    buffer.setUint16(8, 0, Endian.little); // Reserved
    buffer.setUint32(10, 62, Endian.little); // Offset to pixel data
  }

  /// Write the DIB header
  static void _writeDibHeader(
      ByteData buffer, int width, int height, int imageSize) {
    buffer.setUint32(14, 40, Endian.little); // DIB header size
    buffer.setUint32(18, width, Endian.little); // Width
    buffer.setUint32(22, height, Endian.little); // Height
    buffer.setUint16(26, 1, Endian.little); // Color planes
    buffer.setUint16(28, 1, Endian.little); // Bits per pixel
    buffer.setUint32(30, 0, Endian.little); // No compression
    buffer.setUint32(34, imageSize, Endian.little); // Image size
    buffer.setUint32(38, 2835, Endian.little); // X pixels/meter
    buffer.setUint32(42, 2835, Endian.little); // Y pixels/meter
    buffer.setUint32(46, 2, Endian.little); // Number of colors
    buffer.setUint32(50, 0, Endian.little); // Important colors
  }

  /// Write the color table
  static void _writeColorTable(ByteData buffer) {
    buffer.setUint32(54, 0x00000000, Endian.little); // Black
    buffer.setUint32(58, 0x00FFFFFF, Endian.little); // White
  }

  /// Initialize BMP data to white
  static void _initializeImage(ByteData buffer, int fileSize) {
    for (var i = 62; i < fileSize; i++) {
      buffer.setUint8(i, 0xFF); // Set all pixels to white
    }
  }

  /// Draw text onto the BMP buffer
  static Future<void> _drawText(
    ByteData buffer,
    TextDrawCommand command,
    BitmapFont font,
    int width,
    int bytesPerLine,
    int height,
  ) async {
    final tempImage = Image(width: width, height: height);
    fill(tempImage, color: ColorRgb8(255, 255, 255));

    drawString(
      tempImage,
      font: font,
      x: command.x,
      y: command.y,
      command.text,
      color: ColorRgb8(0, 0, 0),
    );

    // Convert to monochrome and copy to BMP buffer
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = tempImage.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        
        // Check if pixel is black (or close to black)
        final isBlack = (r + g + b) / 3 < 128;

        if (isBlack) {
          final byteOffset = 62 + ((height - 1 - y) * bytesPerLine) + (x >> 3);
          final bitOffset = 7 - (x & 7);
          final currentByte = buffer.getUint8(byteOffset);
          buffer.setUint8(byteOffset, currentByte & ~(1 << bitOffset));
        }
      }
    }
  }
}
