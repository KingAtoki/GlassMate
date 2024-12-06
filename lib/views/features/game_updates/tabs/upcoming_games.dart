import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class UpcomingGamesTab extends StatefulWidget {
  const UpcomingGamesTab({super.key});

  @override
  _UpcomingGamesTabState createState() => _UpcomingGamesTabState();
}

class _UpcomingGamesTabState extends State<UpcomingGamesTab> {
  List<dynamic> teams = [];
  String? selectedTeamId;
  List<dynamic> upcomingGames = [];

  @override
  void initState() {
    super.initState();
    fetchTeams();
  }

  Future<void> fetchTeams() async {
    const url =
        'https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams';
    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      setState(() {
        teams = data['sports'][0]['leagues'][0]['teams'];
      });
    } catch (e) {
      print('Error fetching teams: $e');
    }
  }

  Future<void> fetchUpcomingGames(String teamId) async {
    final url =
        'https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams/$teamId';
    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      setState(() {
        // Extracting upcoming games from the `nextEvent` array
        upcomingGames = (data['team']['nextEvent'] as List).map((event) {
          return {
            'id': event['id'],
            'name': event['name'],
            'shortName': event['shortName'],
            'date': event['date'],
            'venue': event['competitions'][0]['venue']['fullName'],
            'city': event['competitions'][0]['venue']['address']['city'],
            'state': event['competitions'][0]['venue']['address']['state'],
            'teamHome': event['competitions'][0]['competitors'][0]['team']
                ['displayName'],
            'teamAway': event['competitions'][0]['competitors'][1]['team']
                ['displayName'],
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching games: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButton<String>(
          hint: const Text('Select a Team'),
          value: selectedTeamId,
          items: teams.map<DropdownMenuItem<String>>((team) {
            final teamId = team['team']['id'] as String;
            final teamName = team['team']['displayName'] as String;
            return DropdownMenuItem<String>(
              value: teamId,
              child: Text(teamName),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedTeamId = value;
              upcomingGames = [];
            });
            fetchUpcomingGames(value!);
          },
        ),
        Expanded(
          child: upcomingGames.isEmpty
              ? const Center(child: Text('No upcoming games'))
              : ListView.builder(
                  itemCount: upcomingGames.length,
                  itemBuilder: (context, index) {
                    final game = upcomingGames[index];

                    // Parse and format the date
                    final rawDate = game['date'];
                    final formattedDate = DateFormat('EEEE, MMM d, y h:mm a')
                        .format(DateTime.parse(rawDate).toLocal());

                    return ListTile(
                      title:
                          Text(game['name']), // Game name (e.g., "PHI @ BAL")
                      subtitle: Text(
                        'Date: $formattedDate\nVenue: ${game['venue']}, ${game['city']}, ${game['state']}',
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
