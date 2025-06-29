class Story {
  final String fileName;
  final int fileSize;
  final String fileType;
  final String s3Key;
  final String s3Location;
  final DateTime uploadedAt;
  final String category;

  Story({
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.s3Key,
    required this.s3Location,
    required this.uploadedAt,
    required this.category,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      fileName: json['fileName'] ?? 'Unknown',
      fileSize: json['fileSize'] ?? 0,
      fileType: json['fileType'] ?? 'application/octet-stream',
      s3Key: json['s3Key'] ?? '',
      s3Location: json['s3Location'] ?? '',
      uploadedAt: DateTime.tryParse(json['uploadedAt'] ?? '') ?? DateTime.now(),
      category: json['category'] ?? 'unknown',
    );
  }

  bool get isAudio => category == 'audio';
  bool get isText => category == 'text';

  String get displaySize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(uploadedAt);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${uploadedAt.day}/${uploadedAt.month}/${uploadedAt.year}';
    }
  }
}
