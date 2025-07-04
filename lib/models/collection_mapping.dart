import 'dart:convert';

class CollectionMapping {
  final String contentId;
  final String collectionId;
  final DateTime addedAt;

  CollectionMapping({
    required this.contentId,
    required this.collectionId,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'contentId': contentId,
    'collectionId': collectionId,
    'addedAt': addedAt.toIso8601String(),
  };

  factory CollectionMapping.fromJson(Map<String, dynamic> json) => CollectionMapping(
    contentId: json['contentId'],
    collectionId: json['collectionId'],
    addedAt: DateTime.parse(json['addedAt']),
  );

  @override
  String toString() => 'CollectionMapping(contentId: $contentId, collectionId: $collectionId)';
}
