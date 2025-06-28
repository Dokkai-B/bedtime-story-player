// Handles story metadata (title, file path, etc.) using AsyncStorage
import AsyncStorage from '@react-native-async-storage/async-storage';

const STORY_KEY = 'STORIES';

export const getStories = async () => {
  const json = await AsyncStorage.getItem(STORY_KEY);
  return json ? JSON.parse(json) : [];
};

export const saveStory = async (story) => {
  const stories = await getStories();
  stories.push(story);
  await AsyncStorage.setItem(STORY_KEY, JSON.stringify(stories));
};

export const updateStories = async (stories) => {
  await AsyncStorage.setItem(STORY_KEY, JSON.stringify(stories));
};
