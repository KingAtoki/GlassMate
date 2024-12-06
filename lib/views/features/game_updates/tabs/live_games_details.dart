import 'dart:convert';
import 'dart:io';
import 'package:glassmate/ble_manager.dart';
import 'package:glassmate/services/features_services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class LiveGameDetailsPage extends StatefulWidget {
  final Map<String, dynamic> game;

  const LiveGameDetailsPage({super.key, required this.game});

  @override
  State<LiveGameDetailsPage> createState() => _LiveGameDetailsPageState();
}

class _LiveGameDetailsPageState extends State<LiveGameDetailsPage> {
  List<String> playHistory = [];
  final FeaturesServices featuresServices = FeaturesServices();
  File? generatedBmpFile;

  @override
  void initState() {
    super.initState();
    _initializeLastPlay();
    _startPolling();
  }

  // Initialize play history with the first play
  void _initializeLastPlay() {
    final lastPlay = widget.game['competitions'][0]['situation']?['lastPlay'];
    if (lastPlay != null && lastPlay['text'] != null) {
      setState(() {
        playHistory.add(lastPlay['text']);
      });
    }
  }

  // Poll for updates every 10 seconds
  void _startPolling() {
    Future.delayed(const Duration(seconds: 10), () async {
      await _fetchUpdatedGameDetails();
      if (mounted) _startPolling();
    });
  }

  // Fetch updated game details and update play history
  Future<void> _fetchUpdatedGameDetails() async {
    final gameId = widget.game['id'];
    final url =
        'https://site.api.espn.com/apis/site/v2/sports/football/nfl/summary?event=$gameId';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final updatedGame = jsonDecode(response.body);
        final drives = updatedGame['drives']?['current'];
        final lastPlay = drives?['plays']?.lastWhere(
          (play) => play['type']?['text'] != null,
          orElse: () => null,
        );

        if (lastPlay != null && lastPlay['text'] != null) {
          setState(() {
            if (playHistory.isEmpty || playHistory.last != lastPlay['text']) {
              playHistory.add(lastPlay['text']);
            }
          });

          // Regenerate BMP after updating play history
          await _generateBmpForLastUpdates();
        }
      } else {
        print('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching updated game details: $e');
    }
  }

  Future<void> _generateBmpForLastUpdates() async {
    if (playHistory.isEmpty) {
      print('No play history available to generate BMP.');
      return;
    }

    const lineHeight = 20; // Adjust the line height as needed
    final config = playHistory
        .take(5) // Limit to the last 5 plays to fit in the available space
        .toList() // Convert to a List to use asMap
        .asMap()
        .entries
        .map((entry) => {
              'text': entry.value,
              'x': 10,
              'y': 10 +
                  (entry.key * lineHeight), // Adjust y position dynamically
              'fontSize': 12,
            })
        .toList();

    final outputPath = '${Directory.systemTemp.path}/last_updates.bmp';

    try {
      // Generate and save the BMP image
      featuresServices.createBmpImage(
        config,
        outputPath,
        width: 576, // Adjust for glasses max size
        height: 136, // Adjust for glasses max size
      );

      // Explicitly replace the file reference in the widget
      setState(() {
        generatedBmpFile = File(outputPath); // Reassign the file
      });

      print('BMP generated and replaced at $outputPath with the last updates.');
    } catch (e) {
      print('Error generating BMP: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final competitors = widget.game['competitions'][0]['competitors'] ?? [];
    final homeTeam = competitors.firstWhere(
      (team) => team['homeAway'] == 'home',
      orElse: () => null,
    );
    final awayTeam = competitors.firstWhere(
      (team) => team['homeAway'] == 'away',
      orElse: () => null,
    );
    final status = widget.game['status']['type']['description'] ?? 'Unknown';
    final clock = widget.game['status']['displayClock'] ?? '0:00';
    final period = widget.game['status']['period'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _generateBmpForLastUpdates,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.center,
                child:
                    const Text("Generate BMP", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
            if (generatedBmpFile != null) ...[
              const Text(
                'Generated BMP Image:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Image.file(
                generatedBmpFile!,
                width: 300,
                height: 100,
                key: ValueKey(
                    generatedBmpFile!.path), // Unique key to force refresh
                errorBuilder: (context, error, stackTrace) =>
                    const Text('Error displaying image'),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (homeTeam != null)
                  Column(
                    children: [
                      Image.network(
                        homeTeam['team']['logo'] ?? '',
                        width: 100,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image),
                      ),
                      Text(
                        homeTeam['team']['displayName'] ?? 'Unknown Team',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                if (awayTeam != null)
                  Column(
                    children: [
                      Image.network(
                        awayTeam['team']['logo'] ?? '',
                        width: 100,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image),
                      ),
                      Text(
                        awayTeam['team']['displayName'] ?? 'Unknown Team',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Status: $status', style: const TextStyle(fontSize: 16)),
            Text('Clock: $clock', style: const TextStyle(fontSize: 16)),
            Text('Quarter: $period', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            const Text(
              'Last Plays:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: playHistory.isEmpty
                  ? const Center(child: Text('No play history available'))
                  : ListView.builder(
                      itemCount: playHistory.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(playHistory[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
