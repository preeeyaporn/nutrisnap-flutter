import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../utils/result.dart';

/// Generic HTTP REST API client with standard timeout and error handling.
abstract class ApiService {
  Future<Result<Map<String, dynamic>>> get(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  });

  Future<Result<Map<String, dynamic>>> post(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
  });
}

class HttpApiService implements ApiService {
  final http.Client _client;

  HttpApiService({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<Result<Map<String, dynamic>>> get(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              if (!kIsWeb) 'User-Agent': ApiConstants.openFoodFactsUserAgent,
              ...?headers,
            },
          )
          .timeout(timeout ?? ApiConstants.connectTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return Result.success(decoded);
      } else if (response.statusCode == 404) {
        try {
          final decoded = json.decode(utf8.decode(response.bodyBytes));
          if (decoded is Map<String, dynamic>) {
            return Result.success(decoded);
          }
        } catch (_) {}
        return Result.failure('HTTP Error: 404 - Not Found');
      } else {
        return Result.failure(
          'HTTP Error: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return Result.failure('Network connection failed: $e');
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> post(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse(url);
      final payload = body is String ? body : json.encode(body);
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ...?headers,
            },
            body: payload,
          )
          .timeout(timeout ?? ApiConstants.receiveTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return Result.success(decoded);
      } else if (response.statusCode == 404) {
        try {
          final decoded = json.decode(utf8.decode(response.bodyBytes));
          if (decoded is Map<String, dynamic>) {
            return Result.success(decoded);
          }
        } catch (_) {}
        return Result.failure('HTTP Error: 404 - Not Found');
      } else {
        return Result.failure(
          'HTTP Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      return Result.failure('POST Request failed: $e');
    }
  }
}
