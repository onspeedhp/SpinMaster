import 'api_service.dart';

/// User API service
class UserApi {
  /// Get user profile
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await ApiService.get('/api/user/profile');
    final data = ApiService.handleResponse(response);
    return data['user'] ?? {};
  }

  /// Get user's spin balance
  static Future<int> getSpinsBalance() async {
    final response = await ApiService.get('/api/user/spins');
    final data = ApiService.handleResponse(response);
    return data['spinsBalance'] ?? 0;
  }

  /// Get leaderboard
  /// period: 'daily', 'weekly', 'all-time' (default)
  static Future<List<dynamic>> getLeaderboard({
    String period = 'all-time',
  }) async {
    final response = await ApiService.get('/api/leaderboard/$period');
    final data = ApiService.handleResponse(response);
    return data['leaderboard'] ?? [];
  }
}
