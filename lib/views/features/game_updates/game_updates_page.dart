import 'package:glassmate/views/features/game_updates/tabs/live_games.dart';
import 'package:glassmate/views/features/game_updates/tabs/upcoming_games.dart';
import 'package:flutter/material.dart';

class GameUpdatesPage extends StatelessWidget {
  const GameUpdatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Game Updates'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Live Games'),
              Tab(text: 'Upcoming Games'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            LiveGamesTab(),
            const UpcomingGamesTab(),
          ],
        ),
      ),
    );
  }
}
