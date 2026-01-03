import 'api_service.dart';

/// Payment API service
class PaymentApi {
  /// Get available spin packages
  static Future<List<dynamic>> getPackages() async {
    final response = await ApiService.get('/api/payment/packages');
    final data = ApiService.handleResponse(response);
    return data['packages'] ?? [];
  }

  /// Purchase spins with transaction signature
  static Future<Map<String, dynamic>> purchaseSpins(
    String txSignature,
    int packageId,
  ) async {
    final response = await ApiService.post(
      '/api/payment/purchase-spins',
      body: {'txSignature': txSignature, 'packageId': packageId},
    );
    return ApiService.handleResponse(response);
  }
}
