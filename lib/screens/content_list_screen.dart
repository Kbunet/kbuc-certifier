import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import './certificate_batch_screen.dart';
import '../providers/content_provider.dart';
import '../providers/electrum_provider.dart';
import '../models/content_part.dart';
import 'content_details_screen.dart';
import '../widgets/tags_field.dart';
import '../widgets/qr_dialog.dart';

class ContentListScreen extends StatefulWidget {
  const ContentListScreen({super.key});

  @override
  State<ContentListScreen> createState() => _ContentListScreenState();
}

class _ContentListScreenState extends State<ContentListScreen> {
  // State to track if the filter panel is expanded
  bool _isFilterExpanded = false;
  // State to track if the advanced filter options are shown
  bool _showFilterOptions = false;
  
  @override
  void dispose() {
    super.dispose();
  }
  
  void _deleteMultipleContents(BuildContext context, ContentProvider provider) {
    provider.deleteMultipleContents(context);
  }
  
  /// Export selected certificates to CSV file
  Future<void> _exportSelectedCertificatesToCSV(BuildContext context, ContentProvider provider) async {
    if (provider.selectedContentIds.isEmpty) {
      _showMessage(context, AppLocalizations.of(context)?.noCertificatesFound ?? 'No certificates selected for export', isError: true);
      return;
    }
    
    try {
      // Show loading indicator
      final loadingDialog = _showLoadingDialog(context, AppLocalizations.of(context)?.exportToCSV ?? 'Generating CSV export...');
      
      // Generate CSV content
      final csvContent = await provider.exportSelectedCertificatesToCSV();
      
      // Get the export directory (uses the dedicated KbucCertifier directory)
      final directory = await provider.getExportDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final fileName = 'certificates_export_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';
      
      // Write the CSV content to a file with UTF-8 encoding
      final file = File(filePath);
      await file.writeAsString(
        csvContent,
        encoding: utf8, // Explicitly use UTF-8 encoding for proper Arabic character support
      );
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success message with option to share the file
      _showExportSuccessDialog(context, file, fileName);
    } catch (e) {
      _showMessage(context, '${AppLocalizations.of(context)?.exportToCSV ?? 'Failed to export certificates'}: $e', isError: true);
    }
  }
  
