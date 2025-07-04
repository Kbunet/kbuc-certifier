import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../utils/date_utils.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/content_service.dart';
import 'tags_field.dart';

class StandardContentFormDialog extends StatefulWidget {
  const StandardContentFormDialog({super.key});

  @override
  State<StandardContentFormDialog> createState() => _StandardContentFormDialogState();
}

class _StandardContentFormDialogState extends State<StandardContentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Certificate fields
  final _recipientController = TextEditingController();
  final _issuerController = TextEditingController();
  final _certDescController = TextEditingController();
  final _dateController = TextEditingController();
  final _durationController = TextEditingController();
  final _eventController = TextEditingController();
  final _locationController = TextEditingController();
  final _certificateIdController = TextEditingController();
  String _selectedCertType = 'degree';
  
  // Tags field
  List<String> _tags = [];
  
  String _selectedStandard = 'W3-CERT-HASH'; // Only using certificate standard
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    // Certificate controllers
    _recipientController.dispose();
    _issuerController.dispose();
    _certDescController.dispose();
    _dateController.dispose();
    _durationController.dispose();
    _eventController.dispose();
    _locationController.dispose();
    _certificateIdController.dispose();
    super.dispose();
  }

  // Media picker removed as it's no longer needed for certificate standard

  // We only use the certificate standard now, so other field builder methods have been removed

  Widget _buildCertificateFields() {
    return Column(
      children: [
        // Certificate Type Dropdown
        DropdownButtonFormField<String>(
          value: _selectedCertType,
          decoration: const InputDecoration(
            labelText: 'Certificate Type',
            hintText: 'Select certificate type',
          ),
          items: [
            'degree',
            'attendance',
            'appreciation',
            'participation',
            'completion',
            'honor'
          ].map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.substring(0, 1).toUpperCase() + type.substring(1)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCertType = value;
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a certificate type';
            }
            return null;
          },
        ),
        
        // Recipient Field (Required)
        TextFormField(
          controller: _recipientController,
          decoration: const InputDecoration(
            labelText: 'Recipient Name *',
            hintText: 'Enter recipient full name',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter recipient name';
            }
            return null;
          },
        ),
        
        // Issuer Field (Required)
        TextFormField(
          controller: _issuerController,
          decoration: const InputDecoration(
            labelText: 'Issuer *',
            hintText: 'Enter issuing institution or organization',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter issuer name';
            }
            return null;
          },
        ),
        
        // Description Field (Required)
        TextFormField(
          controller: _certDescController,
          decoration: const InputDecoration(
            labelText: 'Description *',
            hintText: 'Enter certificate description or purpose',
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
        
        // Date Field (Required)
        TextFormField(
          controller: _dateController,
          decoration: const InputDecoration(
            labelText: 'Issue Date *',
            hintText: 'e.g., 2025-07-01, 07/01/2025, Jul 1, 2025',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a date';
            }
            
            // Try to parse the date using our flexible parser
            final standardizedDate = CertificateDateUtils.parseAndStandardizeDate(value);
            if (standardizedDate == null) {
              return 'Please enter a valid date';
            }
            
            // Update the controller with the standardized format
            if (value != standardizedDate) {
              // We use Future.microtask to avoid modifying the TextFormField during validation
              Future.microtask(() {
                _dateController.text = standardizedDate;
              });
            }
            
            return null;
          },
        ),
        
        // Optional fields
        const SizedBox(height: 16),
        const Text('Optional Fields',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        // Tags field
        TagsField(
          initialTags: _tags,
          onTagsChanged: (tags) {
            setState(() {
              _tags = tags;
            });
          },
          labelText: 'Certificate Tags',
          hintText: 'Enter tags separated by commas (e.g., academic, online, 2025)',
        ),
        const SizedBox(height: 8),
        
        // Duration Field (Optional)
        TextFormField(
          controller: _durationController,
          decoration: const InputDecoration(
            labelText: 'Duration',
            hintText: 'Enter duration (e.g., 3 days)',
          ),
        ),
        
        // Event Field (Optional)
        TextFormField(
          controller: _eventController,
          decoration: const InputDecoration(
            labelText: 'Event',
            hintText: 'Enter event name',
          ),
        ),
        
        // Location Field (Optional)
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Location',
            hintText: 'Enter location',
          ),
        ),
        
        // Certificate ID Field (Optional)
        TextFormField(
          controller: _certificateIdController,
          decoration: const InputDecoration(
            labelText: 'Certificate ID',
            hintText: 'Enter unique certificate identifier',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Content'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content Standard:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'W3-CERT-HASH',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter content name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter content description',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildCertificateFields(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () {
                  if (_formKey.currentState!.validate()) {
                    final result = {
                      'standard': _selectedStandard,
                      'name': _nameController.text,
                      'description': _descriptionController.text,
                    };

                    // Add certificate data with required fields
                    final certificateData = {
                      'type': _selectedCertType,
                      'recipient': _recipientController.text,
                      'issuer': _issuerController.text,
                      'description': _certDescController.text,
                      'date': _dateController.text,
                    };
                    
                    // Add optional fields only if they have values
                    if (_durationController.text.isNotEmpty) {
                      certificateData['duration'] = _durationController.text;
                    }
                    if (_eventController.text.isNotEmpty) {
                      certificateData['event'] = _eventController.text;
                    }
                    if (_locationController.text.isNotEmpty) {
                      certificateData['location'] = _locationController.text;
                    }
                    if (_certificateIdController.text.isNotEmpty) {
                      certificateData['certificate_id'] = _certificateIdController.text;
                    }
                    
                    // Add tags if they exist
                    if (_tags.isNotEmpty) {
                      // Convert List<String> to comma-separated String for compatibility
                      certificateData['tags'] = _tags.join(',');
                    }
                    
                    result.addAll(certificateData);

                    Navigator.of(context).pop(result);
                  }
                },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
