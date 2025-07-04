import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/content_part.dart';
import '../services/content_service.dart';
import '../services/electrum_service.dart';
import '../widgets/standard_content_form_dialog.dart';
import 'package:permission_handler/permission_handler.dart';

class ContentProvider with ChangeNotifier {
  final _service = ContentService();
  final _electrumService = ElectrumService();
  List<PortableContent> _contents = [];
  PortableContent? _currentContent;
  List<File>? _currentFiles;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedStandard;
  bool _showRegisteredOnly = false;
  List<String> _selectedTags = [];
  bool _useAndFilterLogic = false; // Default to OR logic for tag filtering
  bool _includeContentInTagFilter = true; // Include content text when filtering by tags
  
  // For multi-select functionality
  final Set<String> _selectedContentIds = <String>{};
  bool _isMultiSelectMode = false;
  
  // For pagination
  int _pageSize = 20; // Number of items per page
  int _currentPage = 0; // Current page index (0-based)
  bool _hasMoreItems = true; // Flag to indicate if more items are available

  ContentProvider() {
    initialize();
  }

  Future<void> initialize() async {
    print('\nInitializing ContentProvider...');
    _setLoading(true);

    try {
      await _service.initialize();
      _contents = _service.getAllContents();
      print('Loaded ${_contents.length} contents');
      notifyListeners();
    } catch (e) {
      print('Error initializing ContentProvider: $e');
      _setError('Failed to load contents: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    print('\nRefreshing contents...');
    await initialize();
  }

  // Get filtered contents without pagination (used for total count and operations on all items)
  List<PortableContent> get _filteredContents {
    var filteredContents = _contents;
    
    // Apply standard filter if selected
    if (_selectedStandard != null) {
      filteredContents = filteredContents.where(
        (content) => content.standardName == _selectedStandard
      ).toList();
    }

    // Apply unified filter (tags and/or content)
    if (_selectedTags.isNotEmpty || _searchQuery.isNotEmpty) {
      filteredContents = filteredContents.where((content) {
        // Get tags from standardData
        List<String> contentTags = getContentTags(content);
        
        // Check if content matches search query
        bool matchesQuery = false;
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          matchesQuery = content.name.toLowerCase().contains(query) ||
              content.contentHash.toLowerCase().contains(query) ||
              content.standardName.toLowerCase().contains(query) ||
              content.description.toLowerCase().contains(query);
        }
        
        // Check if content matches tag filters
        bool matchesTags = false;
        if (_selectedTags.isNotEmpty) {
          if (_useAndFilterLogic) {
            // AND logic - content must contain ALL selected tags
            matchesTags = _selectedTags.every((tag) => contentTags.contains(tag));
          } else {
            // OR logic - content must contain ANY selected tag
            matchesTags = _selectedTags.any((tag) => contentTags.contains(tag));
          }
        }
        
        // Determine if content passes the filter
        if (_searchQuery.isEmpty) {
          // Only tag filtering is active
          return matchesTags;
        } else if (_selectedTags.isEmpty) {
          // Only content filtering is active
          return matchesQuery;
        } else {
          // Both filters are active - include content in tag filter if enabled
          return _includeContentInTagFilter ? (matchesTags || matchesQuery) : (matchesTags && matchesQuery);
        }
      }).toList();
    }

    // Apply registered filter if enabled
    if (_showRegisteredOnly) {
      filteredContents = filteredContents.where((content) => content.rps > 0).toList();
    }

    // Sort by creation date (newest first)
    filteredContents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return filteredContents;
  }
  
  // Get paginated contents for display
  List<PortableContent> get contents {
    final filteredContents = _filteredContents;
    
    // Calculate start and end indices for pagination
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;
    
    // Update hasMoreItems flag
    _hasMoreItems = endIndex < filteredContents.length;
    
    // Return the current page of items
    if (startIndex >= filteredContents.length) {
      return []; // Return empty list if we're past the end
    }
    
    return filteredContents.sublist(
      startIndex, 
      endIndex > filteredContents.length ? filteredContents.length : endIndex
    );
  }
  
  // Get the total number of items after filtering
  int get totalItemCount => _filteredContents.length;
  
  // Get the total number of pages
  int get totalPages => (_filteredContents.length / _pageSize).ceil();
  
  // Check if there are more items to load
  bool get hasMoreItems => _hasMoreItems;
  
  // Get current page index (0-based)
  int get currentPage => _currentPage;
  
  int get pageSize => _pageSize;
  
  // Set page size
  void setPageSize(int size) {
    if (size > 0 && size != _pageSize) {
      _pageSize = size;
      notifyListeners();
    }
  }
  
  // Load next page
  void loadNextPage() {
    if (_hasMoreItems) {
      _currentPage++;
      notifyListeners();
    }
  }
  
  // Load previous page
  void loadPreviousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }
  