  /// Show a loading dialog
  Widget _showLoadingDialog(BuildContext context, String message) {
    final dialog = AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(message)),
        ],
      ),
    );
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => dialog,
    );
    
    return dialog;
  }
  
  /// Show success dialog with options to share or open the exported file
  void _showExportSuccessDialog(BuildContext context, File file, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Certificates exported to: $fileName'),
            const SizedBox(height: 16),
            const Text('The file is saved in your Documents folder.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (Platform.isAndroid || Platform.isIOS)
            TextButton(
              onPressed: () {
                // Share file implementation would go here
                Navigator.of(context).pop();
              },
              child: const Text('Share'),
            ),
        ],
      ),
    );
  }
  
  /// Show a message to the user
  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// Show QR code dialog for a certificate
  void _showQRCode(BuildContext context, PortableContent content) {
    QRDialog.show(
      context: context,
      title: content.name,
      data: content.contentHash,
    );
  }
  
  /// Show profile dialog for a certificate hash
  void _showProfileDialog(BuildContext context, String contentHash) {
    final electrumProvider = Provider.of<ElectrumProvider>(context, listen: false);
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.verifying ?? 'Verifying Certificate'),
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(AppLocalizations.of(context)?.fetchingProfile ?? 'Fetching certificate profile...')),
          ],
        ),
      ),
    );
    
    // Fetch profile
    electrumProvider.fetchProfile(contentHash).then((_) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Get the profile
      final profile = electrumProvider.getProfile(contentHash);
      
      // Update the certificate with the profile data if available
      if (profile != null) {
        // Find the certificate with this content hash
        final certificates = contentProvider.contents;
        for (final cert in certificates) {
          if (cert.contentHash == contentHash) {
            // Update the certificate with the profile data
            // Create a new PortableContent with updated rps value
            final updatedContent = PortableContent(
              id: cert.id,
              name: cert.name,
              description: cert.description,
              standardName: cert.standardName,
              standardVersion: cert.standardVersion,
              standardData: cert.standardData,
              contentHash: cert.contentHash,
              parts: cert.parts,
              createdAt: cert.createdAt,
              updatedAt: DateTime.now(),
              owner: profile['owner'] ?? cert.owner,
              creator: profile['creator'] ?? cert.creator,
              rps: profile['rps'] != null ? int.tryParse(profile['rps'].toString()) ?? cert.rps : cert.rps,
              tags: cert.tags,
            );
            
            // Update the certificate in the content provider
            contentProvider.updateCertificate(updatedContent);
            break;
          }
        }
      }
      
      // Show profile dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)?.certificateProfile ?? 'Certificate Profile'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (profile != null) ..._buildProfileInfo(profile)
                else Text(AppLocalizations.of(context)?.noProfileFound ?? 'No profile information found'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)?.close ?? 'Close'),
            ),
          ],
        ),
      );
    }).catchError((error) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('${AppLocalizations.of(context)?.errorFetchingProfile ?? 'Error fetching profile'}: $error'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)?.close ?? 'Close'),
            ),
          ],
        ),
      );
    });
  }
  
  /// Build profile information widgets
  List<Widget> _buildProfileInfo(Map<String, dynamic> profile) {
    final widgets = <Widget>[];
    
    // Add each profile field
    profile.forEach((key, value) {
      if (value != null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  value.toString(),
                  style: const TextStyle(fontSize: 16),
                ),
                const Divider(),
              ],
            ),
          ),
        );
      }
    });
    
    return widgets;
  }
  
  /// Delete a single certificate
  void _deleteContent(BuildContext context, String contentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.delete ?? 'Delete Certificate'),
        content: Text(AppLocalizations.of(context)?.deleteSelected ?? 'Are you sure you want to delete this certificate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              final provider = Provider.of<ContentProvider>(context, listen: false);
              provider.deleteContent(contentId);
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)?.delete ?? 'Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
  
  /// Update tags for selected certificates
  void _updateTagsForSelectedContents(BuildContext context) {
    final provider = Provider.of<ContentProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;
    
    // Get common tags from selected contents
    final selectedContentIds = provider.selectedContentIds;
    
    // Get tags from selected contents
    final List<String> commonTags = [];
    for (final id in selectedContentIds) {
      final content = provider.getContentById(id);
      if (content != null) {
        final tags = provider.getContentTags(content);
        if (commonTags.isEmpty) {
          commonTags.addAll(tags);
        } else {
          commonTags.retainWhere((tag) => tags.contains(tag));
        }
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Tags'),
        content: SizedBox(
          width: double.maxFinite,
          child: TagsField(
            initialTags: commonTags,
            onTagsChanged: (tags) {
              provider.updateTagsForSelectedContents(tags);
              Navigator.of(context).pop();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.cancel),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final contentProvider = Provider.of<ContentProvider>(context);
    final selectedCount = contentProvider.selectedContentIds.length;
    
    return Scaffold(
      appBar: contentProvider.isMultiSelectMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: contentProvider.toggleMultiSelectMode,
                tooltip: AppLocalizations.of(context)?.cancel ?? 'Cancel selection',
              ),
              title: Text('${AppLocalizations.of(context)?.selected ?? 'Selected'} ($selectedCount)'),
              actions: [
                // Select all button
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () {
                    // Select all visible items
                    final contents = contentProvider.contents;
                    for (final content in contents) {
                      contentProvider.toggleContentSelection(content.id);
                    }
                  },
                  tooltip: AppLocalizations.of(context)?.selectAll ?? 'Select all',
                ),
                // Export to CSV button
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _exportSelectedCertificatesToCSV(context, contentProvider),
                  tooltip: AppLocalizations.of(context)?.exportToCSV ?? 'Export to CSV',
                ),
                // Update tags button
                IconButton(
                  icon: const Icon(Icons.tag),
                  onPressed: () => _updateTagsForSelectedContents(context),
                  tooltip: AppLocalizations.of(context)?.updateTags ?? 'Update tags',
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteMultipleContents(context, contentProvider),
                  tooltip: AppLocalizations.of(context)?.deleteSelected ?? 'Delete selected',
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          // Tag filters section
          if (contentProvider.selectedTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Text(
                      AppLocalizations.of(context)?.activeTags ?? 'Active Tags:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                      onPressed: () => contentProvider.setSelectedTags([]),
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: Text(AppLocalizations.of(context)?.clearFilters ?? 'Clear'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                  ),
                ],
              ),
            ),
          
          // No certificates message
          if (contentProvider.contents.isEmpty && contentProvider.selectedTags.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.noCertificatesFound ?? 'No certificates found',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)?.tryRemovingFilters ?? 'Try removing some tag filters',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => contentProvider.setSelectedTags([]),
                      icon: const Icon(Icons.filter_list_off),
                      label: Text(AppLocalizations.of(context)?.clearFilters ?? 'Clear all filters'),
                    ),
                  ],
                ),
              ),
            ),
          
          // Main content with pagination
          Consumer<ContentProvider>(
            builder: (context, provider, child) {
              final contents = provider.contents;
              
              return Expanded(
                child: Column(
                  children: [
                    // Pagination info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)?.showing ?? 'Showing'} ${contents.isEmpty ? 0 : (provider.currentPage * provider.pageSize) + 1}-${(provider.currentPage * provider.pageSize) + contents.length} ${AppLocalizations.of(context)?.ofTotal ?? 'of'} ${provider.totalItemCount}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Page size dropdown
                              DropdownButton<int>(
                                value: provider.pageSize,
                                isDense: true,
                                underline: Container(),
                                items: [10, 20, 50, 100].map((size) => 
                                  DropdownMenuItem<int>(
                                    value: size,
                                    child: Text('$size ${AppLocalizations.of(context)?.perPage ?? 'per page'}'),
                                  )
                                ).toList(),
                                onChanged: (value) {
                                  if (value != null) provider.setPageSize(value);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Certificate list
                    Expanded(
                      child: ListView.builder(
                        itemCount: contents.length,
                        // Add padding at bottom to avoid FAB overlapping with last item's action buttons
                        padding: const EdgeInsets.only(bottom: 80), // Generous padding to account for FAB height + some extra space
                        itemBuilder: (context, index) {
                          final content = contents[index];
                          final id = content.id;
                          final isSelected = contentProvider.selectedContentIds.contains(content.id);
                    
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                            elevation: isSelected ? 2 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: isSelected
                                  ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)
                                  : BorderSide.none,
                            ),
                            child: InkWell(
                              onTap: contentProvider.isMultiSelectMode
                                  ? () => contentProvider.toggleContentSelection(content.id)
                                  : () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ContentDetailsScreen(content: content),
                                        ),
                                      ),
                              onLongPress: () {
                                if (!contentProvider.isMultiSelectMode) {
                                  contentProvider.toggleMultiSelectMode();
                                  contentProvider.toggleContentSelection(content.id);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  children: [
                                    // Checkbox or Avatar
                                    if (contentProvider.isMultiSelectMode)
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (value) {
                                          contentProvider.toggleContentSelection(content.id);
                                        },
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: CircleAvatar(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          child: const Icon(Icons.description, color: Colors.white),
                                        ),
                                      ),
                              
                                    // Content info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                           // Title row with verification icon
                                           Row(
                                             textDirection: Directionality.of(context),
                                             children: [
                                               // Always show badge before the title in all languages
                                               if (content.rps > 0)
                                                 Padding(
                                                   padding: const EdgeInsets.only(right: 8.0),
                                                   child: Icon(
                                                     Icons.verified,
                                                     size: 16,
                                                     color: Colors.blue.shade700,
                                                   ),
                                                 ),
                                               Expanded(
                                                 child: Text(
                                                   content.name,
                                                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                   textAlign: Directionality.of(context) == TextDirection.rtl 
                                                     ? TextAlign.right 
                                                     : TextAlign.left,
                                                 ),
                                               ),
                                             ],
                                           ),
                                          
                                          // Description
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                            child: Text(
                                              content.description,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(color: Colors.grey[700]),
                                            ),
                                          ),
                                          
                                          // Read more link if needed
                                          if (content.description.split('\n').length > 2 ||
                                              content.description.length > 100)
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ContentDetailsScreen(content: content),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                'Read more...',
                                                style: TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            
                                          // Tags section
                                          if (contentProvider.getContentTags(content).isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                children: contentProvider.getContentTags(content)
                                                  .map((tag) {
                                                    // Check if this tag is in the selected filters
                                                    final isTagSelected = contentProvider.selectedTags.contains(tag);
                                                    
                                                    return GestureDetector(
                                                      onTap: () => contentProvider.toggleTagFilter(tag),
                                                      child: Chip(
                                                        label: Text(
                                                          tag,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: isTagSelected ? Colors.white : null,
                                                            fontWeight: isTagSelected ? FontWeight.bold : FontWeight.normal,
                                                          ),
                                                        ),
                                                        visualDensity: VisualDensity.compact,
                                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        padding: EdgeInsets.zero,
                                                        backgroundColor: isTagSelected
                                                          ? Theme.of(context).colorScheme.primary
                                                          : Theme.of(context).primaryColor.withOpacity(0.1),
                                                      ),
                                                    );
                                                  })
                                                  .toList(),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Action buttons
                                    if (!contentProvider.isMultiSelectMode)
                                      Container(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        decoration: BoxDecoration(
                                          border: Border(left: BorderSide(color: Colors.grey.shade200, width: 1)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.qr_code),
                                              onPressed: () => _showQRCode(context, content),
                                              tooltip: AppLocalizations.of(context)?.share ?? 'Share',
                                              iconSize: 24,
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.account_box_outlined),
                                              onPressed: () => _showProfileDialog(context, content.contentHash),
                                              tooltip: AppLocalizations.of(context)?.view ?? 'View',
                                              iconSize: 24,
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline),
                                              onPressed: () => _deleteContent(context, content.id),
                                              tooltip: AppLocalizations.of(context)?.delete ?? 'Delete',
                                              iconSize: 24,
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              color: Colors.redAccent,
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Pagination controls
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.first_page),
                            onPressed: provider.currentPage > 0 ? () => provider.goToPage(0) : null,
                            tooltip: AppLocalizations.of(context)?.firstPage ?? 'First page',
                          ),
                          IconButton(
                            icon: const Icon(Icons.navigate_before),
                            onPressed: provider.currentPage > 0 ? () => provider.loadPreviousPage() : null,
                            tooltip: AppLocalizations.of(context)?.previousPage ?? 'Previous page',
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 40),
                            child: Text(
                              '${provider.currentPage + 1}/${provider.totalPages}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.navigate_next),
                            onPressed: provider.hasMoreItems ? () => provider.loadNextPage() : null,
                            tooltip: AppLocalizations.of(context)?.nextPage ?? 'Next page',
                          ),
                          IconButton(
                            icon: const Icon(Icons.last_page),
                            onPressed: provider.hasMoreItems ? () => provider.goToPage(provider.totalPages - 1) : null,
                            tooltip: AppLocalizations.of(context)?.lastPage ?? 'Last page',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
