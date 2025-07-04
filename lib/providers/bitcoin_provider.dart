import 'package:flutter/material.dart';
import '../services/bitcoin_service.dart';

class BitcoinProvider with ChangeNotifier {
  final _bitcoinService = BitcoinService();
  Map<String, Map<String, dynamic>> _profiles = {};
  String? _error;
  bool _isLoading = false;

  String? get error => _error;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? getProfile(String contentHash) => _profiles[contentHash];

  void clearProfiles() {
    _profiles.clear();
    notifyListeners();
  }

  Future<void> fetchProfile(String contentHash) async {
    print('\nFetching profile for hash: $contentHash');
    _isLoading = true;
    _error = null;
    notifyListeners();

    _profiles.remove(contentHash); // Clear existing profile data

    try {
      final profile = await _bitcoinService.getProfile(contentHash);
      _profiles[contentHash] = profile;
    } catch (e) {
      print('Error fetching profile: $e');
      _error = e.toString();
      _profiles.remove(contentHash); // Ensure profile is cleared on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initializeService({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    try {
      await _bitcoinService.initialize(
        host: host,
        port: port,
        username: username,
        password: password,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
