// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:glassmate/ble_manager.dart';
import 'package:glassmate/services/evenai.dart';
import 'package:glassmate/views/even_list_page.dart';
import 'package:glassmate/views/features_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? scanTimer;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    BleManager.get().setMethodCallHandler();
    BleManager.get().startListening();
    BleManager.get().onStatusChanged = _refreshPage;
  }

  void _refreshPage() => setState(() {});

  Future<void> _startScan() async {
    setState(() => isScanning = true);
    await BleManager.get().startScan();
    scanTimer?.cancel();
    scanTimer = Timer(15.seconds, () {
      // todo
      _stopScan();
    });
  }

  Future<void> _stopScan() async {
    if (isScanning) {
      await BleManager.get().stopScan();
      setState(() => isScanning = false);
    }
  }

  Widget blePairedList() => Expanded(
        child: ListView.separated(
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemCount: BleManager.get().getPairedGlasses().length,
          itemBuilder: (context, index) {
            final glasses = BleManager.get().getPairedGlasses()[index];
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: Icon(Icons.bluetooth, color: Colors.teal),
                title: Text(
                  'Pair: ${glasses['channelNumber']}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Left: ${glasses['leftDeviceName']} \nRight: ${glasses['rightDeviceName']}',
                ),
                onTap: () async {
                  String channelNumber = glasses['channelNumber']!;
                  await BleManager.get()
                      .connectToGlasses("Pair_$channelNumber");
                  _refreshPage();
                },
              ),
            );
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GlassMate'),
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeaturesPage()),
              );
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: const Padding(
              padding:
                  EdgeInsets.only(left: 16, top: 12, bottom: 14, right: 16),
              child: Icon(Icons.menu),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade700, Colors.teal.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 44),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  if (BleManager.get().getConnectionStatus() ==
                      'Not connected') {
                    _startScan();
                  }
                },
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    BleManager.get().getConnectionStatus(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (BleManager.get().getConnectionStatus() == 'Not connected')
                blePairedList(),
              if (BleManager.get().isConnected)
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EvenAIListPage(),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        child: StreamBuilder<String>(
                          stream: EvenAI.textStream,
                          initialData:
                              "Press and hold left TouchBar to engage Even AI.",
                          builder: (context, snapshot) => Obx(
                            () => EvenAI.isEvenAISyncing.value
                                ? const SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: CircularProgressIndicator(),
                                  )
                                : Text(
                                    snapshot.data ?? "Loading...",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: BleManager.get().isConnected
                                          ? Colors.black
                                          : Colors.grey.withOpacity(0.5),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    scanTimer?.cancel();
    isScanning = false;
    BleManager.get().onStatusChanged = null;
    super.dispose();
  }
}
