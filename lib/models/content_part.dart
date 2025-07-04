import 'package:json_annotation/json_annotation.dart';

part 'content_part.g.dart';

@JsonSerializable()
class ContentPart {
  final String id;
  final String name;
  final String hash;
  final String mimeType;
  final int size;

  ContentPart({
    required this.id,
    required this.name,
    required this.hash,
    required this.mimeType,
    required this.size,
  });

  factory ContentPart.fromJson(Map<String, dynamic> json) =>
      _$ContentPartFromJson(json);

  Map<String, dynamic> toJson() => _$ContentPartToJson(this);
}

@JsonSerializable()
class PortableContent {
  final String id;
  final String name;
  final String description;
  final String standardName;
  final String standardVersion;
  final Map<String, dynamic> standardData;
  String contentHash;
  final List<ContentPart> parts;
  final DateTime createdAt;
  final DateTime updatedAt;
  String owner = "";
  String creator = "";
  int rps = 0;
  List<String> tags = [];

  PortableContent({
    required this.id,
    required this.name,
    required this.description,
    required this.standardName,
    required this.standardVersion,
    required this.standardData,
    required this.contentHash,
    required this.parts,
    required this.createdAt,
    required this.updatedAt,
    this.owner = "",
    this.creator = "",
    this.rps = 0,
    this.tags = const [],
  });

  factory PortableContent.fromJson(Map<String, dynamic> json) =>
      _$PortableContentFromJson(json);

  Map<String, dynamic> toJson() => _$PortableContentToJson(this);
}
