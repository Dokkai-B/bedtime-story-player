import React from 'react';
import { View, Text } from 'react-native';
import AudioPlayer from '../components/AudioPlayer';
import Controls from '../components/Controls';
import SeekBar from '../components/SeekBar';

export default function PlayerScreen() {
  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <Text>Player Screen</Text>
      <AudioPlayer />
      <SeekBar />
      <Controls />
    </View>
  );
}
