import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class BitcoinRPCClient {
  final String host;
  final int port;
  final String username;
  final String password;
  final String _auth;
  
  BitcoinRPCClient({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
  }) : _auth = base64Encode(utf8.encode('$username:$password'));

  Future<Map<String, dynamic>> command(String method, [List<dynamic>? params]) async {
    // Parse the host to handle protocol
    String cleanHost = host;
    if (host.startsWith('http://')) {
      cleanHost = host.substring(7);
    } else if (host.startsWith('https://')) {
      cleanHost = host.substring(8);
    }
    
    final url = Uri.http('$cleanHost:$port', '/');
    final requestBody = {
      'jsonrpc': '2.0',
      'id': DateTime.now().millisecondsSinceEpoch,
      'method': method,
      'params': params ?? [],
    };
    
    print('\nBitcoin RPC Request:');
    print('URL: $url');
    print('Method: $method');
    print('Params: $params');
    print('Request body: ${json.encode(requestBody)}');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $_auth',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please check your node settings.');
        },
      );

      print('\nBitcoin RPC Response:');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please check your username and password.');
      }

      if (response.statusCode != 200) {
        throw Exception('RPC call failed with status ${response.statusCode}: ${response.body}');
      }

      // Try to parse the response body
      Map<String, dynamic> result;
      try {
        result = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Invalid response format from node: ${response.body}');
      }
      
      if (result.containsKey('error') && result['error'] != null) {
        print('RPC error: ${result['error']}');
        throw Exception('RPC error: ${result['error']}');
      }

      if (!result.containsKey('result')) {
        throw Exception('Invalid response format: missing result field');
      }

      print('RPC result: ${result['result']}');
      return result['result'] as Map<String, dynamic>;
    } on SocketException catch (e) {
      print('Socket error: $e');
      throw Exception('Failed to connect to node. Please check your host and port settings.');
    } catch (e) {
      print('RPC exception: $e');
      rethrow;
    }
  }
}
