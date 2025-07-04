import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'content_standard.dart';
import '../models/content_part.dart';

class W3SimplePostNFTStandard implements ContentStandard {
  @override
  String get name => 'W3-S-POST-NFT';

  @override
  String get version => '1.0.0';

  @override
  Map<String, dynamic> getRequiredFields() {
    return {
      'text': 'Text content of the post',
      'mediaPath': 'Optional path to media file (image or video)',
      'mediaType': 'Type of media (image or video)',
      'mediaChecksum': 'SHA-256 checksum of the media file',
    };
  }

  @override
  Future<Map<String, dynamic>> validateData(
    Map<String, dynamic> data,
    List<File> files,
  ) async {
    print('\nValidating W3-S-POST-NFT data...');
    print('Data: $data');
    print('Number of files: ${files.length}');

    // Validate required fields
    if (!data.containsKey('text') || data['text'].toString().trim().isEmpty) {
      throw Exception('Missing or empty required field: text');
    }

    final validatedData = Map<String, dynamic>.from(data);

    // Handle media file if present
    if (files.isNotEmpty) {
      final mediaFile = files[0];
      
      // Get file extension from the file path
      final extension = path.extension(mediaFile.path).toLowerCase();
      
      // Validate file type
      if (!_isValidMediaType(extension)) {
        throw Exception(
          'Invalid media file type: $extension. Supported types: .jpg, .jpeg, .png, .gif, .mp4, .mov',
        );
      }

      // Validate file size
      final bytes = await mediaFile.readAsBytes();
      final isVideo = _isVideoFile(extension);
      final maxSize = isVideo ? 50 * 1024 * 1024 : 5 * 1024 * 1024; // 50MB for video, 5MB for images
      
      if (bytes.length > maxSize) {
        throw Exception(
          'Media file too large: ${mediaFile.path}. Maximum size: ${maxSize ~/ (1024 * 1024)}MB',
        );
      }

      // Compute media checksum
      final checksum = sha256.convert(bytes).toString();
      print('Computed media checksum: $checksum');

      // Use existing mediaPath if available, otherwise generate UUID
      final mediaPath = data['mediaPath'] ?? '${const Uuid().v4()}$extension';
      validatedData['mediaPath'] = mediaPath;
      validatedData['mediaType'] = _getMediaType(extension);
      validatedData['mediaChecksum'] = checksum;
    }

    print('Data validation successful');
    return validatedData;
  }

  @override
  Future<String> computeHash(Map<String, dynamic> data, List<ContentPart> parts) async {
    print('\nComputing hash with data: $data');
    print('Parts: $parts');
    
    final buffer = StringBuffer();
    
    // Add text content
    buffer.write(data['text']);

    // Add media info if present
    if (data.containsKey('mediaPath')) {
      buffer.write(data['mediaChecksum'] ?? '');
    }

    final content = buffer.toString();
    print('Content to hash: $content');

    // Compute final hash
    final contentHash = sha256.convert(utf8.encode(content)).toString();
    print('Computed content hash: $contentHash');
    
    return contentHash;
  }

  bool _isValidMediaType(String extension) {
    return ['.jpg', '.jpeg', '.png', '.gif', '.mp4', '.mov'].contains(extension);
  }

  bool _isVideoFile(String extension) {
    return ['.mp4', '.mov'].contains(extension);
  }

  String _getMediaType(String extension) {
    if (['.jpg', '.jpeg', '.png', '.gif'].contains(extension)) {
      return 'image';
    } else if (['.mp4', '.mov'].contains(extension)) {
      return 'video';
    }
    throw Exception('Unsupported media type: $extension');
  }
}
