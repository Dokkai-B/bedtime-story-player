import 'package:flutter/material.dart';
import '../widgets/controls_widget.dart';
import '../widgets/seek_bar_widget.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Player')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Audio Player',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Use the Library to play your stories!',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 40),
            SeekBarWidget(),
            ControlsWidget(),
          ],
        ),
      ),
    );
  }
}
