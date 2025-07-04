import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ElectrumService {
  Socket? _socket;
  StreamSubscription? _subscription;
  final _responseControllers = <int, Completer<dynamic>>{};
  int _requestId = 0;
  bool _isConnected = false;
  String? _currentHost;
  int? _currentPort;
  String? _currentUsername;
  String? _currentPassword;
  
  bool get isConnected => _isConnected;
  
  Future<void> initialize({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    // Store credentials for later use when needed
    _currentHost = host;
    _currentPort = port;
    _currentUsername = username;
    _currentPassword = password;
    
    // Disconnect if already connected
    if (_isConnected) {
      _handleDisconnect();
    }
    // Don't connect immediately, only store credentials
  }
  
  String _cleanHost(String host) {
    // Remove any protocol prefixes
    final prefixes = ['tcp://', 'ws://', 'wss://', 'http://', 'https://'];
    String cleanHost = host;
    for (final prefix in prefixes) {
      if (cleanHost.startsWith(prefix)) {
        cleanHost = cleanHost.substring(prefix.length);
        break;
      }
    }
    // Remove any trailing paths
    final pathIndex = cleanHost.indexOf('/');
    if (pathIndex != -1) {
      cleanHost = cleanHost.substring(0, pathIndex);
    }
    return cleanHost;
  }
  
  Future<void> _connect(String host, int port, String username, String password) async {
    if (_isConnected) return;
    
    try {
      final cleanHost = _cleanHost(host);
      print('Connecting to Electrum server at $cleanHost:$port');
      
      // Connect to TCP socket
      _socket = await Socket.connect(cleanHost, port);
      _isConnected = true;
      
      // Set up stream transformer to handle JSON messages
      String buffer = '';
      
      _subscription = _socket!.listen(
        (List<int> data) {
          // Convert received data to string and add to buffer
          buffer += utf8.decode(data);
          
          // Process complete JSON messages
          while (true) {
            final endIndex = buffer.indexOf('\n');
            if (endIndex == -1) break;
            
            final message = buffer.substring(0, endIndex);
            buffer = buffer.substring(endIndex + 1);
            
            try {
              final response = json.decode(message);
              final id = response['id'] as int?;
              
              if (id != null && _responseControllers.containsKey(id)) {
                if (response.containsKey('error') && response['error'] != null) {
                  _responseControllers[id]!.completeError(response['error']);
                } else {
                  _responseControllers[id]!.complete(response['result']);
                }
                _responseControllers.remove(id);
              }
            } catch (e) {
              print('Error processing message: $e');
              print('Message was: $message');
            }
          }
        },
        onError: (error) {
          print('Socket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          print('Socket connection closed');
          _handleDisconnect();
        },
      );
      
      // Send version handshake
      await _send('server.version', ['ElectrumClient', '1.4']);
      
    } catch (e) {
      print('Failed to establish socket connection: $e');
      _handleDisconnect();
      throw Exception('Failed to connect to Electrum server: $e');
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _subscription?.cancel();
    _subscription = null;
    _socket?.destroy();
    _socket = null;
    
    // Complete all pending requests with error
    for (final controller in _responseControllers.values) {
      controller.completeError('Connection closed');
    }
    _responseControllers.clear();
  }
  
  // Keep-alive functionality removed as we're only connecting when needed
  
  // Removed automatic reconnection as we're only connecting when needed

  Future<Map<String, dynamic>> verifyProfile(String contentHash) async {
    // Connect on-demand if not already connected
    if (!_isConnected) {
      if (_currentHost == null || _currentPort == null) {
        throw Exception('Electrum server credentials not initialized');
      }
      try {
        await _connect(
          _currentHost!, 
          _currentPort!, 
          _currentUsername ?? '', 
          _currentPassword ?? ''
        );
      } catch (e) {
        throw Exception('Failed to connect to Electrum server: $e');
      }
    }

    try {
      final response = await _send('blockchain.scripthash.get_profile', [contentHash]);
      // Disconnect after getting the profile to avoid keeping the connection open
      _handleDisconnect();
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      // Ensure we disconnect even if there's an error
      _handleDisconnect();
      throw Exception('Failed to verify profile: $e');
    }
  }

  Future<dynamic> _send(String method, List<dynamic> params) async {
    if (!_isConnected || _socket == null) {
      throw Exception('Not connected to Electrum server');
    }
    
    final id = _requestId++;
    final request = {
      'id': id,
      'method': method,
      'params': params,
    };
    
    final completer = Completer<dynamic>();
    _responseControllers[id] = completer;
    
    try {
      final message = json.encode(request) + '\n';  // Add newline as message delimiter
      print('Sending request: $message');
      _socket!.write(message);
      await _socket!.flush();
    } catch (e) {
      _responseControllers.remove(id);
      throw Exception('Failed to send request: $e');
    }
    
    return completer.future;
  }

  void dispose() {
    _handleDisconnect();
    _currentHost = null;
    _currentPort = null;
    _currentUsername = null;
    _currentPassword = null;
  }
}
