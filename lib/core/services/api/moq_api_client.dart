import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';

/// HTTP client for the MOQ backend, which serves the Quran content that used to
/// be read from the bundled sqlite database.
///
/// Every request returns decoded JSON, or the supplied fallback when the call
/// fails — the database helpers this replaces also degraded to empty results
/// rather than throwing, and the screens depend on that.
class MoqApiClient {
  MoqApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConstants.moqApiBaseUrl;

  static final MoqApiClient instance = MoqApiClient();

  final http.Client _client;
  final String _baseUrl;

  static const Duration _timeout = Duration(seconds: 20);

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final params = <String, String>{};
    query?.forEach((key, value) {
      if (value != null) params[key] = value.toString();
    });
    return Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: params.isEmpty ? null : params);
  }

  Future<dynamic> _get(String path, Map<String, dynamic>? query) async {
    final uri = _uri(path, query);
    final response = await _client.get(uri).timeout(_timeout);
    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'HTTP ${response.statusCode} for $uri',
        uri,
      );
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  /// Returns the JSON array at [path] as a list of maps, or `[]` on failure.
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final decoded = await _get(path, query);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('MoqApiClient: GET $path failed — $e');
      return [];
    }
  }

  /// Returns the JSON object at [path], or `null` when missing or on failure.
  Future<Map<String, dynamic>?> getObject(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final decoded = await _get(path, query);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      debugPrint('MoqApiClient: GET $path failed — $e');
      return null;
    }
  }

  /// Returns the JSON array at [path] as a list of ints, or `[]` on failure.
  Future<List<int>> getIntList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final decoded = await _get(path, query);
      if (decoded is! List) return [];
      return decoded.whereType<num>().map((e) => e.toInt()).toList();
    } catch (e) {
      debugPrint('MoqApiClient: GET $path failed — $e');
      return [];
    }
  }

  /// Returns the JSON array at [path] as a list of strings, or `[]` on failure.
  Future<List<String>> getStringList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final decoded = await _get(path, query);
      if (decoded is! List) return [];
      return decoded.whereType<String>().toList();
    } catch (e) {
      debugPrint('MoqApiClient: GET $path failed — $e');
      return [];
    }
  }
}
