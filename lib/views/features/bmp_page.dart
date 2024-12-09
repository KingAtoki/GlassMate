// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:glassmate/ble_manager.dart';
import 'package:glassmate/services/features_services.dart';

class BmpPage extends StatefulWidget {
  const BmpPage({super.key});

  @override
  _BmpState createState() => _BmpState();
}

class _BmpState extends State<BmpPage> {
  String? generatedBmpPath;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('BMP'),
        ),
        body: Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 44),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  if (BleManager.get().isConnected == false) return;
                  print("${DateTime.now()} to show bmp1-----------");
                  FeaturesServices().sendBmp("assets/images/image_1.bmp");
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: const Text("BMP 1", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  if (BleManager.get().isConnected == false) return;
                  print("${DateTime.now()} to show bmp2-----------");
                  FeaturesServices().sendBmp("assets/images/image_2.bmp");
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: const Text("BMP 2", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  if (BleManager.get().isConnected == false) return;
                  FeaturesServices().exitBmp(); // todo
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: const Text("Exit", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  // Define the path for the generated BMP image
                  final outputPath =
                      '${Directory.systemTemp.path}/test_image.bmp';

                  // Call the createBmpImage method
                  FeaturesServices().createBmpImage(
                    [
                      {
                        'text': 'Wed, May 8',
                        'x': 10,
                        'y': 20,
                        'fontSize': 24,
                      },
                      {
                        'text': '12:47',
                        'x': 10,
                        'y': 50,
                        'fontSize': 32,
                      },
                      {
                        'text': 'Task Reminder',
                        'x': 200,
                        'y': 20,
                        'fontSize': 12,
                      },
                      {
                        'text': '1. Develop and test new feature.',
                        'x': 200,
                        'y': 40,
                        'fontSize': 12,
                      },
                      {
                        'text': '2. Fix reported bugs.',
                        'x': 200,
                        'y': 60,
                        'fontSize': 12,
                      },
                    ],
                    outputPath,
                  );

                  FeaturesServices().sendBmp(outputPath);
                  // Update state to display the image
                  setState(() {
                    generatedBmpPath = outputPath;
                  });
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: const Text("Generate BMP",
                      style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              if (generatedBmpPath != null)
                Column(
                  children: [
                    const Text('Generated BMP Image:',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Image.file(File(generatedBmpPath!)),
                  ],
                ),
            ],
          ),
        ),
      );
}
