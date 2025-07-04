import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import '../providers/content_provider.dart';
import '../services/csv_service.dart';
import '../widgets/tags_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CertificateBatchScreen extends StatefulWidget {
  const CertificateBatchScreen({super.key});

  @override
  State<CertificateBatchScreen> createState() => _CertificateBatchScreenState();
}

class _CertificateBatchScreenState extends State<CertificateBatchScreen> {
  final CSVService _csvService = CSVService();
  
  File? _csvFile;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _error;
  List<Map<String, dynamic>> _certificates = [];
  int _processedCount = 0;
  int _totalCount = 0;
  
  // Global tags to apply to all certificates being imported
  List<String> _globalTags = [];

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final templateFile = await _csvService.createCertificateTemplate();
      
      final localizations = AppLocalizations.of(context);
      _showMessage(localizations?.templateDownloaded(templateFile.path) ?? 
        'Template downloaded to: ${templateFile.path}\nYou can open it with any spreadsheet application.');
    } catch (e) {
      final localizations = AppLocalizations.of(context);
      _showMessage(localizations?.failedToCreateTemplate(e.toString()) ?? 
        'Failed to create template: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickCSVFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _certificates = [];
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        
        // Validate file extension
        if (path.extension(file.path).toLowerCase() != '.csv') {
          throw Exception('Selected file is not a CSV file');
        }

        setState(() {
          _csvFile = file;
        });

        // Parse the CSV file
        final certificates = await _csvService.parseCertificateCSV(file);
        setState(() {
          _certificates = certificates;
        });

        if (_certificates.isEmpty) {
          final localizations = AppLocalizations.of(context);
          _showMessage(localizations?.noValidCertificateData ?? 
            'No valid certificate data found in the CSV file', isError: true);
        } else {
          final localizations = AppLocalizations.of(context);
          _showMessage(localizations?.foundCertificates(_certificates.length) ?? 
            'Found ${_certificates.length} certificate(s) to process');
        }
      }
    } catch (e) {
      final localizations = AppLocalizations.of(context);
      final errorMessage = localizations?.failedToProcessCSV(e.toString()) ?? 'Failed to process CSV file: $e';
      setState(() {
        _error = errorMessage;
        _csvFile = null;
      });
      _showMessage(errorMessage, isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processCertificates() async {
    final localizations = AppLocalizations.of(context);
    if (_certificates.isEmpty) {
      _showMessage(localizations?.noCertificatesToProcess ?? 'No certificates to process', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _processedCount = 0;
      _totalCount = _certificates.length;
      _error = null;
    });

    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    
    // Get existing certificates for duplicate checking
    final existingContents = contentProvider.getAllContents();
    int skippedCount = 0;

    try {
      for (var certificate in _certificates) {
        // Generate name based on recipient and date
        final name = '${certificate['recipient']} - ${certificate['date']}';
        
        // Use certificate description as content description
        final description = certificate['description'];
        
        // Apply global tags to each certificate if they exist
        if (_globalTags.isNotEmpty) {
          // Get existing tags if any
          List<String> existingTags = [];
          if (certificate.containsKey('tags')) {
            if (certificate['tags'] is List) {
              existingTags = List<String>.from(certificate['tags']);
            } else if (certificate['tags'] is String) {
              existingTags = (certificate['tags'] as String)
                  .split(',')
                  .map((tag) => tag.trim())
                  .where((tag) => tag.isNotEmpty)
                  .toList();
            }
          }
          
          // Combine global tags with existing tags
          final allTags = [...existingTags, ..._globalTags];
          
          // Remove duplicates while preserving order
          final uniqueTags = <String>{};
          final combinedTags = <String>[];
          for (final tag in allTags) {
            if (uniqueTags.add(tag)) {
              combinedTags.add(tag);
            }
          }
          
          // Store as comma-separated string for compatibility
          certificate['tags'] = combinedTags.join(',');
        }
        
        // Make a copy of the certificate data without tags for hash computation
        final certificateForHash = Map<String, dynamic>.from(certificate);
        
        // Remove tags so they don't affect duplication check
        certificateForHash.remove('tags');
        
        // Check if this certificate would be a duplicate by having contentProvider
        // compute its hash without actually creating it
        final potentialHash = await contentProvider.computeContentHash(
          standardName: 'W3-CERT-HASH',
          standardVersion: '1.0.0',
          standardData: certificateForHash,
        );
        
        // Check if any existing content has the same hash (ignoring tags)
        bool isDuplicate = false;
        
        for (final content in existingContents) {
          // Get the standard data for the existing certificate
          final existingData = Map<String, dynamic>.from(content.standardData);
          
          // Remove tags from the existing data too
          existingData.remove('tags');
          
          // Compare core data by computing hash without tags
          final existingHash = await contentProvider.computeContentHash(
            standardName: 'W3-CERT-HASH',
            standardVersion: '1.0.0',
            standardData: existingData,
          );
          
          if (existingHash == potentialHash) {
            isDuplicate = true;
            break;
          }
        }
        
        if (isDuplicate) {
          // Skip this certificate as it already exists
          skippedCount++;
          setState(() {
            _processedCount++;
          });
        } else {
          // Create the certificate as it's not a duplicate
          await contentProvider.createContentDirect(
            name: name,
            description: description,
            standardName: 'W3-CERT-HASH', // Using our certificate standard
            standardVersion: '1.0.0',
            standardData: certificate,
            files: [], // No files for certificates created from CSV
          );

          setState(() {
            _processedCount++;
          });
        }
      }

      String resultMessage;
      if (skippedCount > 0) {
        resultMessage = localizations?.certificatesCreatedWithSkipped(_processedCount - skippedCount, skippedCount) ?? 
          'Successfully created ${_processedCount - skippedCount} certificate(s), skipped $skippedCount duplicate(s)';
      } else {
        resultMessage = localizations?.certificatesCreatedSuccess(_processedCount) ?? 
          'Successfully created ${_processedCount} certificate(s)';
      }
      _showMessage(resultMessage);
    } catch (e) {
      final errorMessage = localizations?.failedToCreateCertificates(e.toString()) ?? 'Failed to create certificates: $e';
      setState(() {
        _error = errorMessage;
      });
      _showMessage(errorMessage, isError: true);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.batchCertificateUpload ?? 'Batch Certificate Upload'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)?.uploadMultipleCertificates ?? 'Upload Multiple Certificates',
                style: const TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)?.batchUploadDescription ?? 
                'Use this tool to upload multiple certificates at once using a CSV file. '
                'Each row in the CSV will be converted to a separate certificate.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              
              // Step 1: Download Template
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.step1DownloadTemplate ?? 'Step 1: Download Template',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)?.downloadTemplateDescription ?? 
                        'Download a CSV template with all required and optional fields for certificates.',
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _downloadTemplate,
                        icon: const Icon(Icons.download),
                        label: Text(AppLocalizations.of(context)?.downloadTemplate ?? 'Download Template'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Step 2: Upload CSV
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.step2UploadCSV ?? 'Step 2: Upload CSV File',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)?.uploadCSVDescription ?? 
                        'Fill in the template with your certificate data and upload it here.',
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading || _isProcessing ? null : _pickCSVFile,
                        icon: const Icon(Icons.upload_file),
                        label: Text(AppLocalizations.of(context)?.selectCSVFile ?? 'Select CSV File'),
                      ),
                      if (_csvFile != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)?.selectedFile(path.basename(_csvFile!.path)) ?? 
                          'Selected file: ${path.basename(_csvFile!.path)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Step 3: Review & Process
              if (_certificates.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.step3ReviewProcess ?? 'Step 3: Review & Process',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)?.foundCertificates(_certificates.length) ?? 
                          'Found ${_certificates.length} certificate(s) to process.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        
                        // Global Tags Field for all certificates
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)?.addTagsToAll ?? 'Add tags to all certificates:',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TagsField(
                              initialTags: _globalTags,
                              onTagsChanged: (tags) {
                                setState(() {
                                  _globalTags = tags;
                                });
                              },
                              hintText: AppLocalizations.of(context)?.enterCommonTags ?? 'Enter common tags for all certificates',
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Certificate list preview
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListView.builder(
                            itemCount: _certificates.length,
                            itemBuilder: (context, index) {
                              final cert = _certificates[index];
                              return ListTile(
                                title: Text('${cert['recipient']} - ${cert['date']}'),
                                subtitle: Text('${cert['type']} from ${cert['issuer']}'),
                                leading: const Icon(Icons.verified),
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        _isProcessing
                            ? Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: _totalCount > 0
                                        ? _processedCount / _totalCount
                                        : 0,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context)?.processing(_processedCount, _totalCount) ?? 
                                    'Processing: $_processedCount of $_totalCount',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            : ElevatedButton.icon(
                                onPressed: _isLoading ? null : _processCertificates,
                                icon: const Icon(Icons.check_circle),
                                label: Text(AppLocalizations.of(context)?.createCertificates ?? 'Create Certificates'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
              
              // Error display
              if (_error != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)?.errorTitle ?? 'Error',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_error!),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
