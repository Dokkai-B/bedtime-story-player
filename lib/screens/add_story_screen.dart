import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/story_upload_service.dart';

class AddStoryScreen extends StatefulWidget {
  const AddStoryScreen({Key? key}) : super(key: key);

  @override
  State<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen> {
  File? _selectedFile;
  String? _fileName;
  String? _fileSize;
  String? _fileType;
  bool _isUploading = false;
  String? _uploadMessage;
  Color _messageColor = Colors.green;
  String? _s3Url;

  final StoryUploadService _uploadService = StoryUploadService();

  // Pick file using file_picker
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'pdf', 'mp3', 'wav', 'm4a', 'aac'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
          _fileSize = _formatFileSize(result.files.single.size);
          _fileType = result.files.single.extension?.toLowerCase();
          _uploadMessage = null;
          _s3Url = null;
        });
      }
    } catch (e) {
      setState(() {
        _uploadMessage = 'Error picking file: ${e.toString()}';
        _messageColor = Colors.red;
      });
    }
  }

  // Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Upload file to backend
  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      setState(() {
        _uploadMessage = 'Please select a file first';
        _messageColor = Colors.orange;
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadMessage = 'Uploading file...';
      _messageColor = Colors.blue;
    });

    try {
      final result = await _uploadService.uploadFile(_selectedFile!);
      
      setState(() {
        _isUploading = false;
        _uploadMessage = 'Upload successful! 🎉';
        _messageColor = Colors.green;
        _s3Url = result['s3Location'];
      });

      // Show success dialog
      _showSuccessDialog(result);
      
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadMessage = 'Upload failed: ${e.toString()}';
        _messageColor = Colors.red;
      });
    }
  }

  // Show success dialog with upload details
  void _showSuccessDialog(Map<String, dynamic> uploadResult) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Upload Successful!'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('File: ${uploadResult['fileName']}'),
                Text('Size: ${_formatFileSize(uploadResult['fileSize'])}'),
                Text('Type: ${uploadResult['fileType']}'),
                const SizedBox(height: 8),
                const Text('S3 Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(
                  uploadResult['s3Location'] ?? 'N/A',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
                if (uploadResult['testMode'] == true) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '⚠️ TEST MODE: File uploaded to development server',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Clear selected file
  void _clearFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _fileSize = null;
      _fileType = null;
      _uploadMessage = null;
      _s3Url = null;
    });
  }

  // Get file type icon
  IconData _getFileTypeIcon() {
    switch (_fileType) {
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'aac':
        return Icons.audiotrack;
      case 'txt':
      case 'md':
        return Icons.description;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Get file type color
  Color _getFileTypeColor() {
    switch (_fileType) {
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'aac':
        return Colors.purple;
      case 'txt':
      case 'md':
        return Colors.blue;
      case 'pdf':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Story'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              'Upload a New Story',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a text or audio file to add to your story collection',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // File picker section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Choose File'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Supported formats: TXT, MD, PDF, MP3, WAV, M4A, AAC',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Selected file info
            if (_selectedFile != null) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getFileTypeIcon(),
                            color: _getFileTypeColor(),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fileName ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '$_fileSize • ${_fileType?.toUpperCase()}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _clearFile,
                            icon: const Icon(Icons.clear),
                            tooltip: 'Remove file',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _uploadFile,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload),
                          label: Text(_isUploading ? 'Uploading...' : 'Upload Story'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Upload message
            if (_uploadMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _messageColor.withOpacity(0.1),
                  border: Border.all(color: _messageColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _uploadMessage!,
                  style: TextStyle(
                    color: _messageColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const Spacer(),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📖 How to add stories:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Text files: Stories you can read'),
                  const Text('• Audio files: Stories you can listen to'),
                  const Text('• Files are securely stored in the cloud'),
                  const Text('• Maximum file size: 100MB'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
