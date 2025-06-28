// Handles file storage operations using expo-file-system
import * as FileSystem from 'expo-file-system';

export const saveFile = async (uri, fileName) => {
  const dest = FileSystem.documentDirectory + fileName;
  await FileSystem.copyAsync({ from: uri, to: dest });
  return dest;
};

export const deleteFile = async (fileUri) => {
  await FileSystem.deleteAsync(fileUri);
};

export const listFiles = async () => {
  return await FileSystem.readDirectoryAsync(FileSystem.documentDirectory);
};
