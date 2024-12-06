import 'dart:async';
import 'dart:convert';
import 'package:glassmate/views/features/game_updates/tabs/live_games_details.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LiveGamesTab extends StatefulWidget {
  @override
  _LiveGamesTabState createState() => _LiveGamesTabState();
}

class _LiveGamesTabState extends State<LiveGamesTab> {
  List<dynamic> liveGames = [];
  Timer? pollingTimer;

  @override
  void initState() {
    super.initState();
    fetchLiveGames();
    startPolling();
  }

  @override
  void dispose() {
    pollingTimer?.cancel();
    super.dispose();
  }

  void startPolling() {
    pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchLiveGames();
    });
  }

  Future<void> fetchLiveGames() async {
    const url = 'https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard';
    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      setState(() {
        liveGames = data['events'] ?? [];
      });
    } catch (e) {
      print('Error fetching live games: $e');
    }
  }

   @override
  Widget build(BuildContext context) {
    return liveGames.isEmpty
        ? const Center(child: Text('No live games currently'))
        : ListView.builder(
            itemCount: liveGames.length,
            itemBuilder: (context, index) {
              final game = liveGames[index];
              final competitors = game['competitions'][0]['competitors'];
              final homeTeam = competitors.firstWhere((team) => team['homeAway'] == 'home');
              final awayTeam = competitors.firstWhere((team) => team['homeAway'] == 'away');
              final status = game['status']['type']['description'];
              final clock = game['status']['displayClock'];
              final period = game['status']['period'];

              return ListTile(
                title: Text('${awayTeam['team']['displayName']} @ ${homeTeam['team']['displayName']}'),
                subtitle: Text('Score: ${awayTeam['score']} - ${homeTeam['score']}\n'
                    'Status: $status\n'
                    'Clock: $clock | Quarter: $period'),
                isThreeLine: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LiveGameDetailsPage(game: game),
                    ),
                  );
                },
              );
            },
          );
  }
}
