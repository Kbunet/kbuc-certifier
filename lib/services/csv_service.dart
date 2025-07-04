import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../utils/date_utils.dart';

/// Service to handle CSV operations related to certificates
class CSVService {
  /// Create a CSV template file with all required and optional columns for certificates
  Future<File> createCertificateTemplate() async {
    // Define the header with all required and optional fields
    final header = [
      // Required fields
      'type',
      'recipient',
      'issuer',
      'description',
      'date',
      // Optional fields
      'tags',
      'duration',
      'event',
      'location',
      'certificate_id'
    ];

    // Add a sample row to demonstrate the format
    final sampleRow = [
      'degree', // type
      'John Doe', // recipient
      'University of ABC', // issuer
      'Bachelor of Science in Computer Science', // description
      '2025-06-30', // date
      'academic,computer science,2025', // tags (optional, comma-separated)
      '4 years', // duration (optional)
      'Graduation Ceremony', // event (optional)
      'Main Campus', // location (optional)
      'CS-2025-001' // certificate_id (optional)
    ];

    // Create the CSV content
    final csvData = [header, sampleRow];
    final csvString = const ListToCsvConverter().convert(csvData);

    // Save to a file in the temp directory
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/certificate_template.csv';
    final file = File(filePath);
    await file.writeAsString(csvString);

    return file;
  }

  /// Parse a CSV file into a list of certificate data maps
  Future<List<Map<String, dynamic>>> parseCertificateCSV(File file) async {
    final csvString = await file.readAsString();
    final csvTable = const CsvToListConverter().convert(csvString);

    if (csvTable.isEmpty) {
      throw Exception('CSV file is empty');
    }

    final headers = csvTable[0].map((e) => e.toString().trim()).toList();
    final requiredFields = ['type', 'recipient', 'issuer', 'description', 'date'];
    
    // Validate that all required fields are present
    for (final field in requiredFields) {
      if (!headers.contains(field)) {
        throw Exception('CSV is missing required field: $field');
      }
    }

    final certificates = <Map<String, dynamic>>[];
    
    // Skip the header row and process each data row
    for (int i = 1; i < csvTable.length; i++) {
      final row = csvTable[i];
      if (row.length != headers.length) {
        print('Warning: Row $i has ${row.length} values but ${headers.length} headers. Skipping.');
        continue;
      }
      
      // Create a map for this certificate
      final certificate = <String, dynamic>{};
      for (int j = 0; j < headers.length; j++) {
        final value = row[j];
        final fieldName = headers[j];
        
        // Only include non-empty values
        if (value != null && value.toString().trim().isNotEmpty) {
          // Handle date field specially
          if (fieldName == 'date') {
            final standardizedDate = CertificateDateUtils.parseAndStandardizeDate(value.toString());
            if (standardizedDate == null) {
              print('Warning: Row $i has invalid date format: "${value}". Skipping.');
              certificate[fieldName] = null; // Mark as invalid
            } else {
              certificate[fieldName] = standardizedDate;
            }
          }
          // Handle tags field specially - convert comma-separated string to list
          else if (fieldName == 'tags') {
            // Split by comma, trim whitespace, and filter out empty tags
            final tagsList = value.toString()
                .split(',')
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList();
            
            if (tagsList.isNotEmpty) {
              certificate[fieldName] = tagsList;
            }
          } 
          else {
            certificate[fieldName] = value.toString().trim();
          }
        }
      }
      
      // Validate that all required fields have values
      bool isValid = true;
      for (final field in requiredFields) {
        if (!certificate.containsKey(field) || 
            certificate[field] == null || 
            certificate[field].isEmpty) {
          print('Warning: Row $i is missing required field: $field. Skipping.');
          isValid = false;
          break;
        }
      }
      
      if (isValid) {
        certificates.add(certificate);
      }
    }
    
    return certificates;
  }
}