  // Go to specific page
  void goToPage(int page) {
    if (page >= 0 && page < totalPages && page != _currentPage) {
      _currentPage = page;
      notifyListeners();
    }
  }

  List<String> get availableStandards {
    return _contents
        .map((content) => content.standardName)
        .toSet()
        .toList()
      ..sort();
  }
  
  // Get all unique tags from all content
  List<String> get availableTags {
    final allTags = <String>{};
    
    for (final content in _contents) {
      final contentTags = getContentTags(content);
      allTags.addAll(contentTags);
    }
    
    final tagsList = allTags.toList();
    tagsList.sort();
    return tagsList;
  }
  
  // Extract tags from a content item
  List<String> getContentTags(PortableContent content) {
    // Try to get tags from standardData
    if (content.standardData.containsKey('tags')) {
      final tags = content.standardData['tags'];
      
      if (tags is List) {
        // If already a list, convert any non-string elements to strings
        return tags.map((tag) => tag.toString()).toList();
      } else if (tags is String) {
        // If a comma-separated string, split and trim
        return tags
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
      }
    }
    
    return [];
  }

  PortableContent? get currentContent => _currentContent;
  List<File>? get currentFiles => _currentFiles;
  String? get selectedStandard => _selectedStandard;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get showRegisteredOnly => _showRegisteredOnly;
  List<String> get selectedTags => _selectedTags;
  bool get useAndFilterLogic => _useAndFilterLogic;
  
  // Getters for multi-select functionality
  bool get isMultiSelectMode => _isMultiSelectMode;
  Set<String> get selectedContentIds => _selectedContentIds;
  int get selectedCount => _selectedContentIds.length;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void setSelectedStandard(String? standard) {
    _selectedStandard = standard;
    notifyListeners();
  }
  
  void setSelectedTags(List<String> tags) {
    _selectedTags = tags;
    notifyListeners();
  }
  
  void addTagFilter(String tag) {
    if (!_selectedTags.contains(tag)) {
      _selectedTags.add(tag);
      notifyListeners();
    }
  }
  
