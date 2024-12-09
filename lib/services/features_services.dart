import 'dart:io';

import 'package:flutter/services.dart';
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

  Future<void> createBmpImage(
    List<Map<String, dynamic>> textConfig,
    String outputPath,
  ) async {
    final commands = textConfig
        .map((config) => TextDrawCommand(
              text: config['text'] as String,
              x: config['x'] as int,
              y: config['y'] as int,
              fontSize: config['fontSize'] as int,
            ))
        .toList();

    final bmpData = await BmpGenerator.createBitmap(
      width: 576,
      height: 135,
      textCommands: commands,
    );

    File(outputPath).writeAsBytesSync(bmpData);
    print('BMP file created at $outputPath');
  }
}
