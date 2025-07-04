import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/content_part.dart';
import '../providers/content_provider.dart';
import '../widgets/tags_field.dart';
import '../widgets/qr_dialog.dart';
import '../widgets/address_qr_dialog.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'package:archive/archive.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ContentDetailsScreen extends StatefulWidget {
  final PortableContent content;

  const ContentDetailsScreen({
    super.key,
    required this.content,
  });

  @override
  State<ContentDetailsScreen> createState() => _ContentDetailsScreenState();
}

class _ContentDetailsScreenState extends State<ContentDetailsScreen> {
  bool _isEditingTags = false;
  late List<String> _currentTags;
  
  // Get the localizations instance
  AppLocalizations get localizations => AppLocalizations.of(context)!;
  
  @override
  void initState() {
    super.initState();
    // Initialize current tags from content
    final provider = Provider.of<ContentProvider>(context, listen: false);
    _currentTags = provider.getContentTags(widget.content);
  }
  
  // Show dialog to edit tags
  void _showTagsEditDialog(BuildContext context) {
    final tagsController = TextEditingController(
      text: _currentTags.join(', '),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.editCertificateTags),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tagsController,
              decoration: InputDecoration(
                labelText: localizations.certificateTags,
                hintText: localizations.enterTagsSeparatedByCommas,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Parse tags from input
              final tagsInput = tagsController.text.trim();
              final List<String> newTags = tagsInput.isEmpty 
                ? [] 
                : tagsInput.split(',').map((tag) => tag.trim()).toList();
              
              setState(() {
                _isEditingTags = true;
              });
              
              try {
                // Update tags in the database
                final contentProvider = context.read<ContentProvider>();
                await contentProvider.updateContentTags(widget.content.id, newTags);
                
                // Update local state
                setState(() {
                  _currentTags = List.from(newTags);
                  _isEditingTags = false;
                });
                
                _showMessage(context, localizations.tagsUpdatedSuccessfully);
              } catch (e) {
                setState(() {
                  _isEditingTags = false;
                });
                _showMessage(
                  context, 
                  localizations.failedToUpdateTags(e.toString()),
                  isError: true,
                );
              }
            },
            child: Text(localizations.save),
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  void _showAddressQrDialog(BuildContext context, String address, String label) {
    AddressQRDialog.show(
      context: context,
      title: label,
      address: address,
      label: label,
    );
  }

  Future<String> _createShareText(PortableContent content) async {
    return '''
Content Details:
Name: ${content.name}
Description: ${content.description}
ID: ${content.id}
Standard: ${content.standardName} v${content.standardVersion}
Created: ${content.createdAt}
Creator: ${content.creator}

Note: The content file is attached to this share.
''';
  }

  Future<void> _shareContent(BuildContext context) async {
    try {
      final provider = context.read<ContentProvider>();
      final tempDir = await getTemporaryDirectory();
      final exportFile = File('${tempDir.path}/share_content.pcontent');
      
      // Export the content to a temporary file
      await provider.exportContent(widget.content.id, targetFile: exportFile);
      
      // Create share text
      final shareText = await _createShareText(widget.content);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(exportFile.path)],
        text: shareText,
      );

      // Clean up the temporary file
      if (await exportFile.exists()) {
        await exportFile.delete();
      }
    } catch (e) {
      _showMessage(context, 'Failed to share content: $e', isError: true);
    }
  }

  Future<void> _sendReputation() async {
    final uri = Uri.parse('bluewallet:send?addresses=${widget.content.contentHash}-0.001-reputation');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch BlueWallet');
    }
  }
  
  /// Shows QR code dialog for a certificate
  void _showCertificateQR(BuildContext context, PortableContent content) {
    // Create a URL or data string that represents the certificate
    // Here we're using the content hash, but you could create a more structured data format
    final qrData = content.contentHash;
    final certTitle = content.name;
    
    QRDialog.show(
      context: context, 
      title: certTitle,
      data: qrData,
      onVerify: () {
        // Optional verification functionality
        Navigator.of(context).pop();
        _showMessage(context, localizations.certificateHashVerified);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.content.name),
        actions: [
          // Hide share button on Windows platform
          if (defaultTargetPlatform != TargetPlatform.windows)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareContent(context),
              tooltip: 'Share',
            ),
          // Hide reputation button on Windows platform
          if (defaultTargetPlatform != TargetPlatform.windows)
            IconButton(
              icon: const Icon(Icons.monetization_on_outlined),
              onPressed: _sendReputation,
              tooltip: 'Send Reputation',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Certificate Details Section - Moved to the top
          if (widget.content.standardName == 'W3-CERT-HASH') ...[            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.certificateDetails,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    _InfoRow(
                      label: localizations.type,
                      value: (widget.content.standardData['type'] as String).substring(0, 1).toUpperCase() + 
                             (widget.content.standardData['type'] as String).substring(1),
                    ),
                    _InfoRow(
                      label: localizations.recipient,
                      value: widget.content.standardData['recipient'] as String,
                    ),
                    _InfoRow(
                      label: localizations.issuer,
                      value: widget.content.standardData['issuer'] as String,
                    ),
                    _InfoRow(
                      label: localizations.description,
                      value: widget.content.standardData['description'] as String,
                    ),
                    _InfoRow(
                      label: localizations.date,
                      value: widget.content.standardData['date'] as String,
                    ),
                    if (widget.content.standardData.containsKey('duration')) 
                      _InfoRow(
                        label: localizations.durationLabel,
                        value: widget.content.standardData['duration'] as String,
                      ),
                    if (widget.content.standardData.containsKey('event')) 
                      _InfoRow(
                        label: localizations.event,
                        value: widget.content.standardData['event'] as String,
                      ),
                    if (widget.content.standardData.containsKey('location')) 
                      _InfoRow(
                        label: localizations.location,
                        value: widget.content.standardData['location'] as String,
                      ),
                    if (widget.content.standardData.containsKey('certificate_id')) 
                      _InfoRow(
                        label: localizations.certificateId,
                        value: widget.content.standardData['certificate_id'] as String,
                      ),
                      // Tags section with edit button
                      const SizedBox(height: 16), // Increased top spacing
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              localizations.tags,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _isEditingTags
                              ? const Center(child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ))
                              : Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _currentTags.isEmpty
                                  ? [Chip(
                                      label: Text(localizations.noTags),
                                      backgroundColor: Colors.grey,
                                      visualDensity: VisualDensity.compact,
                                    )]
                                  : _currentTags.map((tag) => Chip(
                                      label: Text(tag),
                                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                      visualDensity: VisualDensity.compact,
                                    )).toList(),
                              ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showTagsEditDialog(context),
                            tooltip: localizations.editTags,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Content Info Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.contentInformation,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _InfoRow(
                    label: localizations.id,
                    value: widget.content.id,
                  ),
                  _InfoRow(
                    label: localizations.standardName,
                    value: widget.content.standardName,
                  ),
                  _InfoRow(
                    label: localizations.standardVersion,
                    value: widget.content.standardVersion,
                  ),
                  // Display file attachments if available
                  if (widget.content.parts?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              localizations.files,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: widget.content.parts!.map((part) => Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  part.name,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              )).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _InfoRow(
                    label: localizations.contentHash,
                    value: widget.content.contentHash,
                  ),
                  _InfoRow(
                    label: localizations.name,
                    value: widget.content.name,
                  ),
                  _InfoRow(
                    label: localizations.description,
                    value: widget.content.description,
                  ),
                  _InfoRow(
                    label: localizations.created,
                    value: widget.content.createdAt.toString(),
                  ),
                  _InfoRow(
                    label: localizations.creator,
                    value: widget.content.creator.isEmpty ? localizations.notSet : widget.content.creator,
                    showCopyButton: widget.content.creator.isNotEmpty,
                    onCopy: () => _showAddressQrDialog(context, widget.content.creator, localizations.creator),
                  ),
                  _InfoRow(
                    label: localizations.ownerLabel,
                    value: widget.content.owner.isEmpty ? localizations.notSet : widget.content.owner,
                    showCopyButton: widget.content.owner.isNotEmpty,
                    onCopy: () => _showAddressQrDialog(context, widget.content.owner, localizations.ownerLabel),
                  ),
                  _InfoRow(
                    label: localizations.reputationScore,
                    value: widget.content.rps.toString(),
                  ),
                  if (widget.content.tags.isNotEmpty) ...[  
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            localizations.tags,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: widget.content.tags.map((tag) => Chip(
                              label: Text(tag),
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              visualDensity: VisualDensity.compact,
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],

                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Actions Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.actions,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.verified),
                    title: Text(localizations.verifyContent),
                    onTap: () async {
                      final contentProvider = context.read<ContentProvider>();
                      contentProvider.selectContent(widget.content.id);
                      
                      // Show loading indicator
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(localizations.verifyingContent),
                              ],
                            ),
                            duration: Duration(seconds: 30), // Long duration as default
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.all(8),
                          ),
                        );
                      }

                      try {
                        final isValid = await contentProvider.verifyContent();
                        // Hide the loading indicator
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        
                        if (context.mounted) {
                          if (isValid) {
                            _showMessage(
                              context,
                              localizations.contentVerificationSuccess,
                            );
                          } else {
                            _showMessage(
                              context,
                              localizations.contentVerificationFailed,
                              isError: true,
                            );
                          }
                        }
                      } catch (e) {
                        // Hide the loading indicator
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        
                        if (context.mounted) {
                          _showMessage(
                            context,
                            localizations.verificationError(e.toString()),
                            isError: true,
                          );
                        }
                      }
                    },
                  ),
                  // Export button (restored for all platforms)
                  ListTile(
                    leading: const Icon(Icons.save),
                    title: Text(localizations.exportContent),
                    onTap: () async {
                      try {
                        final contentProvider = context.read<ContentProvider>();
                        await contentProvider.exportContent(widget.content.id);
                        _showMessage(context, localizations.contentExportedSuccess);
                      } catch (e) {
                        _showMessage(
                          context,
                          localizations.failedToExportContent(e.toString()),
                          isError: true,
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(localizations.deleteContent),
                    textColor: Theme.of(context).colorScheme.error,
                    iconColor: Theme.of(context).colorScheme.error,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(localizations.deleteContent),
                          content: Text(
                            localizations.deleteContentConfirmation,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(localizations.cancel),
                            ),
                            TextButton(
                              onPressed: () {
                                final contentProvider = context.read<ContentProvider>();
                                contentProvider.deleteContent(widget.content.id);
                                Navigator.of(context).pop(); // Close dialog
                                Navigator.of(context).pop(); // Go back to list
                              },
                              child: Text(
                                localizations.delete,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Add bottom margin to keep away from the floating button
          SizedBox(height: 72),
          // Post content section removed - only using certificate standard
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // QR Code button - Enhanced appearance with active accent
          FloatingActionButton.extended(
            heroTag: 'qr',
            onPressed: () => _showCertificateQR(context, widget.content),
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.qr_code_scanner, size: 28),
            label: Text(localizations.showQRCode, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            tooltip: localizations.showQRCode,
          ),
          // Hide reputation button on Windows platform
          if (defaultTargetPlatform != TargetPlatform.windows) ...[  
            const SizedBox(width: 16),
            // Reputation button
            FloatingActionButton.extended(
              heroTag: 'rep',
              onPressed: _sendReputation,
              icon: const Icon(Icons.monetization_on_outlined),
              label: Text(localizations.sendReputation),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showCopyButton;
  final VoidCallback? onCopy;

  const _InfoRow({
    required this.label,
    required this.value,
    this.showCopyButton = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          if (showCopyButton)
            IconButton(
              icon: const Icon(Icons.qr_code, size: 20),
              onPressed: onCopy,
              tooltip: 'Show QR Code',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
