import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Authentication API service
class AuthApi {
  /// Get nonce for wallet signature
  static Future<String> getNonce(String walletAddress) async {
    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/api/auth/nonce?walletAddress=$walletAddress',
      ),
    );

    if (response.statusCode == 200) {
      final data = ApiService.handleResponse(response);
      return data['nonce'];
    } else {
      throw ApiException('Failed to get nonce', response.statusCode);
    }
  }

  /// Login with wallet signature
  static Future<Map<String, dynamic>> login(
    String walletAddress,
    String signature,
  ) async {
    final response = await ApiService.post(
      '/api/auth/login',
      body: {'walletAddress': walletAddress, 'signature': signature},
    );

    final data = ApiService.handleResponse(response);

    // Store tokens
    await ApiService.storeTokens(data['accessToken'], data['refreshToken']);

    return data;
  }

  /// Refresh access token
  static Future<String> refreshToken() async {
    final refreshToken = await ApiService.getRefreshToken();
    if (refreshToken == null) {
      throw ApiException('No refresh token available', 401);
    }

    final response = await ApiService.post(
      '/api/auth/refresh',
      body: {'refreshToken': refreshToken},
    );

    final data = ApiService.handleResponse(response);

    // Store new access token
    await ApiService.storeTokens(
      data['accessToken'],
      refreshToken, // Keep same refresh token
    );

    return data['accessToken'];
  }

  /// Logout
  static Future<void> logout() async {
    try {
      await ApiService.post('/api/auth/logout');
    } catch (e) {
      // Ignore errors on logout
    } finally {
      await ApiService.clearTokens();
    }
  }
}