  void removeTagFilter(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
      notifyListeners();
    }
  }
  
  void toggleTagFilter(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    notifyListeners();
  }

  void setShowRegisteredOnly(bool value) {
    _showRegisteredOnly = value;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedStandard = null;
    _showRegisteredOnly = false;
    _selectedTags = [];
    // Don't reset includeContentInTagFilter when clearing filters
    notifyListeners();
  }
  
  void toggleIncludeContentInTagFilter() {
    _includeContentInTagFilter = !_includeContentInTagFilter;
    notifyListeners();
  }
  
  // Get whether content text is included in tag filtering
  bool get includeContentInTagFilter => _includeContentInTagFilter;
  
  // Check if any filters are active
  bool get hasActiveFilters => _searchQuery.isNotEmpty || _selectedStandard != null || _showRegisteredOnly || _selectedTags.isNotEmpty;
  
  /// Toggle between AND/OR logic for tag filtering
  void toggleTagFilterLogic() {
    _useAndFilterLogic = !_useAndFilterLogic;
    notifyListeners();
  }
  
  /// Set specific filter logic mode
  void setTagFilterLogic(bool useAndLogic) {
    if (_useAndFilterLogic != useAndLogic) {
      _useAndFilterLogic = useAndLogic;
      notifyListeners();
    }
  }

  void selectContent(String id) {
    print('\nSelecting content: $id');
    final contentData = _service.getContent(id);
    if (contentData != null) {
      _currentContent = contentData.$1;
      _currentFiles = contentData.$2;
      print('Selected content: ${_currentContent!.name}');
      print('Number of files: ${_currentFiles!.length}');
      
      // We'll fetch the creator profile only when explicitly requested
      // instead of automatically when selecting content
      
      notifyListeners();
    } else {
      print('Content not found: $id');
    }
  }

  /// Creates a new content entry by showing a dialog to collect data
  Future<void> createContent(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const StandardContentFormDialog(),
    );

    if (result != null) {
      try {
        _isLoading = true;
        notifyListeners();

        final standardName = result['standard'] as String; // Will always be 'W3-CERT-HASH'
        // Certificate standard doesn't use media files
        final files = <File>[]; 

        final standardData = Map<String, dynamic>.from(result)
          ..remove('standard'); // Certificate standard doesn't use mediaFile

        print('Initial standardData: $standardData');

        // Create the content
        final content = await _service.createContent(
          name: standardData['name'],
          description: standardData['description'],
          standardName: standardName,
          standardVersion: '1.0.0',
          standardData: standardData,
          files: files,
        );

        _contents.add(content);
        notifyListeners();
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        rethrow;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
  
  /// Creates content directly from provided data without showing a dialog
  /// Used for batch certificate creation from CSV
  Future<void> createContentDirect({
    required String name,
    required String description,
    required String standardName,
    required String standardVersion,
    required Map<String, dynamic> standardData,
    required List<File> files,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Creating content directly with data: $standardData');

      // Create the content
      final content = await _service.createContent(
        name: name,
        description: description,
        standardName: standardName,
        standardVersion: standardVersion,
        standardData: standardData,
        files: files,
      );

      _contents.add(content);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> importContent() async {
    _error = null;
    _setLoading(true);

    try {
      // Show file picker for .pcontent file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Use any type to avoid extension filtering issues
        withData: true, // Ensure we get the file data on all platforms
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final filePath = result.files.first.path!;
      if (!filePath.toLowerCase().endsWith('.pcontent')) {
        throw Exception('Please select a .pcontent file');
      }

      final file = File(filePath);
      final importResult = await _service.importContent(file);
      _currentContent = importResult.$1;
      _currentFiles = importResult.$2;
      _contents = _service.getAllContents();
      notifyListeners();
    } catch (e) {
      _setError('Failed to import content: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<File> exportContent(String? contentId, {File? targetFile}) async {
    try {
      final content = contentId != null 
          ? contents.firstWhere((c) => c.id == contentId)
          : _currentContent!;
          
      if (content == null) {
        throw Exception('No content selected for export');
      }

      final file = targetFile ?? await _createExportFile(content);
      await _service.exportContent(content, file);
      return file;
    } catch (e) {
      rethrow;
    }
  }

  Future<File> _createExportFile(PortableContent content) async {
    final exportDir = await getExportDirectory();
    // Directory is already created in getExportDirectory
    final fileName = '${content.name.replaceAll(' ', '_')}.pcontent';
    return File(path.join(exportDir.path, fileName));
  }

  /// Returns the application's dedicated export directory
  /// This will create a 'KbucCertifier' folder in the user's Documents directory
  Future<Directory> getExportDirectory() async {
    try {
      // App-specific export directory name
      const String appDirName = 'KbucCertifier';
      
      if (Platform.isAndroid) {
        // Request storage permissions on Android
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission is required to export content');
        }
        
        // Get the Downloads directory using getExternalStorageDirectory
        final baseDir = await getExternalStorageDirectory();
        if (baseDir == null) {
          throw Exception('Could not access external storage');
        }
        
        // Navigate up to find the root external storage
        String? documentsPath;
        List<String> paths = baseDir.path.split('/');
        int index = paths.indexOf('Android');
        if (index > 0) {
          // Create app directory in Downloads folder
          documentsPath = paths.sublist(0, index).join('/') + '/Download/$appDirName';
        } else {
          // Fallback if we can't find the Android directory
          documentsPath = baseDir.path + '/Download/$appDirName';
        }
        
        final appDir = Directory(documentsPath);
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }
        return appDir;
      } else if (Platform.isIOS) {
        // For iOS, use the Documents directory
        final directory = await getApplicationDocumentsDirectory();
        final appDir = Directory('${directory.path}/$appDirName');
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }
        return appDir;
      } else {
        // For desktop platforms (Windows, macOS, Linux)
        // Get the user's Documents directory
        Directory? documentsDir;
        
        try {
          // Try to get the system's Documents directory
          if (Platform.isWindows) {
            // On Windows, typically C:\Users\Username\Documents
            final userProfile = Platform.environment['USERPROFILE'];
            if (userProfile != null) {
              documentsDir = Directory('$userProfile\\Documents\\$appDirName');
            }
          } else if (Platform.isMacOS) {
            // On macOS, typically /Users/Username/Documents
            final home = Platform.environment['HOME'];
            if (home != null) {
              documentsDir = Directory('$home/Documents/$appDirName');
            }
          } else if (Platform.isLinux) {
            // On Linux, typically /home/username/Documents
            final home = Platform.environment['HOME'];
            if (home != null) {
              documentsDir = Directory('$home/Documents/$appDirName');
            }
          }
          
          // Create the directory if it doesn't exist
          if (documentsDir != null && !await documentsDir.exists()) {
            await documentsDir.create(recursive: true);
          }
        } catch (e) {
          // If we can't access the Documents directory, fall back to app directory
          print('Failed to access Documents directory: $e');
          documentsDir = null;
        }
        
        // If we couldn't get the Documents directory, fall back to app directory
        if (documentsDir == null) {
          final appDocsDir = await getApplicationDocumentsDirectory();
          documentsDir = Directory('${appDocsDir.path}/$appDirName');
          if (!await documentsDir.exists()) {
            await documentsDir.create(recursive: true);
          }
        }
        
        return documentsDir;
      }
    } catch (e) {
      print('Error creating export directory: $e');
      // Fallback to app documents directory if we can't create the custom directory
      final directory = await getApplicationDocumentsDirectory();
      final fallbackDir = Directory('${directory.path}/KbucCertifier');
      if (!await fallbackDir.exists()) {
        await fallbackDir.create(recursive: true);
      }
      return fallbackDir;
    }
  }

  Future<bool> verifyContent() async {
    print('\nStarting content verification...');
    if (_currentContent == null || _currentFiles == null) {
      print('No content to verify');
      _setError('No content to verify');
      return false;
    }

    _error = null;
    _setLoading(true);

    try {
      print('Verifying content: ${_currentContent!.name} (${_currentContent!.id})');
      print('Number of files: ${_currentFiles!.length}');
      final isValid = await _service.verifyContent(_currentContent!, _currentFiles!);
      if (!isValid) {
        print('Content verification failed');
        _setError('Content verification failed');
      } else {
        print('Content verification successful');
      }
      return isValid;
    } catch (e) {
      print('Error during verification: $e');
      _setError('Content verification failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteContent(String id) async {
    _error = null;
    _setLoading(true);

    try {
      await _service.deleteContent(id);
      if (_currentContent?.id == id) {
        _currentContent = null;
        _currentFiles = null;
      }
      _contents = _service.getAllContents();
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete content: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Deletes multiple certificates in batch
  Future<void> deleteMultipleContents(BuildContext context) async {
    if (_selectedContentIds.isEmpty) return;
    
    // Confirm delete with a dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Certificates'),
        content: Text('Are you sure you want to delete ${_selectedContentIds.length} selected certificate(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    _error = null;
    _setLoading(true);
    
    int successCount = 0;
    int failCount = 0;
    List<String> failedIds = [];
    
    try {
      // Process each deletion individually to handle partial success
      for (final id in _selectedContentIds) {
        try {
          await _service.deleteContent(id);
          successCount++;
          
          if (_currentContent?.id == id) {
            _currentContent = null;
            _currentFiles = null;
          }
        } catch (e) {
          failCount++;
          failedIds.add(id);
          print('Error deleting content $id: $e');
        }
      }
      
      // Refresh contents list
      _contents = _service.getAllContents();
      
      // Clear selection after deletion attempt
      _selectedContentIds.clear();
      _isMultiSelectMode = false;
      
      // Show completion message
      String message;
      if (failCount > 0) {
        message = '$successCount certificates deleted, $failCount failed';
      } else {
        message = '$successCount certificates deleted successfully';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ));
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete contents: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Toggle multi-select mode
  void toggleMultiSelectMode() {
    _isMultiSelectMode = !_isMultiSelectMode;
    if (!_isMultiSelectMode) {
      _selectedContentIds.clear();
    }
    notifyListeners();
  }
  
  /// Toggle selection of a specific content
  void toggleContentSelection(String contentId) {
    if (_selectedContentIds.contains(contentId)) {
      _selectedContentIds.remove(contentId);
      if (_selectedContentIds.isEmpty) {
        _isMultiSelectMode = false;
      }
    } else {
      _selectedContentIds.add(contentId);
      if (!_isMultiSelectMode) {
        _isMultiSelectMode = true;
      }
    }
    notifyListeners();
  }
  
  /// Clear all selections
  void clearSelection() {
    _selectedContentIds.clear();
    _isMultiSelectMode = false;
    notifyListeners();
  }
  
  /// Select all visible contents based on current filters
  void selectAllVisible() {
    final visibleContents = contents;
    for (final content in visibleContents) {
      _selectedContentIds.add(content.id);
    }
    if (visibleContents.isNotEmpty) {
      _isMultiSelectMode = true;
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Update tags for an existing certificate
  /// This won't affect the content hash since tags are not part of the hash computation
  Future<void> updateContentTags(String contentId, List<String> tags) async {
    _error = null;
    _setLoading(true);
    
    try {
      // Find the content to update
      final index = _contents.indexWhere((content) => content.id == contentId);
      if (index == -1) {
        throw Exception('Content not found');
      }
      
      final content = _contents[index];
      
      // Create a new standardData map with updated tags
      final updatedData = Map<String, dynamic>.from(content.standardData);
      
      // Update tags - store as comma-separated string for consistency
      updatedData['tags'] = tags.join(',');
      
      // Create updated content with new standardData
      final updatedContent = PortableContent(
        id: content.id,
        name: content.name,
        description: content.description,
        standardName: content.standardName,
        standardVersion: content.standardVersion,
        standardData: updatedData,
        contentHash: content.contentHash, // Hash doesn't change when just tags are updated
        parts: content.parts,
        createdAt: content.createdAt,
        updatedAt: DateTime.now(), // Update the timestamp
        owner: content.owner,
        creator: content.creator,
        rps: content.rps,
      );
      
      // Update in the content list
      _contents[index] = updatedContent;
      
      // Update current content if it's the one being modified
      if (_currentContent?.id == contentId) {
        _currentContent = updatedContent;
      }
      
      // Persist the changes
      await _service.updateContent(updatedContent);
      
      notifyListeners();
      return;
    } catch (e) {
      _setError('Failed to update tags: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Update tags for multiple certificates at once
  /// This won't affect the content hashes since tags are not part of the hash computation
  Future<void> updateMultipleContentTags(BuildContext context, List<String> tags) async {
    if (_selectedContentIds.isEmpty) return;
    
    // Confirm update with a dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Certificate Tags'),
        content: Text('Are you sure you want to update tags for ${_selectedContentIds.length} selected certificate(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    _error = null;
    _setLoading(true);
    
    int successCount = 0;
    int failCount = 0;
    List<String> failedIds = [];
    
    try {
      // Process each update individually to handle partial success
      for (final id in _selectedContentIds) {
        try {
          // Find the content to update
          final index = _contents.indexWhere((content) => content.id == id);
          if (index == -1) {
            failCount++;
            failedIds.add(id);
            continue;
          }
          
          final content = _contents[index];
          
          // Create a new standardData map with updated tags
          final updatedData = Map<String, dynamic>.from(content.standardData);
          
          // Update tags - store as comma-separated string for consistency
          updatedData['tags'] = tags.join(',');
          
          // Create updated content with new standardData
          final updatedContent = PortableContent(
            id: content.id,
            name: content.name,
            description: content.description,
            standardName: content.standardName,
            standardVersion: content.standardVersion,
            standardData: updatedData,
            contentHash: content.contentHash, // Hash doesn't change when just tags are updated
            parts: content.parts,
            createdAt: content.createdAt,
            updatedAt: DateTime.now(), // Update the timestamp
            owner: content.owner,
            creator: content.creator,
            rps: content.rps,
          );
          
          // Update in the content list
          _contents[index] = updatedContent;
          
          // Update current content if it's the one being modified
          if (_currentContent?.id == id) {
            _currentContent = updatedContent;
          }
          
          // Persist the changes
          await _service.updateContent(updatedContent);
          successCount++;
        } catch (e) {
          failCount++;
          failedIds.add(id);
          print('Error updating tags for content $id: $e');
        }
      }
      
      // Show completion message
      String message;
      if (failCount > 0) {
        message = 'Updated tags for $successCount certificates, $failCount failed';
      } else {
        message = 'Updated tags for $successCount certificates successfully';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ));
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to update tags: $e');
    } finally {
      _setLoading(false);
    }
  }

  void updateContentProfile(String contentId, String owner, int rps, {String? creator}) {
    final index = _contents.indexWhere((content) => content.id == contentId);
    if (index != -1) {
      final content = _contents[index];
      _contents[index] = PortableContent(
        id: content.id,
        name: content.name,
        description: content.description,
        standardName: content.standardName,
        standardVersion: content.standardVersion,
        standardData: content.standardData,
        contentHash: content.contentHash,
        parts: content.parts,
        createdAt: content.createdAt,
        updatedAt: content.updatedAt,
        owner: owner,
        creator: creator ?? content.creator,
        rps: rps,
      );
      if (_currentContent?.id == contentId) {
        _currentContent = _contents[index];
      }

      // Persist the changes
      _service.updateContent(_contents[index]);
      
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Export selected certificates to CSV format matching the import template
  /// with proper Unicode support for Arabic and other non-Latin characters
  Future<String> exportSelectedCertificatesToCSV() async {
    if (_selectedContentIds.isEmpty) {
      throw Exception('No certificates selected for export');
    }
    
    // Get selected certificates
    final selectedContents = _contents.where(
      (content) => _selectedContentIds.contains(content.id)
    ).toList();
    
    if (selectedContents.isEmpty) {
      throw Exception('No certificates found for export');
    }
    
    // Add UTF-8 BOM (Byte Order Mark) to ensure Excel and other apps recognize the encoding
    final bom = '\uFEFF'; // UTF-8 BOM character
    
    // Define the header row and data rows using the same format as the import template
    final List<List<dynamic>> csvData = [];
    
    // Header row with required and optional fields in the same order as the import template
    csvData.add(['type', 'recipient', 'issuer', 'description', 'date', 
                'duration', 'event', 'location', 'certificate_id', 'tags']);
    
    // Add data rows
    for (final content in selectedContents) {
      final data = content.standardData;
      final tags = data.containsKey('tags') ? _formatTagsForCSV(data['tags']) : '';
      
      // Add each field in the same order as the import template
      csvData.add([
        data['type'] ?? '',
        data['recipient'] ?? '',
        data['issuer'] ?? '',
        data['description'] ?? content.description, // Use content description as fallback
        data['date'] ?? '',
        data['duration'] ?? '',
        data['event'] ?? '',
        data['location'] ?? '',
        data['certificate_id'] ?? '',
        tags,
      ]);
    }
    
    // Convert to CSV string using the same converter as the import function
    final csvString = const ListToCsvConverter().convert(csvData);
    
    // Add BOM at the beginning of the string for proper Unicode handling
    return '$bom$csvString';
  }
  
  /// Format tags for CSV export
  String _formatTagsForCSV(dynamic tags) {
    if (tags == null) return '';
    
    if (tags is String) {
      return tags;
    } else if (tags is List) {
      return tags.join(',');
    }
    
    return '';
  }
  
  /// Escape a field for CSV format
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      // Escape quotes by doubling them and wrap in quotes
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
  
  /// Compute the hash for content without creating it
  /// Used for checking duplicates before importing certificates
  Future<String> computeContentHash({
    required String standardName,
    required String standardVersion,
    required Map<String, dynamic> standardData,
  }) async {
    // Get the standard
    final standard = _service.getStandard(standardName);
    if (standard == null) {
      throw Exception('Unknown standard: $standardName');
    }
    
    // Create a copy of standardData for validation
    final validatedData = Map<String, dynamic>.from(standardData);
    
    // Validate standard data
    final finalData = await standard.validateData(validatedData, []);
    
    // Compute content hash using the validated data
    final contentHash = await standard.computeHash(finalData, []);
    
    return contentHash;
  }
  
  /// Get all contents unfiltered
  List<PortableContent> getAllContents() {
    return List<PortableContent>.from(_contents);
  }
  
  Future<void> fetchCreatorProfile(String contentHash) async {
    if (_currentContent == null) return;
    
    try {
      print('Fetching creator profile for content hash: $contentHash');
      final profileData = await _electrumService.verifyProfile(contentHash);
      
      if (profileData.containsKey('creator') && profileData['creator'] is String) {
        final creator = profileData['creator'] as String;
        if (creator.isNotEmpty) {
          print('Found creator: $creator');
          updateContentProfile(
            _currentContent!.id, 
            _currentContent!.owner, 
            _currentContent!.rps,
            creator: creator
          );
        }
      }
    } catch (e) {
      print('Error fetching creator profile: $e');
      // Don't set error as this is a non-critical operation
    }
  }
  
  /// Get content by ID
  PortableContent? getContentById(String id) {
    try {
      return _contents.firstWhere((content) => content.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Update tags for selected contents
  void updateTagsForSelectedContents(List<String> tags) {
    if (_selectedContentIds.isEmpty) return;
    
    for (final id in _selectedContentIds) {
      final content = getContentById(id);
      if (content != null) {
        // Create a copy of the standardData with updated tags
        final Map<String, dynamic> standardData = Map.from(content.standardData);
        standardData['tags'] = tags;
        
        // Create a new PortableContent with updated standardData
        // Make sure to preserve all original properties including rps
        final updatedContent = PortableContent(
          id: content.id,
          name: content.name,
          description: content.description,
          standardName: content.standardName,
          standardVersion: content.standardVersion,
          standardData: standardData,
          contentHash: content.contentHash,
          parts: content.parts,
          createdAt: content.createdAt,
          updatedAt: DateTime.now(),
          owner: content.owner,
          rps: content.rps, // Preserve the rps value for the verification badge
          creator: content.creator,
          tags: tags, // Also update the tags field directly
        );
        
        // Update content with new tags
        _service.updateContent(updatedContent);
      }
    }
    
    // Refresh contents
    refresh();
  }
  
  /// Update certificate with blockchain profile data
  void updateCertificate(PortableContent updatedContent) {
    try {
      // Update the content in the service
      _service.updateContent(updatedContent);
      
      // Update the content in the local list
      final index = _contents.indexWhere((content) => content.id == updatedContent.id);
      if (index != -1) {
        _contents[index] = updatedContent;
      }
      
      // Notify listeners to update the UI
      notifyListeners();
    } catch (e) {
      print('Error updating certificate: $e');
      _setError('Failed to update certificate: $e');
    }
  }
}
