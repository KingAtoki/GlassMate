import 'package:glassmate/ble_manager.dart';
import 'package:glassmate/controllers/evenai_model_controller.dart';
import 'package:glassmate/views/home_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  BleManager.get();
  Get.put(EvenaiModelController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlassMate',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.teal,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black, fontFamily: 'Poppins'),
          bodyMedium: TextStyle(color: Colors.black, fontFamily: 'Poppins'),
          headlineSmall: TextStyle(
              color: Colors.black, fontFamily: 'Poppins'), // AppBar title
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal.shade900,
          titleTextStyle: const TextStyle(
              color: Colors.white, fontFamily: 'Poppins', fontSize: 20),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
      home: const HomePage(),
    );
  }
}
