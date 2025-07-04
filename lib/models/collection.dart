import 'dart:convert';

class Collection {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hidden;

  Collection({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.hidden = false,
  });

  Collection copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hidden,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hidden: hidden ?? this.hidden,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'hidden': hidden,
  };

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
    id: json['id'],
    name: json['name'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    hidden: json['hidden'] ?? false,
  );

  @override
  String toString() => 'Collection(id: $id, name: $name)';
}
