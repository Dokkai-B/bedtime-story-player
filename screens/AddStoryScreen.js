import React from 'react';
import { View, Text, Button } from 'react-native';

export default function AddStoryScreen({ navigation }) {
  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <Text>Add a new story (import or record)</Text>
      <Button title="Go Back" onPress={() => navigation.goBack()} />
    </View>
  );
}
