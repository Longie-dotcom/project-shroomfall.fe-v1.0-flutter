import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class DioClient {
  late final Dio dio;
  final StorageService _storageService;

  DioClient(this._storageService) {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://gamems-apirailwayinternal-production.up.railway.app/api',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Automatically inject token if available
          final token = await _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Log the full resolved URL string and method for debugging
          final fullUrl = dio.options.baseUrl + options.path;
          debugPrint('🌐 [HTTP] ${options.method} --> $fullUrl');
          debugPrint('📦 [Headers] ${options.headers}');
          if (options.data != null) {
            debugPrint('📤 [Body] ${options.data}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('✅ [HTTP Response] ${response.statusCode} --> ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          // Log error details for 404 or other issues
          debugPrint('❌ [HTTP Error] ${error.response?.statusCode} --> ${error.requestOptions.uri}');
          debugPrint('💬 [Error Message] ${error.message}');

          if (error.response?.statusCode == 401) {
            // TODO: Handle token expiration / force sign out if needed
          }
          return handler.next(error);
        },
      ),
    );
  }
}