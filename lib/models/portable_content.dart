import 'dart:io';

class PortableContent {
  final String id;
  final String name;
  final String description;
  final String contentHash;
  final int createdAt;
  final File imageFile;
  final String owner;
  final int rps;
  final String standardName;
  final String standardVersion;
  final Map<String, dynamic> standardData;

  PortableContent({
    required this.id,
    required this.name,
    required this.description,
    required this.contentHash,
    required this.createdAt,
    required this.imageFile,
    required this.standardName,
    required this.standardVersion,
    required this.standardData,
    this.owner = "",
    this.rps = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'contentHash': contentHash,
      'createdAt': createdAt,
      'imagePath': imageFile.path,
      'owner': owner,
      'rps': rps,
      'standardName': standardName,
      'standardVersion': standardVersion,
      'standardData': standardData,
    };
  }

  factory PortableContent.fromJson(Map<String, dynamic> json) {
    print('\n=== PortableContent.fromJson ===');
    print('Input JSON: $json');
    print('JSON type: ${json.runtimeType}');
    
    // Log each field type and value
    print('\nField types and values:');
    print('id: ${json['id']} (${json['id']?.runtimeType})');
    print('name: ${json['name']} (${json['name']?.runtimeType})');
    print('description: ${json['description']} (${json['description']?.runtimeType})');
    print('contentHash: ${json['contentHash']} (${json['contentHash']?.runtimeType})');
    print('createdAt: ${json['createdAt']} (${json['createdAt']?.runtimeType})');
    print('imagePath: ${json['imagePath']} (${json['imagePath']?.runtimeType})');
    print('mediaPath: ${json['mediaPath']} (${json['mediaPath']?.runtimeType})');
    print('owner: ${json['owner']} (${json['owner']?.runtimeType})');
    print('rps: ${json['rps']} (${json['rps']?.runtimeType})');
    print('standardName: ${json['standardName']} (${json['standardName']?.runtimeType})');
    print('standardVersion: ${json['standardVersion']} (${json['standardVersion']?.runtimeType})');
    print('standardData: ${json['standardData']} (${json['standardData']?.runtimeType})');
    
    try {
      // Handle the case where imagePath might be called mediaPath
      final imagePath = json['imagePath'] ?? json['mediaPath'] ?? '';
      print('\nResolved imagePath: $imagePath');

      // For backward compatibility, if standardData is not present, create it from mediaPath
      Map<String, dynamic> standardData;
      if (json['standardData'] != null) {
        standardData = Map<String, dynamic>.from(json['standardData']);
        // Ensure mediaPath exists and is a string
        standardData['mediaPath'] = standardData['mediaPath']?.toString() ?? imagePath;
      } else {
        standardData = {
          'mediaPath': imagePath,
          'mediaType': 'image',
          'mediaChecksum': json['mediaChecksum']?.toString() ?? '',
        };
      }
      
      return PortableContent(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        contentHash: json['contentHash'] as String,
        createdAt: json['createdAt'] as int,
        imageFile: File(imagePath),
        standardName: json['standardName'] as String? ?? 'W3-CERT-HASH', // Default to certificate standard
        standardVersion: json['standardVersion'] as String? ?? '1.0.0',
        standardData: standardData,
        owner: (json['owner'] as String?) ?? "",
        rps: (json['rps'] as int?) ?? 0,
      );
    } catch (e, stackTrace) {
      print('\nError creating PortableContent:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'PortableContent(id: $id, name: $name, description: $description, contentHash: $contentHash, createdAt: $createdAt, owner: $owner, rps: $rps)';
  }
}
