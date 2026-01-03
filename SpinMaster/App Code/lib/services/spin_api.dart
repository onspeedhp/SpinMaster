import 'api_service.dart';

/// Spin API service
class SpinApi {
  /// Claim daily free spin
  static Future<Map<String, dynamic>> claimDailySpin() async {
    final response = await ApiService.post('/api/spin/daily-claim');
    return ApiService.handleResponse(response);
  }

  /// Execute a spin (server-side result generation)
  static Future<Map<String, dynamic>> executeSpin() async {
    final response = await ApiService.post('/api/spin/execute');
    return ApiService.handleResponse(response);
  }

  /// Get official wheel configuration
  static Future<Map<String, dynamic>> getWheelConfig() async {
    final response = await ApiService.get('/api/spin/configuration');
    return ApiService.handleResponse(response);
  }

  /// Get spin history
  static Future<List<dynamic>> getSpinHistory({int limit = 50}) async {
    final response = await ApiService.get('/api/spin/history?limit=$limit');
    final data = ApiService.handleResponse(response);
    return data['history'] ?? [];
  }
}
