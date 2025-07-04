import 'package:flutter/foundation.dart';
import '../models/collection.dart';
import '../services/collection_service.dart';

class CollectionProvider with ChangeNotifier {
  final CollectionService _service;
  List<Collection> _collections = [];
  bool _loading = false;
  String? _error;
  String _searchQuery = '';
  bool _showHidden = false;

  CollectionProvider(this._service) {
    _loadCollections();
  }

  List<Collection> get collections {
    var filtered = _collections;
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) => 
        c.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Filter hidden collections
    if (!_showHidden) {
      filtered = filtered.where((c) => !c.hidden).toList();
    }

    // Sort by name
    filtered.sort((a, b) => a.name.compareTo(b.name));
    
    return filtered;
  }

  bool get loading => _loading;
  String? get error => _error;
  bool get showHidden => _showHidden;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleShowHidden() {
    _showHidden = !_showHidden;
    notifyListeners();
  }

  Future<void> _loadCollections() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _collections = await _service.getCollections();
    } catch (e) {
      _error = 'Failed to load collections: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createCollection(String name) async {
    _error = null;
    notifyListeners();

    try {
      await _service.createCollection(name);
      await _loadCollections();
    } catch (e) {
      _error = 'Failed to create collection: $e';
      notifyListeners();
    }
  }

  Future<void> updateCollection(Collection collection) async {
    _error = null;
    notifyListeners();

    try {
      await _service.updateCollection(collection);
      await _loadCollections();
    } catch (e) {
      _error = 'Failed to update collection: $e';
      notifyListeners();
    }
  }

  Future<void> deleteCollection(String collectionId) async {
    _error = null;
    notifyListeners();

    try {
      await _service.deleteCollection(collectionId);
      await _loadCollections();
    } catch (e) {
      _error = 'Failed to delete collection: $e';
      notifyListeners();
    }
  }

  Future<void> toggleCollectionVisibility(Collection collection) async {
    try {
      final updated = collection.copyWith(hidden: !collection.hidden);
      await updateCollection(updated);
    } catch (e) {
      _error = 'Failed to toggle collection visibility: $e';
      notifyListeners();
    }
  }

  Future<void> addContentToCollection(String contentId, String collectionId) async {
    _error = null;
    notifyListeners();

    try {
      await _service.addContentToCollection(contentId, collectionId);
    } catch (e) {
      _error = 'Failed to add content to collection: $e';
      notifyListeners();
    }
  }

  Future<void> removeContentFromCollection(String contentId, String collectionId) async {
    _error = null;
    notifyListeners();

    try {
      await _service.removeContentFromCollection(contentId, collectionId);
    } catch (e) {
      _error = 'Failed to remove content from collection: $e';
      notifyListeners();
    }
  }

  Future<List<String>> getContentIdsInCollection(String collectionId) async {
    try {
      return await _service.getContentIdsInCollection(collectionId);
    } catch (e) {
      _error = 'Failed to get collection contents: $e';
      notifyListeners();
      return [];
    }
  }

  Future<String?> getCollectionForContent(String contentId) async {
    try {
      return await _service.getCollectionForContent(contentId);
    } catch (e) {
      _error = 'Failed to get content collection: $e';
      notifyListeners();
      return null;
    }
  }
}
