import 'package:flutter/material.dart';
import '../widgets/audio_player_widget.dart';
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
            AudioPlayerWidget(),
            SeekBarWidget(),
            ControlsWidget(),
          ],
        ),
      ),
    );
  }
}
