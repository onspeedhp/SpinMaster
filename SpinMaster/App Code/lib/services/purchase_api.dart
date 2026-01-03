import 'package:flutter/foundation.dart';
import 'api_service.dart';

class PurchaseApi {
  /// Get available spin packages and config
  static Future<Map<String, dynamic>> getPackages() async {
    try {
      final response = await ApiService.get('/api/payment/packages');
      return ApiService.handleResponse(response);
    } catch (e) {
      debugPrint('Error getting packages: $e');
      return {};
    }
  }

  /// Verify purchase and add spins
  static Future<Map<String, dynamic>> purchaseSpins({
    required String txSignature,
    required int packageId,
  }) async {
    final response = await ApiService.post(
      '/api/payment/purchase-spins',
      body: {'txSignature': txSignature, 'packageId': packageId},
    );
    return ApiService.handleResponse(response);
  }
}
