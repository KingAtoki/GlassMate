import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'dart:typed_data';
import 'package:glassmate/ble_manager.dart';
import 'package:glassmate/controllers/bmp_update_manager.dart';
import 'package:glassmate/services/proto.dart';
import 'package:glassmate/utils/utils.dart';

class FeaturesServices {
  final bmpUpdateManager = BmpUpdateManager();
  Future<void> sendBmp(String imageUrl) async {
    Uint8List bmpData = await Utils.loadBmpImage(imageUrl);
    int initialSeq = 0;
    bool isSuccess = await Proto.sendHeartBeat();
    print(
        "${DateTime.now()} testBMP -------startSendBeatHeart----isSuccess---$isSuccess------");
    BleManager.get().startSendBeatHeart();

    final results = await Future.wait([
      bmpUpdateManager.updateBmp("L", bmpData, seq: initialSeq),
      bmpUpdateManager.updateBmp("R", bmpData, seq: initialSeq)
    ]);

    bool successL = results[0];
    bool successR = results[1];

    if (successL) {
      print("${DateTime.now()} left ble success");
    } else {
      print("${DateTime.now()} left ble fail");
    }

    if (successR) {
      print("${DateTime.now()} right ble success");
    } else {
      print("${DateTime.now()} right ble success");
    }
  }

  Future<void> exitBmp() async {
    bool isSuccess = await Proto.exit();
    print("exitBmp----isSuccess---$isSuccess--");
  }

  void createBmpImage(
  List<Map<String, dynamic>> textConfig,
  String outputPath, {
  int width = 576,
  int height = 136,
}) async {
  // Create a blank image with dynamic dimensions
  final image = Image(width: width, height: height);

  // Fill the background with white
  fill(image, color: ColorRgb8(255, 255, 255));

  try {
    for (var config in textConfig) {
      final text = config['text'] as String;
      final x = config['x'] as int;
      final y = config['y'] as int;
      final fontSize = config['fontSize'] as int;

      // Dynamically load the font based on font size
      final fontZipFile =
          await rootBundle.load('assets/fonts/Arial_$fontSize.ttf.zip');
      final fontData = fontZipFile.buffer.asUint8List();
      final font = BitmapFont.fromZip(fontData);

      // Draw the text using the configuration
      drawString(
        image,
        text,
        font: font,
        x: x,
        y: y,
        color: ColorRgb8(0, 0, 0), // Black text
      );
    }
  } catch (e) {
    print('Error rendering text: $e');
    return;
  }

  // Encode the image to BMP format
  final bmp = encodeBmp(image);

  // Save the BMP image to a file
  File(outputPath).writeAsBytesSync(bmp);
  print('BMP image created at $outputPath with dimensions $width x $height');
}

}
