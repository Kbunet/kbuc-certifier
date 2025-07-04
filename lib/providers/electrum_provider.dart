import 'package:flutter/foundation.dart';
import '../services/electrum_service.dart';
import 'settings_provider.dart';

class ElectrumProvider with ChangeNotifier {
  final _electrumService = ElectrumService();
  bool _isLoading = false;
  String? _error;
  final Map<String, Map<String, dynamic>> _profiles = {};
  SettingsProvider? _settingsProvider;
  bool _hasAttemptedConnection = false;

  bool get isLoading => _isLoading;
  String? get error => _hasAttemptedConnection ? _error : null;
  bool get isConnected => _electrumService.isConnected;

  void initialize(SettingsProvider settingsProvider) {
    _settingsProvider = settingsProvider;
    // We no longer need to listen for settings changes since we connect on-demand
  }

  // No longer needed as we connect on-demand

  // Initialize the service with credentials but don't connect yet
  void _initializeWithSettings() {
    final settings = _settingsProvider?.nodeSettings;
    if (settings != null) {
      _electrumService.initialize(
        host: settings.host,
        port: settings.port,
        username: settings.username,
        password: settings.password,
      );
    }
  }

  Map<String, dynamic>? getProfile(String contentHash) {
    return _profiles[contentHash];
  }

  Future<void> fetchProfile(String contentHash) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Make sure we have the latest settings before trying to connect
      _initializeWithSettings();

      final profile = await _electrumService.verifyProfile(contentHash);
      _profiles[contentHash] = profile;
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error fetching profile: $_error');
    } finally {
      _isLoading = false;
      _hasAttemptedConnection = true;
      notifyListeners();
    }
  }

  void dispose() {
    _electrumService.dispose();
    super.dispose();
  }
}
