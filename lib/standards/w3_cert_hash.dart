import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:collection/collection.dart';
import '../utils/date_utils.dart';
import './content_standard.dart';
import '../models/content_part.dart';

class W3CertificateStandard implements ContentStandard {
  @override
  String get name => 'W3-CERT-HASH';

  @override
  String get version => '1.1.0';

  // Valid certificate types
  static const List<String> validTypes = [
    'degree',
    'attendance',
    'appreciation',
    'participation',
    'completion',
    'honor'
  ];

  @override
  Map<String, dynamic> getRequiredFields() {
    return {
      'type': 'Type of certificate (degree, attendance, appreciation, participation, completion, honor)',
      'recipient': 'Full name of the certificate recipient',
      'issuer': 'Name of the issuing institution or organization',
      'description': 'Description of the certificate purpose or achievement',
      'date': 'ISO 8601 format date (YYYY-MM-DD)',
      'duration': 'Optional duration of event or program',
      'event': 'Optional name of the event',
      'location': 'Optional location where certificate was issued',
      'certificate_id': 'Optional unique identifier for the certificate',
      'tags': 'Optional list of tags associated with the certificate',
    };
  }

  @override
  Future<Map<String, dynamic>> validateData(
    Map<String, dynamic> data,
    List<File> files,
  ) async {
    print('\nValidating W3-CERT-HASH data...');
    print('Data: $data');

    final validatedData = Map<String, dynamic>.from(data);
    
    // Validate certificate type
    if (!data.containsKey('type') || data['type'].toString().trim().isEmpty) {
      throw Exception('Missing or empty required field: type');
    }
    
    final type = data['type'].toString().toLowerCase().trim();
    if (!validTypes.contains(type)) {
      throw Exception('Invalid certificate type: $type. Allowed types: ${validTypes.join(', ')}');
    }
    
    validatedData['type'] = type;

    // Validate required fields
    final requiredFields = ['recipient', 'issuer', 'description', 'date'];
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field].toString().trim().isEmpty) {
        throw Exception('Missing or empty required field: $field');
      }
    }

    // Parse and normalize date to ISO 8601 format (YYYY-MM-DD)
    final dateStr = data['date'].toString();
    final standardizedDate = CertificateDateUtils.parseAndStandardizeDate(dateStr);
  
    if (standardizedDate == null) {
      throw Exception('Could not parse date: "$dateStr". Please use a valid date format.');
    }
  
    // Update the date with the standardized version
    validatedData['date'] = standardizedDate;

    // Normalize strings by trimming and applying Unicode NFC normalization
    for (final key in validatedData.keys) {
      if (validatedData[key] is String) {
        // Trim whitespace and convert to NFC form
        validatedData[key] = validatedData[key].trim();
        // Note: Dart doesn't have built-in Unicode NFC normalization
        // In a real implementation, you would use a library like 'unorm' for JavaScript
        // or implement a proper Unicode normalization function
      }
      
      // Handle tags - ensure it's a List<String>
      if (key == 'tags') {
        if (validatedData[key] is List) {
          // Convert any non-string elements to strings
          validatedData[key] = (validatedData[key] as List)
              .map((tag) => tag.toString().trim())
              .where((tag) => tag.isNotEmpty)
              .toList();
        } else if (validatedData[key] is String) {
          // Parse comma-separated string into a list of tags
          final tagString = validatedData[key] as String;
          validatedData[key] = tagString
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList();
        }
      }
    }

    // Remove empty or null fields
    validatedData.removeWhere((key, value) => 
      value == null || (value is String && value.isEmpty));

    print('Data validation successful');
    return validatedData;
  }

  @override
  Future<String> computeHash(Map<String, dynamic> data, List<ContentPart> parts) async {
    print('\nComputing hash with data: $data');
    
    // Create a normalized copy of the data
    final normalizedData = Map<String, dynamic>.from(data);
    
    // Remove any non-canonical fields
    final allowedFields = [
      'type', 'recipient', 'issuer', 'description', 'date',
      'duration', 'event', 'location', 'certificate_id'
      // 'tags' removed from hash calculation as it's only metadata
    ];
    
    // Remove tags from hash calculation
    normalizedData.remove('tags');
    
    normalizedData.removeWhere((key, _) => !allowedFields.contains(key));
    
    // Remove empty or null fields
    normalizedData.removeWhere((key, value) => 
      value == null || (value is String && value.isEmpty));
    
    // Define canonical order for keys (instead of alphabetical)
    final keyOrder = [
      'type', 'recipient', 'issuer', 'description', 'date',
      'duration', 'event', 'location', 'certificate_id'
      // 'tags' removed from hash calculation as it's only metadata
    ];
    
    // Sort keys according to defined order to ensure deterministic ordering
    final sortedMap = <String, dynamic>{};
    
    // Add keys in the defined order (if they exist in normalizedData)
    for (final key in keyOrder) {
      if (normalizedData.containsKey(key)) {
        sortedMap[key] = normalizedData[key];
      }
    }
    
    // Convert to minified JSON (no extra whitespace)
    final jsonString = jsonEncode(sortedMap);
    print('Canonical JSON: $jsonString');
    
    // Compute SHA-256 hash of UTF-8 encoded JSON
    final hash = sha256.convert(utf8.encode(jsonString)).toString();
    print('Computed certificate hash: $hash');
    
    return hash;
  }
}
