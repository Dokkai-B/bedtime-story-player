import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/player_screen.dart';
import 'screens/add_story_screen.dart';

void main() {
  runApp(const BedtimeStoryPlayerApp());
}

class BedtimeStoryPlayerApp extends StatelessWidget {
  const BedtimeStoryPlayerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bedtime Story Player',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/player': (context) => const PlayerScreen(),
        '/add': (context) => const AddStoryScreen(),
      },
    );
  }
}
