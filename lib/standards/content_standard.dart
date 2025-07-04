import 'dart:io';
import '../models/content_part.dart';

abstract class ContentStandard {
  String get name;
  String get version;
  
  Future<String> computeHash(Map<String, dynamic> standardData, List<ContentPart> parts);
  Future<Map<String, dynamic>> validateData(Map<String, dynamic> standardData, List<File> files);
  Map<String, dynamic> getRequiredFields();
}
