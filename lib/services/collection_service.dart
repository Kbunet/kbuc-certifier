import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/collection.dart';
import '../models/collection_mapping.dart';
import '../models/content_part.dart';

class CollectionService {
  static const String _collectionsFileName = 'collections.json';
  static const String _mappingsFileName = 'collection_mappings.json';
  final _uuid = const Uuid();

  // In-memory cache
  List<Collection>? _collections;
  List<CollectionMapping>? _mappings;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _collectionsFile async {
    final path = await _localPath;
    return File('$path/$_collectionsFileName');
  }

  Future<File> get _mappingsFile async {
    final path = await _localPath;
    return File('$path/$_mappingsFileName');
  }

  Future<List<Collection>> getCollections() async {
    if (_collections != null) {
      return _collections!;
    }

    try {
      final file = await _collectionsFile;
      if (!await file.exists()) {
        _collections = [];
        return [];
      }

      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      _collections = jsonList.map((json) => Collection.fromJson(json)).toList();
      return _collections!;
    } catch (e) {
      print('Error loading collections: $e');
      _collections = [];
      return [];
    }
  }

  Future<List<CollectionMapping>> getMappings() async {
    if (_mappings != null) {
      return _mappings!;
    }

    try {
      final file = await _mappingsFile;
      if (!await file.exists()) {
        _mappings = [];
        return [];
      }

      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      _mappings = jsonList.map((json) => CollectionMapping.fromJson(json)).toList();
      return _mappings!;
    } catch (e) {
      print('Error loading collection mappings: $e');
      _mappings = [];
      return [];
    }
  }

  Future<Collection> createCollection(String name) async {
    final collections = await getCollections();
    
    final collection = Collection(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    collections.add(collection);
    await _saveCollections(collections);
    return collection;
  }

  Future<void> updateCollection(Collection collection) async {
    final collections = await getCollections();
    final index = collections.indexWhere((c) => c.id == collection.id);
    
    if (index == -1) {
      throw Exception('Collection not found');
    }

    collections[index] = collection.copyWith(
      updatedAt: DateTime.now(),
    );

    await _saveCollections(collections);
  }

  Future<void> deleteCollection(String collectionId) async {
    final collections = await getCollections();
    collections.removeWhere((c) => c.id == collectionId);
    await _saveCollections(collections);

    // Remove all mappings for this collection
    final mappings = await getMappings();
    mappings.removeWhere((m) => m.collectionId == collectionId);
    await _saveMappings(mappings);
  }

  Future<void> addContentToCollection(String contentId, String collectionId) async {
    final mappings = await getMappings();
    
    // Remove existing mapping if any
    mappings.removeWhere((m) => m.contentId == contentId);

    // Add new mapping
    mappings.add(CollectionMapping(
      contentId: contentId,
      collectionId: collectionId,
      addedAt: DateTime.now(),
    ));

    await _saveMappings(mappings);
  }

  Future<void> removeContentFromCollection(String contentId, String collectionId) async {
    final mappings = await getMappings();
    mappings.removeWhere((m) => 
      m.contentId == contentId && m.collectionId == collectionId);
    await _saveMappings(mappings);
  }

  Future<List<String>> getContentIdsInCollection(String collectionId) async {
    final mappings = await getMappings();
    return mappings
      .where((m) => m.collectionId == collectionId)
      .map((m) => m.contentId)
      .toList();
  }

  Future<String?> getCollectionForContent(String contentId) async {
    final mappings = await getMappings();
    final mapping = mappings.firstWhere(
      (m) => m.contentId == contentId,
      orElse: () => CollectionMapping(
        contentId: '', 
        collectionId: '', 
        addedAt: DateTime.now(),
      ),
    );
    return mapping.contentId.isEmpty ? null : mapping.collectionId;
  }

  Future<void> _saveCollections(List<Collection> collections) async {
    final file = await _collectionsFile;
    final data = collections.map((c) => c.toJson()).toList();
    await file.writeAsString(json.encode(data));
    _collections = collections;
  }

  Future<void> _saveMappings(List<CollectionMapping> mappings) async {
    final file = await _mappingsFile;
    final data = mappings.map((m) => m.toJson()).toList();
    await file.writeAsString(json.encode(data));
    _mappings = mappings;
  }
}
