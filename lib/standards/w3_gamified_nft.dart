import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:pointycastle/digests/ripemd160.dart';
import 'content_standard.dart';
import '../models/content_part.dart';

class W3GamifiedNFTStandard implements ContentStandard {
  static final _ripemd160 = RIPEMD160Digest();

  @override
  String get name => 'W3-Gamified-NFT';

  @override
  String get version => '1.0.0';

  @override
  Map<String, dynamic> getRequiredFields() {
    return {
      'code': 'string',
      'owner': 'hex_string',
      'nonce': 'number',
      'image': 'file',
    };
  }

  @override
  Future<Map<String, dynamic>> validateData(Map<String, dynamic> data, List<File> files) async {
    print('\nValidating W3-Gamified-NFT data...');
    print('Data: $data');
    print('Number of files: ${files.length}');

    // Validate required fields
    if (!data.containsKey('code')) {
      throw Exception('Missing required field: code');
    }
    if (!data.containsKey('owner')) {
      throw Exception('Missing required field: owner');
    }
    if (!data.containsKey('nonce')) {
      throw Exception('Missing required field: nonce');
    }

    // Validate file types and sizes
    if (files.isEmpty) {
      throw Exception('At least one image file is required');
    }

    final validatedData = Map<String, dynamic>.from(data);
    final file = files[0]; // Use the first file as the image
    validatedData['image'] = file.path; // Always set the image path

    print('\nValidating image file: ${file.path}');
    final bytes = await file.readAsBytes();
    print('Image file size: ${bytes.length} bytes');

    // Validate file size (max 5MB)
    if (bytes.length > 5 * 1024 * 1024) {
      throw Exception('Image file too large: ${file.path}');
    }

    // Compute checksum for verification
    final checksum = sha256.convert(bytes).toString();
    print('Computed checksum: $checksum');

    // During content creation, we don't need to verify the checksum
    // as it will be set later in the content hash computation
    if (data.containsKey('imageChecksum') && data['imageChecksum'] != null) {
      print('Verifying checksum against expected value: ${data['imageChecksum']}');
      if (checksum != data['imageChecksum']) {
        throw Exception('Image file checksum mismatch: expected ${data['imageChecksum']}, got $checksum');
      }
      print('Checksum verification successful');
      validatedData['imageChecksum'] = data['imageChecksum'];
    } else {
      print('Setting new checksum for image');
      validatedData['imageChecksum'] = checksum;
    }

    print('Data validation successful');
    return validatedData;
  }

    @override
  Future<String> computeHash(Map<String, dynamic> standardData, List<ContentPart> parts) async {
    final code = standardData['code'] as String;
    final owner = standardData['owner'] as String;
    final nonce = standardData['nonce'] is String ? int.parse(standardData['nonce'] as String) : standardData['nonce'] as int;
    final imageChecksum = standardData['imageChecksum'] as String;

    // Concatenate in specified order
    final hashInput = code + owner + imageChecksum + nonce.toString();
    
    // First compute SHA-256
    final sha256Digest = sha256.convert(utf8.encode(hashInput));
    
    // Then compute RIPEMD160 of the SHA256 result
    final ripemd160Bytes = _ripemd160.process(sha256Digest.bytes as Uint8List);
    
    // Return as hex
    return hex.encode(ripemd160Bytes);
  }
}
