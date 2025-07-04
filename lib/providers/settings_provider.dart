import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NodeSettings {
  final String host;
  final int port;
  final String username;
  final String password;

  NodeSettings({
    required this.host,
    required this.port,
    this.username = '',
    this.password = '',
  });

  factory NodeSettings.defaults() {
    return NodeSettings(
      host: 'electrumx.kbunet.net',
      port: 50001,
      username: '',
      password: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'username': username,
      'password': password,
    };
  }

  factory NodeSettings.fromJson(Map<String, dynamic> json) {
    return NodeSettings(
      host: json['host'] as String,
      port: json['port'] as int,
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }
}

class SettingsProvider with ChangeNotifier {
  static const String _settingsKey = 'node_settings';
  static const String _languageKey = 'app_language';
  final SharedPreferences _prefs;
  NodeSettings? _nodeSettings;
  String? _error;
  bool _isLoading = false;
  Locale _locale = const Locale('en'); // Default to English

  SettingsProvider(this._prefs) {
    _loadSettings();
  }

  NodeSettings? get nodeSettings => _nodeSettings;
  String? get error => _error;
  bool get isLoading => _isLoading;
  Locale get locale => _locale;

  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load node settings
      final settingsJson = _prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          jsonDecode(settingsJson) as Map,
        );
        _nodeSettings = NodeSettings.fromJson(json);
      } else {
        _nodeSettings = NodeSettings.defaults();
        await saveNodeSettings(_nodeSettings!);
      }
      
      // Load language settings
      final languageCode = _prefs.getString(_languageKey);
      if (languageCode != null) {
        _locale = Locale(languageCode);
      }
      
      _error = null;
    } catch (e) {
      _error = 'Failed to load settings: $e';
      print('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveNodeSettings(NodeSettings settings) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
      _nodeSettings = settings;
      _error = null;
    } catch (e) {
      _error = 'Failed to save settings: $e';
      print('Error saving settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadSettings() async {
    await _loadSettings();
  }
  
  Future<void> setLanguage(String languageCode) async {
    try {
      await _prefs.setString(_languageKey, languageCode);
      _locale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to save language setting: $e';
      print('Error saving language setting: $e');
    }
  }
}
