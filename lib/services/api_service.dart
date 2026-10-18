import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import '../models/brand_model.dart';
import '../models/session_model.dart';
import '../models/voucher_model.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:4000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000'; // Android emulator to host machine mapping
    }
    return 'http://localhost:4000'; // iOS simulator or desktop
  }

  static Future<bool> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<CategoryModel>?> getCategories() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/categories')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((item) => CategoryModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<List<BrandModel>?> getBrands({String? categoryId}) async {
    try {
      var url = '$baseUrl/api/brands?approvedOnly=true';
      if (categoryId != null) url += '&categoryId=$categoryId';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((item) => BrandModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<List<SessionModel>?> getActiveSessions() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/sessions/active')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((item) => SessionModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<VoucherModel?> claimSessionVoucher(String sessionId) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/sessions/$sessionId/claim')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return VoucherModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }
}
