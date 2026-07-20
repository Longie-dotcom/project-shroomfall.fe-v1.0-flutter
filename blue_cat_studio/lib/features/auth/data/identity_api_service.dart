import 'package:blue_cat_studio/core/network/dio_client.dart';
import 'package:blue_cat_studio/core/services/storage_service.dart';
import 'package:blue_cat_studio/models/dtos/identity_dtos.dart';

class IdentityApiService {
  final DioClient _dioClient;
  final StorageService _storageService;

  IdentityApiService(this._dioClient, this._storageService);

  /// Corresponds to: [HttpPost("login")]
  Future<TokenDTO> login(LoginDTO dto) async {
    try {
      final response = await _dioClient.dio.post('/Identity/login', data: dto.toJson());

      final tokenResult = TokenDTO.fromJson(response.data);

      // Automatically persist tokens upon successful login
      await _storageService.saveToken(tokenResult.accessToken);
      // Optional: Save refresh token if you want to store it securely too

      return tokenResult;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Corresponds to: [HttpPost("refresh")]
  Future<TokenDTO> refreshToken(RefreshTokenDTO dto) async {
    try {
      final response = await _dioClient.dio.post('/Auth/refresh', data: dto.toJson());

      final tokenResult = TokenDTO.fromJson(response.data);

      // Automatically update the stored access token
      await _storageService.saveToken(tokenResult.accessToken);

      return tokenResult;
    } catch (e) {
      throw Exception('Token refresh failed: $e');
    }
  }
}